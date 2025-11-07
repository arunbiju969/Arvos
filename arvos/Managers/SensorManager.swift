//
//  SensorManager.swift
//  arvos
//
//  Coordinates all sensor services and manages streaming modes
//

import Foundation
import Combine
import ARKit
import AVFoundation

class SensorManager: ObservableObject {
    static let shared = SensorManager()

    @Published private(set) var currentMode: StreamMode = .liveStream
    @Published private(set) var isStreaming = false
    @Published private(set) var currentFPS: Double = 0
    @Published private(set) var sensorStatuses: SensorStatuses = SensorStatuses()

    // Services
    private let cameraService = CameraService()
    private let arKitService = ARKitService()
    private let imuService = IMUService()
    private let gpsService = GPSService()
    private var awaitingCameraAuthorization = false

    // Managers
    private let networkManager = NetworkManager.shared
    private let recordingManager = RecordingManager()

    // Burst scan timer
    private var burstScanTimer: Timer?
    private var burstScanStartTime: Date?

    // FPS tracking
    private var frameTimestamps: [TimeInterval] = []
    private let fpsWindow: TimeInterval = 1.0

    private init() {
        setupDelegates()
    }

    private func setupDelegates() {
        cameraService.delegate = self
        arKitService.delegate = self
        imuService.delegate = self
        gpsService.delegate = self
    }

    // MARK: - Mode Management

    func setMode(_ mode: StreamMode) {
        guard !isStreaming else {
            print("Cannot change mode while streaming")
            return
        }

        currentMode = mode
        networkManager.sendModeConfig(mode)
    }

    func startStreaming() {
        guard !isStreaming else { return }

        let config = currentMode.config

        if config.cameraEnabled {
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            switch status {
            case .authorized:
                break
            case .notDetermined:
                guard !awaitingCameraAuthorization else { return }
                awaitingCameraAuthorization = true
                AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                    DispatchQueue.main.async {
                        guard let self else { return }
                        self.awaitingCameraAuthorization = false
                        if granted {
                            self.startStreaming()
                        } else {
                            self.sensorStatuses.camera = .error
                            self.networkManager.sendError(
                                "camera_permission_denied",
                                details: "Camera access denied by user"
                            )
                        }
                    }
                }
                return
            default:
                sensorStatuses.camera = .error
                networkManager.sendError(
                    "camera_permission_denied",
                    details: "Camera access denied. Enable camera in Settings."
                )
                return
            }
        }

        do {
            // Configure and start camera
            if config.cameraEnabled {
                try cameraService.configure(fps: config.cameraFPS)
                cameraService.start()
                sensorStatuses.camera = .active
            }

            // Configure and start ARKit
            if config.depthEnabled || config.poseEnabled {
                try arKitService.configure(
                    depthEnabled: config.depthEnabled,
                    depthFPS: config.depthFPS,
                    poseFPS: config.poseHz
                )
                arKitService.start()
                if config.depthEnabled {
                    sensorStatuses.depth = .active
                }
                if config.poseEnabled {
                    sensorStatuses.pose = .active
                }
            }

            // Configure and start IMU
            if config.imuEnabled {
                try imuService.configure(hz: config.imuHz)
                imuService.start()
                sensorStatuses.imu = .active
            }

            // Configure and start GPS
            if config.gpsEnabled {
                gpsService.configure(hz: 1) // GPS is typically 1 Hz
                gpsService.start()
                sensorStatuses.gps = .active
            }

            // Start recording if enabled
            if config.recordingEnabled {
                try recordingManager.startRecording(mode: currentMode)
            }

            isStreaming = true
            networkManager.sendStatus("streaming", sessionId: recordingManager.sessionId)

            // Start burst scan timer if applicable
            if let duration = config.autoDuration {
                startBurstScanTimer(duration: duration)
            }

        } catch {
            handleStartupFailure(error, config: config)
            return
        }
    }

    private func handleStartupFailure(_ error: Error, config: ModeConfiguration) {
        print("Failed to start streaming: \(error)")

        if let cameraError = error as? CameraError, config.cameraEnabled {
            sensorStatuses.camera = .error
            networkManager.sendError("camera_error", details: cameraError.localizedDescription)
        }

        if let arError = error as? ARKitError, (config.depthEnabled || config.poseEnabled) {
            sensorStatuses.depth = .error
            sensorStatuses.pose = .error
            networkManager.sendError("arkit_error", details: arError.localizedDescription)
        }

        if let imuError = error as? IMUError, config.imuEnabled {
            sensorStatuses.imu = .error
            networkManager.sendError("imu_error", details: imuError.localizedDescription)
        }

        if let gpsError = error as? GPSError, config.gpsEnabled {
            sensorStatuses.gps = .error
            networkManager.sendError("gps_error", details: gpsError.localizedDescription)
        }

        stopStreaming()
    }

    func stopStreaming() {
        guard isStreaming else { return }

        // Stop all services
        cameraService.stop()
        arKitService.stop()
        imuService.stop()
        gpsService.stop()

        // Stop recording
        if recordingManager.isRecording {
            try? recordingManager.stopRecording()
        }

        // Cancel burst scan timer
        burstScanTimer?.invalidate()
        burstScanTimer = nil
        burstScanStartTime = nil

        isStreaming = false
        sensorStatuses = SensorStatuses()

        networkManager.sendStatus("stopped")
    }

    func pauseStreaming() {
        arKitService.pause()
        // Other sensors don't need explicit pause
    }

    func resumeStreaming() {
        arKitService.resume()
    }

    // MARK: - Burst Scan

    private func startBurstScanTimer(duration: TimeInterval) {
        burstScanStartTime = Date()

        burstScanTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            self?.stopStreaming()
        }
    }

    var burstScanRemainingTime: TimeInterval? {
        guard let startTime = burstScanStartTime, let duration = currentMode.config.autoDuration else {
            return nil
        }

        let elapsed = Date().timeIntervalSince(startTime)
        return max(0, duration - elapsed)
    }

    // MARK: - Dynamic Configuration

    func updateCameraFPS(_ fps: Int) {
        cameraService.updateFPS(fps)
    }

    func updateIMUFrequency(_ hz: Int) {
        imuService.updateFrequency(hz)
    }

    func updateDepthSettings(enabled: Bool, fps: Int) {
        arKitService.updateDepthSettings(enabled: enabled, fps: fps)
    }

    func updatePoseFPS(_ hz: Int) {
        arKitService.updatePoseFPS(hz)
    }

    func updateGPSFrequency(_ hz: Int) {
        gpsService.updateFrequency(hz)
    }

    // MARK: - FPS Calculation

    private func updateFPS() {
        let now = Date().timeIntervalSinceReferenceDate
        frameTimestamps.append(now)

        // Remove old timestamps
        frameTimestamps.removeAll { now - $0 > fpsWindow }

        // Calculate FPS
        currentFPS = Double(frameTimestamps.count) / fpsWindow
    }

    // MARK: - Statistics

    func getStatistics() -> StreamingStatistics {
        return StreamingStatistics(
            mode: currentMode,
            isStreaming: isStreaming,
            fps: currentFPS,
            sensorStatuses: sensorStatuses,
            recordingDuration: recordingManager.recordingDuration,
            recordingSize: recordingManager.fileSize
        )
    }
}

