//
//  WatchSensorService.swift
//  arvosWatchApp
//
//  Captures IMU and other sensor data on Apple Watch
//

import Foundation
import CoreMotion
import Combine

class WatchSensorService: ObservableObject {
    @Published private(set) var isStreaming = false
    @Published private(set) var currentHz: Double = 0
    @Published private(set) var sampleCount: Int = 0
    
    private let motionManager = CMMotionManager()
    private let connectivityService = WatchConnectivityService.shared
    
    private var updateTimer: Timer?
    private var sampleTimestamps: [TimeInterval] = []
    private let fpsWindow: TimeInterval = 1.0
    
    // Configuration
    private var targetHz: Int = 50 // Default to 50Hz for watch (battery friendly)
    private var updateInterval: TimeInterval {
        return 1.0 / Double(targetHz)
    }
    
    init() {
        setupMotionManager()
        setupCommandObserver()
    }
    
    private func setupCommandObserver() {
        NotificationCenter.default.addObserver(
            forName: .watchCommandReceived,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let command = notification.userInfo?["command"] as? String,
                  let parameters = notification.userInfo?["parameters"] as? [String: Any] else {
                return
            }
            
            self.handleCommand(command, parameters: parameters)
        }
    }
    
    private func handleCommand(_ command: String, parameters: [String: Any]) {
        switch command {
        case "start_streaming":
            let hz = parameters["hz"] as? Int ?? 50
            startStreaming(hz: hz)
            
        case "stop_streaming":
            stopStreaming()
            
        case "update_frequency":
            let hz = parameters["hz"] as? Int ?? 50
            updateFrequency(hz)
            
        default:
            print("⚠️ Unknown command: \(command)")
        }
    }
    
    private func setupMotionManager() {
        guard motionManager.isDeviceMotionAvailable else {
            print("❌ Device motion not available on this watch")
            return
        }
        
        motionManager.deviceMotionUpdateInterval = updateInterval
    }
    
    // MARK: - Streaming Control
    
    func startStreaming(hz: Int = 50) {
        guard !isStreaming else { return }
        guard motionManager.isDeviceMotionAvailable else {
            print("❌ Cannot start streaming: device motion not available")
            return
        }
        
        targetHz = min(hz, 100) // Cap at 100Hz for watch
        motionManager.deviceMotionUpdateInterval = updateInterval
        
        // Start motion updates
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .userInitiated
        
        motionManager.startDeviceMotionUpdates(to: queue) { [weak self] (motion, error) in
            guard let self = self, let motion = motion else {
                if let error = error {
                    print("❌ Motion update error: \(error)")
                }
                return
            }
            
            self.handleMotionUpdate(motion)
        }
        
        isStreaming = true
        sampleCount = 0
        sampleTimestamps.removeAll()
        
        print("✅ Watch sensor streaming started at \(targetHz) Hz")
    }
    
    func stopStreaming() {
        guard isStreaming else { return }
        
        motionManager.stopDeviceMotionUpdates()
        updateTimer?.invalidate()
        updateTimer = nil
        
        isStreaming = false
        currentHz = 0
        
        print("⏹️ Watch sensor streaming stopped")
    }
    
    func updateFrequency(_ hz: Int) {
        let newHz = min(hz, 100)
        guard newHz != targetHz else { return }
        
        targetHz = newHz
        
        if isStreaming {
            stopStreaming()
            startStreaming(hz: targetHz)
        }
    }
    
    // MARK: - Motion Handling
    
    private func handleMotionUpdate(_ motion: CMDeviceMotion) {
        // Create timestamp (nanoseconds since reference date)
        let timestamp = UInt64(motion.timestamp * 1_000_000_000)
        
        // Extract IMU data
        let angularVelocity = SIMD3<Double>(
            motion.rotationRate.x,
            motion.rotationRate.y,
            motion.rotationRate.z
        )
        
        let linearAcceleration = SIMD3<Double>(
            motion.userAcceleration.x,
            motion.userAcceleration.y,
            motion.userAcceleration.z
        )
        
        let gravity = SIMD3<Double>(
            motion.gravity.x,
            motion.gravity.y,
            motion.gravity.z
        )
        
        // Create packet
        let packet = WatchSensorPacket.imu(
            timestamp: timestamp,
            angularVelocity: angularVelocity,
            linearAcceleration: linearAcceleration,
            gravity: gravity
        )
        
        // Send to phone
        connectivityService.send(packet: packet)
        
        // Update statistics
        DispatchQueue.main.async {
            self.sampleCount += 1
            self.updateFPS()
        }
    }
    
    private func updateFPS() {
        let now = Date().timeIntervalSinceReferenceDate
        sampleTimestamps.append(now)
        
        // Remove old timestamps
        sampleTimestamps.removeAll { now - $0 > fpsWindow }
        
        // Calculate FPS
        currentHz = Double(sampleTimestamps.count) / fpsWindow
    }
    
    // MARK: - Future Extensions
    
    // Placeholder for heart rate monitoring
    func startHeartRateMonitoring() {
        // TODO: Implement HealthKit heart rate monitoring
        print("⚠️ Heart rate monitoring not yet implemented")
    }
    
    // Placeholder for workout metrics
    func startWorkoutSession() {
        // TODO: Implement workout session with metrics
        print("⚠️ Workout session not yet implemented")
    }
}

