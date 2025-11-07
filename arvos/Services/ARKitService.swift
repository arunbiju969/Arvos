//
//  ARKitService.swift
//  arvos
//
//  ARKit service for depth/LiDAR and pose tracking
//

import Foundation
import ARKit
import Combine

protocol ARKitServiceDelegate: AnyObject {
    func arKitService(_ service: ARKitService, didUpdate pose: PoseData)
    func arKitService(_ service: ARKitService, didCapture depth: DepthFrame)
    func arKitService(_ service: ARKitService, didEncounterError error: Error)
}

class ARKitService: NSObject {
    weak var delegate: ARKitServiceDelegate?

    private var arSession: ARSession?
    private var configuration: ARWorldTrackingConfiguration?

    private var isRunning = false
    private var depthEnabled = false
    private var targetDepthFPS: Int = 5
    private var targetPoseFPS: Int = 30

    private var lastDepthTime: UInt64 = 0
    private var lastPoseTime: UInt64 = 0
    private var depthInterval: UInt64 = 0
    private var poseInterval: UInt64 = 0

    // Device capabilities
    let hasLiDAR: Bool
    let supportsDepth: Bool

    // MARK: - Initialization

    override init() {
        self.hasLiDAR = ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh)
        self.supportsDepth = ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth)
        super.init()
    }

    // MARK: - Configuration

    func configure(depthEnabled: Bool, depthFPS: Int, poseFPS: Int) throws {
        guard ARWorldTrackingConfiguration.isSupported else {
            throw ARKitError.notSupported
        }

        self.depthEnabled = depthEnabled
        self.targetDepthFPS = depthFPS
        self.targetPoseFPS = poseFPS
        self.depthInterval = Constants.Time.nanosPerSecond / UInt64(depthFPS)
        self.poseInterval = Constants.Time.nanosPerSecond / UInt64(poseFPS)

        arSession = ARSession()
        arSession?.delegate = self

        configuration = ARWorldTrackingConfiguration()
        configuration?.worldAlignment = .gravity

        // Enable depth if supported and requested
        if depthEnabled {
            if hasLiDAR && ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
                configuration?.sceneReconstruction = .mesh
            } else if supportsDepth {
                configuration?.frameSemantics.insert(.sceneDepth)
            }
        }

        // Enable plane detection for better tracking
        configuration?.planeDetection = [.horizontal, .vertical]
    }

    // MARK: - Control

    func start() {
        guard let session = arSession, let config = configuration, !isRunning else { return }

        session.run(config, options: [.resetTracking, .removeExistingAnchors])
        isRunning = true
    }

    func stop() {
        guard let session = arSession, isRunning else { return }

        session.pause()
        isRunning = false
    }

    func pause() {
        guard let session = arSession else { return }
        session.pause()
    }

    func resume() {
        guard let session = arSession, let config = configuration else { return }
        session.run(config)
    }

    // MARK: - Update Settings

    func updateDepthSettings(enabled: Bool, fps: Int) {
        depthEnabled = enabled
        targetDepthFPS = fps
        depthInterval = Constants.Time.nanosPerSecond / UInt64(fps)

        guard let config = configuration else { return }

        if enabled {
            if hasLiDAR && ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
                config.sceneReconstruction = .mesh
            } else if supportsDepth {
                config.frameSemantics.insert(.sceneDepth)
            }
        } else {
            config.sceneReconstruction = .meshWithClassification
            config.frameSemantics.remove(.sceneDepth)
        }

        arSession?.run(config)
    }

    func updatePoseFPS(_ fps: Int) {
        targetPoseFPS = fps
        poseInterval = Constants.Time.nanosPerSecond / UInt64(fps)
    }

    // MARK: - Helper Methods

    private func processDepthFrame(_ frame: ARFrame) {
        guard depthEnabled else { return }

        let timestamp = Constants.Time.now()

        // Rate limiting for depth
        guard timestamp - lastDepthTime >= depthInterval else { return }
        lastDepthTime = timestamp

        // Try to get depth data
        var depthMap: CVPixelBuffer?
        var pointCloud: PointCloud?

        // LiDAR depth (preferred)
        if let sceneDepth = frame.sceneDepth {
            depthMap = sceneDepth.depthMap
        }
        // ARKit depth estimation (fallback)
        else if let estimatedDepth = frame.estimatedDepthData {
            depthMap = estimatedDepth
        }

        // Convert depth map to point cloud
        if let depthBuffer = depthMap {
            pointCloud = createPointCloud(from: depthBuffer, camera: frame.camera, frame: frame)
        }

        // Create depth frame
        if let cloud = pointCloud {
            let depthFrame = DepthFrame(
                timestamp: timestamp,
                pointCloud: cloud,
                camera: frame.camera
            )
            delegate?.arKitService(self, didCapture: depthFrame)
        }
    }

    private func createPointCloud(from depthMap: CVPixelBuffer, camera: ARCamera, frame: ARFrame) -> PointCloud {
        CVPixelBufferLockBaseAddress(depthMap, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(depthMap, .readOnly) }

        let width = CVPixelBufferGetWidth(depthMap)
        let height = CVPixelBufferGetHeight(depthMap)
        let baseAddress = CVPixelBufferGetBaseAddress(depthMap)

        guard let floatBuffer = baseAddress?.assumingMemoryBound(to: Float32.self) else {
            return PointCloud(timestamp: Constants.Time.now(), points: [], colors: nil)
        }

        var points: [SIMD3<Float>] = []
        var colors: [SIMD3<UInt8>] = []

        // Downsample for performance
        let step = Constants.Depth.downsampleFactor

        for y in stride(from: 0, to: height, by: step) {
            for x in stride(from: 0, to: width, by: step) {
                let depthValue = floatBuffer[y * width + x]

                // Filter by depth range
                guard depthValue >= Constants.Depth.minDepth && depthValue <= Constants.Depth.maxDepth else {
                    continue
                }

                // Unproject to 3D
                let normalizedPoint = CGPoint(x: CGFloat(x) / CGFloat(width), y: CGFloat(y) / CGFloat(height))
                let point = camera.unprojectPoint(
                    normalizedPoint,
                    ontoPlane: simd_float4x4(1),
                    orientation: .portrait,
                    viewportSize: CGSize(width: width, height: height)
                )

                // Apply depth
                let direction = simd_normalize(point)
                let depthPoint = direction * depthValue

                points.append(depthPoint)

                // Try to get color from camera image
                let pixelBuffer = frame.capturedImage
                let color = getColor(from: pixelBuffer, at: (x, y))
                colors.append(color)
            }
        }

        return PointCloud(
            timestamp: Constants.Time.now(),
            points: points,
            colors: colors.isEmpty ? nil : colors
        )
    }

    private func getColor(from pixelBuffer: CVPixelBuffer, at point: (Int, Int)) -> SIMD3<UInt8> {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)

        guard let buffer = baseAddress?.assumingMemoryBound(to: UInt8.self) else {
            return SIMD3<UInt8>(128, 128, 128)
        }

        let (x, y) = point
        let offset = y * bytesPerRow + x * 4

        let b = buffer[offset]
        let g = buffer[offset + 1]
        let r = buffer[offset + 2]

        return SIMD3<UInt8>(r, g, b)
    }
}