// MARK: - Camera Service Delegate

extension SensorManager: CameraServiceDelegate {
    func cameraService(_ service: CameraService, didCapture frame: CameraFrame) {
        updateFPS()

        // Stream to network
        networkManager.stream(cameraFrame: frame)

        // Record if enabled
        if recordingManager.isRecording {
            recordingManager.record(cameraFrame: frame)
        }
    }

    func cameraService(_ service: CameraService, didEncounterError error: Error) {
        print("Camera error: \(error)")
        sensorStatuses.camera = .error
        networkManager.sendError("camera_error", details: error.localizedDescription)
    }
}

// MARK: - ARKit Service Delegate

extension SensorManager: ARKitServiceDelegate {
    func arKitService(_ service: ARKitService, didUpdate pose: PoseData) {
        // Stream to network
        networkManager.stream(poseData: pose)

        // Record if enabled
        if recordingManager.isRecording {
            recordingManager.record(poseData: pose)
        }
    }

    func arKitService(_ service: ARKitService, didCapture depth: DepthFrame) {
        // Stream to network
        networkManager.stream(depthFrame: depth)

        // Record if enabled
        if recordingManager.isRecording {
            recordingManager.record(depthFrame: depth)
        }
    }

    func arKitService(_ service: ARKitService, didEncounterError error: Error) {
        print("ARKit error: \(error)")
        sensorStatuses.depth = .error
        sensorStatuses.pose = .error
        networkManager.sendError("arkit_error", details: error.localizedDescription)
    }
}

// MARK: - IMU Service Delegate

extension SensorManager: IMUServiceDelegate {
    func imuService(_ service: IMUService, didUpdate data: IMUData) {
        // Stream to network
        networkManager.stream(imuData: data)

        // Record if enabled
        if recordingManager.isRecording {
            recordingManager.record(imuData: data)
        }
    }

    func imuService(_ service: IMUService, didEncounterError error: Error) {
        print("IMU error: \(error)")
        sensorStatuses.imu = .error
        networkManager.sendError("imu_error", details: error.localizedDescription)
    }
}

// MARK: - GPS Service Delegate

extension SensorManager: GPSServiceDelegate {
    func gpsService(_ service: GPSService, didUpdate location: GPSData) {
        // Stream to network
        networkManager.stream(gpsData: location)

        // Record if enabled
        if recordingManager.isRecording {
            recordingManager.record(gpsData: location)
        }
    }

    func gpsService(_ service: GPSService, didEncounterError error: Error) {
        print("GPS error: \(error)")
        sensorStatuses.gps = .error
        networkManager.sendError("gps_error", details: error.localizedDescription)
    }
}

// MARK: - Sensor Status

enum SensorStatus: String {
    case inactive = "Inactive"
    case active = "Active"
    case error = "Error"
}

struct SensorStatuses {
    var camera: SensorStatus = .inactive
    var depth: SensorStatus = .inactive
    var pose: SensorStatus = .inactive
    var imu: SensorStatus = .inactive
    var gps: SensorStatus = .inactive
}

// MARK: - Statistics

struct StreamingStatistics {
    let mode: StreamMode
    let isStreaming: Bool
    let fps: Double
    let sensorStatuses: SensorStatuses
    let recordingDuration: TimeInterval
    let recordingSize: Int64

    var description: String {
        return """
        Mode: \(mode.rawValue)
        Streaming: \(isStreaming)
        FPS: \(String(format: "%.1f", fps))
        Recording: \(recordingDuration > 0 ? String(format: "%.1fs", recordingDuration) : "No")
        Size: \(recordingSize / 1024 / 1024) MB
        """
    }
}
