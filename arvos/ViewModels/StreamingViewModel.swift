//
//  StreamingViewModel.swift
//  arvos
//
//  ViewModel for streaming and sensor control
//

import Foundation
import Combine
import SwiftUI

class StreamingViewModel: ObservableObject {
    // Managers
    private let sensorManager = SensorManager.shared
    private let networkManager = NetworkManager.shared
    private let recordingManager = RecordingManager()

    // Published properties
    @Published var selectedMode: StreamMode = .fullSensor
    @Published var isStreaming = false
    @Published var isConnected = false
    @Published var connectionHost = ""
    @Published var connectionPort = "9090"

    @Published var currentFPS: Double = 0
    @Published var sensorStatuses: SensorStatuses = SensorStatuses()
    @Published var recordingDuration: TimeInterval = 0
    @Published var recordingSize: Int64 = 0

    @Published var showingQRScanner = false
    @Published var showingConnectionSheet = false
    @Published var showingSettings = false
    // Removed LiDAR preview - it was causing ARFrame retention issues

    private var cancellables = Set<AnyCancellable>()
    private var updateTimer: Timer?
    private let updateQueue = DispatchQueue(label: "com.arvos.viewmodel.stats", qos: .utility)

    init() {
        setupBindings()
        startUpdateTimer()
    }

    private func setupBindings() {
        // Observe sensor manager
        sensorManager.$currentMode
            .assign(to: &$selectedMode)

        sensorManager.$isStreaming
            .assign(to: &$isStreaming)

        // Observe network manager
        networkManager.$connectionState
            .map { $0 == .connected }
            .assign(to: &$isConnected)
    }

    private func startUpdateTimer() {
        // Reduced from 0.5s to 1.0s to halve UI update frequency
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateStatistics()
        }
    }

    private func updateStatistics() {
        // Move stats calculation to background queue
        updateQueue.async { [weak self] in
            guard let self = self else { return }
            let stats = self.sensorManager.getStatistics()

            // Only update on main thread if values actually changed
            DispatchQueue.main.async {
                if abs(self.currentFPS - stats.fps) > 0.1 {
                    self.currentFPS = stats.fps
                }
                if self.sensorStatuses != stats.sensorStatuses {
                    self.sensorStatuses = stats.sensorStatuses
                }
                if abs(self.recordingDuration - stats.recordingDuration) > 0.5 {
                    self.recordingDuration = stats.recordingDuration
                }
                if self.recordingSize != stats.recordingSize {
                    self.recordingSize = stats.recordingSize
                }
            }
        }
    }

    // MARK: - Actions

    func selectMode(_ mode: StreamMode) {
        guard !isStreaming else { return }
        selectedMode = mode
        sensorManager.setMode(mode)
    }

    func toggleStreaming() {
        if isStreaming {
            stopStreaming()
        } else {
            startStreaming()
        }
    }

    func startStreaming() {
        guard !connectionHost.isEmpty else {
            showingConnectionSheet = true
            return
        }

        // Connect to server
        if !isConnected {
            connectToServer()
        }

        // Start sensors
        sensorManager.startStreaming()
    }

    func stopStreaming() {
        sensorManager.stopStreaming()
    }

    func connectToServer() {
        guard !connectionHost.isEmpty, let port = Int(connectionPort) else { return }
        networkManager.connect(host: connectionHost, port: port)
    }

    func disconnect() {
        networkManager.disconnect()
    }

    func scanQRCode(_ code: String) {
        // Parse QR code: ws://192.168.1.100:9090
        if let url = URL(string: code),
           let host = url.host,
           let port = url.port {
            connectionHost = host
            connectionPort = String(port)
            connectToServer()
        }
    }

    // MARK: - Sensor Controls

    func updateDataSources(camera: Bool, depth: Bool, imu: Bool, pose: Bool, gps: Bool) {
        // Create custom mode based on user selection
        let customMode: StreamMode = .fullSensor // Use as base
        sensorManager.setMode(customMode)

        // Then dynamically enable/disable sensors
        if !camera {
            // Disable camera - set to 0 FPS
            sensorManager.updateCameraFPS(0)
        }

        sensorManager.updateDepthSettings(enabled: depth, fps: depth ? 5 : 0)

        if !imu {
            sensorManager.updateIMUFrequency(0)
        }

        if !pose {
            sensorManager.updatePoseFPS(0)
        }

        if !gps {
            sensorManager.updateGPSFrequency(0)
        }

        print("📊 Data sources updated: Camera=\(camera), Depth=\(depth), IMU=\(imu), Pose=\(pose), GPS=\(gps)")
    }

    func updateCameraFPS(_ fps: Int) {
        sensorManager.updateCameraFPS(fps)
    }

    func updateIMUHz(_ hz: Int) {
        sensorManager.updateIMUFrequency(hz)
    }

    func updateDepthFPS(_ fps: Int) {
        sensorManager.updateDepthSettings(enabled: true, fps: fps)
    }

    func updatePoseHz(_ hz: Int) {
        sensorManager.updatePoseFPS(hz)
    }

    // MARK: - LiDAR Preview Controls
    // Removed - LiDAR preview was causing ARFrame retention issues and poor performance

    // MARK: - Formatting Helpers

    var recordingDurationFormatted: String {
        let minutes = Int(recordingDuration) / 60
        let seconds = Int(recordingDuration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var recordingSizeFormatted: String {
        let mb = Double(recordingSize) / (1024.0 * 1024.0)
        if mb < 1.0 {
            let kb = Double(recordingSize) / 1024.0
            return String(format: "%.0f KB", kb)
        }
        return String(format: "%.1f MB", mb)
    }

    var fpsFormatted: String {
        return String(format: "%.1f", currentFPS)
    }

    var burstScanRemainingTime: String? {
        guard let remaining = sensorManager.burstScanRemainingTime else { return nil }
        return String(format: "%.0fs", remaining)
    }

    deinit {
        updateTimer?.invalidate()
    }
}
