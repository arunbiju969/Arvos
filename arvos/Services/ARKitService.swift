//
//  ARKitService.swift
//  arvos
//
//  ARKit service for depth/LiDAR and pose tracking
//

import Foundation
import ARKit
import Combine
import CoreImage
import UIKit

protocol ARKitServiceDelegate: AnyObject {
    func arKitService(_ service: ARKitService, didUpdate pose: PoseData)
    func arKitService(_ service: ARKitService, didCapture depth: DepthFrame)
    func arKitService(_ service: ARKitService, didCapture camera: CameraFrame)
    func arKitService(_ service: ARKitService, didEncounterError error: Error)
    func arKitService(_ service: ARKitService, didOutputDepthSample sample: DepthVisualizationSample)
}

extension ARKitServiceDelegate {
    func arKitService(_ service: ARKitService, didOutputDepthSample sample: DepthVisualizationSample) {}
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

    // Camera frame timing
    private var lastCameraTime: UInt64 = 0
    private var cameraInterval: UInt64 = 33_333_333  // 30 FPS (33ms)
    private let arkitJPEGQuality: CGFloat = 0.5

    // Frame counters
    private var frameCount = 0
    private var cameraFrameCount = 0
    private var depthFrameCount = 0

    private let depthProcessingQueue = DispatchQueue(label: "com.arvos.depthProcessing", qos: .userInitiated)
    private let cameraProcessingQueue = DispatchQueue(label: "com.arvos.cameraProcessing", qos: .userInitiated)
    private var isProcessingDepth = false

