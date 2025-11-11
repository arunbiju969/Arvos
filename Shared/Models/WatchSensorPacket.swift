//
//  WatchSensorPacket.swift
//  arvos
//
//  Data packet for watch sensor transmission
//

import Foundation
import simd

/// Packet containing sensor data from Apple Watch
struct WatchSensorPacket: Codable {
    let timestampNs: UInt64
    let sensorType: String
    let data: Data
    
    /// Create an IMU packet from watch sensor data
    static func imu(timestamp: UInt64, angularVelocity: SIMD3<Double>, linearAcceleration: SIMD3<Double>, gravity: SIMD3<Double>) -> WatchSensorPacket {
        let imuData = WatchIMUData(
            angularVelocity: angularVelocity,
            linearAcceleration: linearAcceleration,
            gravity: gravity
        )
        
        let encoded = try! JSONEncoder().encode(imuData)
        
        return WatchSensorPacket(
            timestampNs: timestamp,
            sensorType: "watch_imu",
            data: encoded
        )
    }
    
    /// Decode IMU data from packet
    func decodeIMU() -> WatchIMUData? {
        guard sensorType == "watch_imu" else { return nil }
        return try? JSONDecoder().decode(WatchIMUData.self, from: data)
    }
}

/// Watch IMU sensor data
struct WatchIMUData: Codable {
    let angularVelocity: SIMD3<Double>
    let linearAcceleration: SIMD3<Double>
    let gravity: SIMD3<Double>
}

/// Watch heart rate data (future extension)
struct WatchHeartRateData: Codable {
    let bpm: Double
    let confidence: Double
}

/// Watch workout metrics (future extension)
struct WatchWorkoutData: Codable {
    let activeCalories: Double
    let distance: Double
    let steps: Int
}