// MARK: - ARSessionDelegate

extension ARKitService: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        let timestamp = Constants.Time.now()

        // Process pose at target FPS
        if timestamp - lastPoseTime >= poseInterval {
            lastPoseTime = timestamp
            let poseData = PoseData(timestamp: timestamp, camera: frame.camera)
            delegate?.arKitService(self, didUpdate: poseData)
        }

        // Process depth at target FPS
        if depthEnabled {
            processDepthFrame(frame)
        }
    }

    func session(_ session: ARSession, didFailWithError error: Error) {
        delegate?.arKitService(self, didEncounterError: error)
    }

    func sessionWasInterrupted(_ session: ARSession) {
        // Session interrupted (e.g., app backgrounded)
    }

    func sessionInterruptionEnded(_ session: ARSession) {
        // Session resumed
    }
}

// MARK: - Depth Frame

struct DepthFrame {
    let timestamp: UInt64
    let pointCloud: PointCloud
    let camera: ARCamera

    func metadata() -> DepthFrameMetadata {
        let plyData = pointCloud.toPLY()
        let minDepth = pointCloud.points.map { simd_length($0) }.min() ?? 0
        let maxDepth = pointCloud.points.map { simd_length($0) }.max() ?? 0

        return DepthFrameMetadata(
            timestamp: timestamp,
            width: 0, // Point cloud doesn't have width/height
            height: 0,
            pointCount: pointCloud.points.count,
            format: "point_cloud",
            size: plyData.count,
            minDepth: minDepth,
            maxDepth: maxDepth
        )
    }
}

// MARK: - Errors

enum ARKitError: LocalizedError {
    case notSupported
    case depthNotAvailable
    case configurationFailed

    var errorDescription: String? {
        switch self {
        case .notSupported:
            return "ARKit is not supported on this device"
        case .depthNotAvailable:
            return "Depth data is not available on this device"
        case .configurationFailed:
            return "Failed to configure ARKit session"
        }
    }
}