    private let cameraContext = CIContext(options: [.useSoftwareRenderer: false])

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
                // Enable mesh reconstruction for LiDAR
                configuration?.sceneReconstruction = .mesh
                // ALSO enable scene depth to get depth frames
                if supportsDepth {
                    configuration?.frameSemantics.insert(.sceneDepth)
                }
            } else if supportsDepth {
                // Fallback to estimated depth for non-LiDAR devices
                configuration?.frameSemantics.insert(.sceneDepth)
            }
        }

        // Enable plane detection for better tracking
        configuration?.planeDetection = [.horizontal, .vertical]
    }

    // MARK: - Control

    func start() {
        guard let session = arSession, let config = configuration, !isRunning else {
            print("⚠️ ARKit start failed: session=\(arSession != nil), config=\(configuration != nil), isRunning=\(isRunning)")
            return
        }

        print("🚀 Starting ARKit session")
        print("   LiDAR: \(hasLiDAR), Depth: \(supportsDepth)")
        print("   Scene reconstruction: \(config.sceneReconstruction)")
        print("   Frame semantics: \(config.frameSemantics)")
        print("   Depth enabled: \(depthEnabled), Target FPS: \(targetDepthFPS)")

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
                // ALSO enable scene depth for LiDAR
                if supportsDepth {
                    config.frameSemantics.insert(.sceneDepth)
                }
            } else if supportsDepth {
                config.frameSemantics.insert(.sceneDepth)
            }
        } else {
            config.sceneReconstruction = []
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
        let timeSinceLastDepth = timestamp - lastDepthTime
        guard lastDepthTime == 0 || timeSinceLastDepth >= depthInterval else {
            return
        }
        lastDepthTime = timestamp

        // Try to get depth data
        var depthMap: CVPixelBuffer?
        var confidenceMap: CVPixelBuffer?

        // LiDAR depth (preferred)
        if let sceneDepth = frame.sceneDepth {
            depthMap = sceneDepth.depthMap
            confidenceMap = sceneDepth.confidenceMap  // Add confidence data
        }
        // ARKit depth estimation (fallback)
        else if let estimatedDepth = frame.estimatedDepthData {
            depthMap = estimatedDepth
        } else {
            // Only print first few failures
            if depthFrameCount < 5 {
                print("❌ No depth data available from ARFrame (tracking: \(frame.camera.trackingState))")
            }
            return
        }

        guard let depthBuffer = depthMap else { return }
        guard !isProcessingDepth else { return }
        isProcessingDepth = true

        // Retain pixel buffers for async processing instead of full memcpy
        let retainedDepth = retainPixelBuffer(depthBuffer)
        let retainedConfidence: CVPixelBuffer? = {
            if let confidenceMap {
                return retainPixelBuffer(confidenceMap)
            }
            return nil
        }()
        let cameraTransform = frame.camera.transform
        let intrinsics = frame.camera.intrinsics
        let hasConfidence = confidenceMap != nil

        depthProcessingQueue.async { [weak self] in
            guard let self else {
                // Release retained buffers if self is deallocated
                CVPixelBufferRelease(retainedDepth)
                if let confidence = retainedConfidence {
                    CVPixelBufferRelease(confidence)
                }
                return
            }

            let cloud = self.createPointCloud(
                from: retainedDepth,
                cameraTransform: cameraTransform,
                intrinsics: intrinsics,
                confidenceMap: retainedConfidence
            )

            // Release retained buffers after processing
            CVPixelBufferRelease(retainedDepth)
            if let confidence = retainedConfidence {
                CVPixelBufferRelease(confidence)
            }

            DispatchQueue.main.async {
                self.isProcessingDepth = false

                let pointCount = cloud.points.count
                if pointCount == 0 {
                    if self.depthFrameCount < 5 {
                        print("⚠️ Depth cloud empty (0 points)")
                    }
                    return
                }

                self.depthFrameCount += 1
                if self.depthFrameCount <= 3 || self.depthFrameCount % 10 == 0 {
                    print("✅ Depth frame #\(self.depthFrameCount): \(pointCount) points")
                }

                let depthFrame = DepthFrame(
                    timestamp: timestamp,
                    pointCloud: cloud,
                    cameraTransform: cameraTransform,
                    intrinsics: intrinsics,
                    hasConfidenceData: hasConfidence
                )
                self.delegate?.arKitService(self, didCapture: depthFrame)
            }
        }
    }

    private func createPointCloud(from depthMap: CVPixelBuffer, cameraTransform: simd_float4x4, intrinsics: simd_float3x3, confidenceMap: CVPixelBuffer?) -> PointCloud {
        CVPixelBufferLockBaseAddress(depthMap, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(depthMap, .readOnly) }

        let width = CVPixelBufferGetWidth(depthMap)
        let height = CVPixelBufferGetHeight(depthMap)

        guard let depthPointer = CVPixelBufferGetBaseAddress(depthMap)?.assumingMemoryBound(to: Float32.self) else {
            return PointCloud(timestamp: Constants.Time.now(), points: [], colors: nil, confidenceLevels: nil)
        }

        // Confidence map
        var confidencePointer: UnsafeMutablePointer<UInt8>?
        if let conf = confidenceMap {
            CVPixelBufferLockBaseAddress(conf, .readOnly)
            confidencePointer = CVPixelBufferGetBaseAddress(conf)?.assumingMemoryBound(to: UInt8.self)
        }
        defer {
            if let conf = confidenceMap {
                CVPixelBufferUnlockBaseAddress(conf, .readOnly)
            }
        }

        let fx = intrinsics[0][0]
        let fy = intrinsics[1][1]
        let cx = intrinsics[2][0]
        let cy = intrinsics[2][1]

        let rotation = simd_float3x3(rows: [
            SIMD3<Float>(cameraTransform.columns.0.x, cameraTransform.columns.0.y, cameraTransform.columns.0.z),
            SIMD3<Float>(cameraTransform.columns.1.x, cameraTransform.columns.1.y, cameraTransform.columns.1.z),
            SIMD3<Float>(cameraTransform.columns.2.x, cameraTransform.columns.2.y, cameraTransform.columns.2.z)
        ])
        let translation = SIMD3<Float>(cameraTransform.columns.3.x, cameraTransform.columns.3.y, cameraTransform.columns.3.z)

        var points: [SIMD3<Float>] = []
        points.reserveCapacity(Constants.Depth.maxPoints)

        var confidenceLevels: [UInt8] = []
        confidenceLevels.reserveCapacity(Constants.Depth.maxPoints)

        // Downsample for performance
        let step = max(1, Constants.Depth.downsampleFactor)

        for y in stride(from: 0, to: height, by: step) {
            for x in stride(from: 0, to: width, by: step) {
                let index = y * width + x
                let depthValue = depthPointer[index]

                guard depthValue.isFinite,
                      depthValue >= Constants.Depth.minDepth,
                      depthValue <= Constants.Depth.maxDepth else {
                    continue
                }

                if let confidencePointer {
                    let confidence = confidencePointer[index]
                    if confidence == 0 {
                        continue
                    }
                    confidenceLevels.append(confidence)
                } else {
                    confidenceLevels.append(2)
                }

                let xn = (Float(x) - cx) / fx
                let yn = (Float(y) - cy) / fy

                let cameraPoint = SIMD3<Float>(xn * depthValue, yn * depthValue, -depthValue)
                let worldPoint = rotation * cameraPoint + translation
                points.append(worldPoint)

                if points.count >= Constants.Depth.maxPoints {
                    break
                }
            }
            if points.count >= Constants.Depth.maxPoints {
                break
            }
        }

        return PointCloud(
            timestamp: Constants.Time.now(),
            points: points,
            colors: nil,
            confidenceLevels: confidenceLevels.isEmpty ? nil : confidenceLevels
        )
    }

    // Retain pixel buffer for async processing
    // Using CVPixelBufferRetain is more efficient than full memcpy
    // ARKit's pixel buffers remain valid as long as they're retained
    private func retainPixelBuffer(_ pixelBuffer: CVPixelBuffer) -> CVPixelBuffer {
        CVPixelBufferRetain(pixelBuffer)
        return pixelBuffer
    }
}

