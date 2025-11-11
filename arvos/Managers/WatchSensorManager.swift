//
//  WatchSensorManager.swift
//  arvos
//
//  Manages watch sensor data integration on iPhone
//

import Foundation
import Combine

protocol WatchSensorManagerDelegate: AnyObject {
    func watchSensorManager(_ manager: WatchSensorManager, didReceiveIMU data: IMUData)
}

class WatchSensorManager: ObservableObject {
    static let shared = WatchSensorManager()
    
    @Published private(set) var isWatchConnected = false
    @Published private(set) var isWatchStreaming = false
    @Published private(set) var watchSampleCount: Int = 0
    @Published private(set) var watchHz: Double = 0
    
    weak var delegate: WatchSensorManagerDelegate?
    
    private let connectivityService = WatchConnectivityService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // FPS tracking
    private var sampleTimestamps: [TimeInterval] = []
    private let fpsWindow: TimeInterval = 1.0
    
    // Time synchronization
    private var timeOffsetNs: Int64 = 0 // Offset between watch and phone clocks
    private var lastSyncTime: Date?
    
    private init() {
        setupConnectivity()
        setupObservers()
    }
    
    private func setupConnectivity() {
        connectivityService.delegate = self
    }
    
    private func setupObservers() {
        // Observe watch reachability
        connectivityService.$isWatchReachable
            .sink { [weak self] isReachable in
                self?.isWatchConnected = isReachable
                if !isReachable {
                    self?.isWatchStreaming = false
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Control
    
    func startWatchStreaming(hz: Int = 50) {
        guard isWatchConnected else {
            print("⚠️ Cannot start watch streaming: watch not connected")
            return
        }
        
        connectivityService.sendCommand("start_streaming", parameters: ["hz": hz])
        isWatchStreaming = true
        watchSampleCount = 0
        sampleTimestamps.removeAll()
        
        // Perform time sync
        performTimeSync()
        
        print("✅ Requested watch to start streaming at \(hz) Hz")
    }
    
    func stopWatchStreaming() {
        guard isWatchStreaming else { return }
        
        connectivityService.sendCommand("stop_streaming")
        isWatchStreaming = false
        watchHz = 0
        
        print("⏹️ Requested watch to stop streaming")
    }
    
    func updateWatchFrequency(_ hz: Int) {
        guard isWatchStreaming else { return }
        connectivityService.sendCommand("update_frequency", parameters: ["hz": hz])
    }
    
    // MARK: - Time Synchronization
    
    private func performTimeSync() {
        // Simple time sync: record the offset between watch timestamp and phone timestamp
        // For more accuracy, could implement NTP-style round-trip time measurement
        lastSyncTime = Date()
        
        // Send sync request to watch
        let phoneTime = UInt64(Date().timeIntervalSinceReferenceDate * 1_000_000_000)
        connectivityService.sendCommand("time_sync", parameters: ["phone_time_ns": phoneTime])
    }
    
    private func adjustTimestamp(_ watchTimestampNs: UInt64) -> UInt64 {
        // Apply time offset to align watch timestamps with phone timeline
        // For now, use watch timestamps directly
        // TODO: Implement proper time synchronization with round-trip measurement
        return watchTimestampNs
    }
    
    // MARK: - Statistics
    
    func getStatistics() -> WatchStatistics {
        return WatchStatistics(
            isConnected: isWatchConnected,
            isStreaming: isWatchStreaming,
            sampleCount: watchSampleCount,
            hz: watchHz,
            messagesSent: connectivityService.messagesSent,
            messagesReceived: connectivityService.messagesReceived,
            bytesSent: connectivityService.bytesSent
        )
    }
    
    func resetStatistics() {
        DispatchQueue.main.async {
            self.watchSampleCount = 0
            self.watchHz = 0
            self.sampleTimestamps.removeAll()
        }
        connectivityService.resetStatistics()
    }
    
    private func updateFPS() {
        let now = Date().timeIntervalSinceReferenceDate
        sampleTimestamps.append(now)
        
        // Remove old timestamps
        sampleTimestamps.removeAll { now - $0 > fpsWindow }
        
        // Calculate FPS
        watchHz = Double(sampleTimestamps.count) / fpsWindow
    }
}

// MARK: - WatchConnectivityDelegate

extension WatchSensorManager: WatchConnectivityDelegate {
    func watchConnectivity(_ service: WatchConnectivityService, didReceivePacket packet: WatchSensorPacket) {
        // Adjust timestamp
        let adjustedTimestamp = adjustTimestamp(packet.timestampNs)
        
        // Handle different packet types
        switch packet.sensorType {
        case "watch_imu":
            guard let watchIMU = packet.decodeIMU() else { return }
            
            // Convert to standard IMUData format
            let imuData = IMUData(
                timestampNs: adjustedTimestamp,
                angularVelocity: watchIMU.angularVelocity,
                linearAcceleration: watchIMU.linearAcceleration,
                gravity: watchIMU.gravity
            )
            
            // Forward to delegate immediately
            delegate?.watchSensorManager(self, didReceiveIMU: imuData)
            
            // Update published stats on the main thread
            DispatchQueue.main.async {
                self.watchSampleCount += 1
                self.updateFPS()
            }
            
        default:
            print("⚠️ Unknown watch sensor type: \(packet.sensorType)")
        }
    }
    
    func watchConnectivity(_ service: WatchConnectivityService, didChangeReachability isReachable: Bool) {
        isWatchConnected = isReachable
        
        if !isReachable {
            isWatchStreaming = false
            watchHz = 0
        }
        
        print("📱 Watch reachability changed: \(isReachable)")
    }
}

// MARK: - Statistics

struct WatchStatistics {
    let isConnected: Bool
    let isStreaming: Bool
    let sampleCount: Int
    let hz: Double
    let messagesSent: Int
    let messagesReceived: Int
    let bytesSent: Int64
    
    var description: String {
        return """
        Watch Connected: \(isConnected)
        Watch Streaming: \(isStreaming)
        Sample Rate: \(String(format: "%.1f Hz", hz))
        Samples: \(sampleCount)
        Messages Sent: \(messagesSent)
        Messages Received: \(messagesReceived)
        Data Sent: \(bytesSent / 1024) KB
        """
    }
}