// MARK: - ARSessionDelegate

extension ARKitService: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        let timestamp = Constants.Time.now()

        // Only print every 30th frame to reduce spam
        frameCount += 1
        if frameCount % 30 == 0 {
            print("📊 ARFrame #\(frameCount): tracking=\(frame.camera.trackingState), sceneDepth=\(frame.sceneDepth != nil), estimatedDepth=\(frame.estimatedDepthData != nil)")
        }

        // Process camera frame at target FPS (10 FPS)
        if lastCameraTime == 0 || timestamp - lastCameraTime >= cameraInterval {
            lastCameraTime = timestamp
            processCameraFrame(frame, timestamp: timestamp)
        }

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

    private func processCameraFrame(_ frame: ARFrame, timestamp: UInt64) {
        let pixelBuffer = frame.capturedImage

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let intrinsicsMatrix = frame.camera.intrinsics

        // Retain instead of copy - much more efficient
        let retainedBuffer = retainPixelBuffer(pixelBuffer)
        let frameIntrinsics = CameraIntrinsics(intrinsics: intrinsicsMatrix)

        cameraProcessingQueue.async { [weak self] in
            autoreleasepool {
                guard let self else {
                    CVPixelBufferRelease(retainedBuffer)
                    return
                }

                guard let jpegData = self.encodeJPEG(from: retainedBuffer, quality: self.arkitJPEGQuality) else {
                    CVPixelBufferRelease(retainedBuffer)
                    return
                }

                // Release buffer after encoding
                CVPixelBufferRelease(retainedBuffer)

                let cameraFrame = CameraFrame(
                    timestamp: timestamp,
                    data: jpegData,
                    width: width,
                    height: height,
                    intrinsics: frameIntrinsics
                )

                self.cameraFrameCount += 1
                if self.cameraFrameCount <= 3 || self.cameraFrameCount % 10 == 0 {
                    print("✅ ARKit camera frame #\(self.cameraFrameCount): \(width)x\(height), \(jpegData.count) bytes")
                }

                DispatchQueue.main.async {
                    self.delegate?.arKitService(self, didCapture: cameraFrame)
                }
            }
        }
    }

    private func encodeJPEG(from pixelBuffer: CVPixelBuffer, quality: CGFloat) -> Data? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        guard let cgImage = cameraContext.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        let uiImage = UIImage(cgImage: cgImage)
        return uiImage.jpegData(compressionQuality: quality)
    }

    func session(_ session: ARSession, didFailWithError error: Error) {
        print("❌ ARSession error: \(error)")
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
    let cameraTransform: simd_float4x4
    let intrinsics: simd_float3x3
    let hasConfidenceData: Bool

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
            maxDepth: maxDepth,
            hasConfidenceData: hasConfidenceData
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
