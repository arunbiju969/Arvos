//
//  SensorData.swift
//  arvos
//
//  Data structures for all sensor types
//

import Foundation
import CoreMotion
import CoreLocation
import ARKit
import simd

// MARK: - Base Protocol

/// Base protocol for all sensor data with timestamps
protocol SensorData: Codable {
    var timestampNs: UInt64 { get }
    var sensorType: String { get }
}

// MARK: - IMU Data

/// Accelerometer and gyroscope data from CoreMotion
struct IMUData: SensorData {
    let timestampNs: UInt64
    let sensorType: String = "imu"

    /// Angular velocity in rad/s (x, y, z)
    let angularVelocity: SIMD3<Double>

    /// Linear acceleration in m/s² (x, y, z)
    let linearAcceleration: SIMD3<Double>

    /// Magnetic field in microteslas (optional)
    let magneticField: SIMD3<Double>?

    /// Device attitude (optional)
    let attitude: Attitude?

    /// Gravity vector in m/s² (for calibration reference)
    let gravity: SIMD3<Double>

    /// Magnetic field accuracy (0=uncalibrated, 1=low, 2=medium, 3=high)
    let magneticFieldAccuracy: Int

    init(timestamp: UInt64, motion: CMDeviceMotion) {
        self.timestampNs = timestamp
        self.angularVelocity = SIMD3(
            motion.rotationRate.x,
            motion.rotationRate.y,
            motion.rotationRate.z
        )
        self.linearAcceleration = SIMD3(
            motion.userAcceleration.x,
            motion.userAcceleration.y,
            motion.userAcceleration.z
        )

        // Gravity vector (calibration reference)
        self.gravity = SIMD3(
            motion.gravity.x,
            motion.gravity.y,
            motion.gravity.z
        )

        // Magnetic field and accuracy
        if motion.magneticField.accuracy != .uncalibrated {
            self.magneticField = SIMD3(
                motion.magneticField.field.x,
                motion.magneticField.field.y,
                motion.magneticField.field.z
            )
        } else {
            self.magneticField = nil
        }

        switch motion.magneticField.accuracy {
        case .uncalibrated:
            self.magneticFieldAccuracy = 0
        case .low:
            self.magneticFieldAccuracy = 1
        case .medium:
            self.magneticFieldAccuracy = 2
        case .high:
            self.magneticFieldAccuracy = 3
        @unknown default:
            self.magneticFieldAccuracy = 0
        }

        self.attitude = Attitude(
            roll: motion.attitude.roll,
            pitch: motion.attitude.pitch,
            yaw: motion.attitude.yaw
        )
    }

    // Memberwise initializer for custom use
    init(timestampNs: UInt64, angularVelocity: SIMD3<Double>, linearAcceleration: SIMD3<Double>, magneticField: SIMD3<Double>? = nil, attitude: Attitude? = nil, gravity: SIMD3<Double> = SIMD3(0, 0, -9.81), magneticFieldAccuracy: Int = 0) {
        self.timestampNs = timestampNs
        self.angularVelocity = angularVelocity
        self.linearAcceleration = linearAcceleration
        self.magneticField = magneticField
        self.attitude = attitude
        self.gravity = gravity
        self.magneticFieldAccuracy = magneticFieldAccuracy
    }
}

/// Device attitude (orientation)
struct Attitude: Codable {
    let roll: Double
    let pitch: Double
    let yaw: Double
}

// MARK: - GPS Data

/// GPS location data from CoreLocation
struct GPSData: SensorData {
    let timestampNs: UInt64
    let sensorType: String = "gps"

    let latitude: Double
    let longitude: Double
    let altitude: Double
    let horizontalAccuracy: Double
    let verticalAccuracy: Double
    let speed: Double // m/s
    let course: Double // degrees

    init(timestamp: UInt64, location: CLLocation) {
        self.timestampNs = timestamp
        self.latitude = location.coordinate.latitude
        self.longitude = location.coordinate.longitude
        self.altitude = location.altitude
        self.horizontalAccuracy = location.horizontalAccuracy
        self.verticalAccuracy = location.verticalAccuracy
        self.speed = location.speed
        self.course = location.course
    }
}

// MARK: - ARKit Pose Data

/// 6DOF pose from ARKit world tracking
struct PoseData: SensorData {
    let timestampNs: UInt64
    let sensorType: String = "pose"

    /// Position in 3D space (x, y, z) in meters
    let position: SIMD3<Float>

    /// Orientation as quaternion (x, y, z, w)
    let orientation: SIMD4<Float>

    /// Tracking state quality
    let trackingState: String

    /// Whether tracking quality is good (helper for researchers)
    var isTrackingGood: Bool {
        return trackingState == "normal"
    }

    init(timestamp: UInt64, camera: ARCamera) {
        self.timestampNs = timestamp

        let transform = camera.transform
        self.position = SIMD3(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)

        // Convert rotation matrix to quaternion
        let quat = simd_quaternion(transform)
        self.orientation = SIMD4(quat.vector.x, quat.vector.y, quat.vector.z, quat.vector.w)

        switch camera.trackingState {
        case .normal:
            self.trackingState = "normal"
        case .limited(let reason):
            self.trackingState = "limited_\(reason)"
        case .notAvailable:
            self.trackingState = "not_available"
        @unknown default:
            self.trackingState = "unknown"
        }
    }
}

// MARK: - Camera Frame Metadata

/// Camera frame metadata (actual image sent as binary)
struct CameraFrameMetadata: SensorData {
    let timestampNs: UInt64
    let sensorType: String = "camera"

    let width: Int
    let height: Int
    let format: String // "jpeg", "h264"
    let compressedSize: Int // bytes
    let intrinsics: CameraIntrinsics?

    init(timestamp: UInt64, width: Int, height: Int, format: String, size: Int, intrinsics: CameraIntrinsics? = nil) {
        self.timestampNs = timestamp
        self.width = width
        self.height = height
        self.format = format
        self.compressedSize = size
        self.intrinsics = intrinsics
    }
}

/// Camera intrinsic parameters
struct CameraIntrinsics: Codable {
    let fx: Float // focal length x
    let fy: Float // focal length y
    let cx: Float // principal point x
    let cy: Float // principal point y

    init(intrinsics: simd_float3x3) {
        self.fx = intrinsics[0][0]
        self.fy = intrinsics[1][1]
        self.cx = intrinsics[2][0]
        self.cy = intrinsics[2][1]
    }
}

// MARK: - Depth Data Metadata

/// Depth/point cloud metadata (actual data sent as binary)
struct DepthFrameMetadata: SensorData {
    let timestampNs: UInt64
    let sensorType: String = "depth"

    let width: Int
    let height: Int
    let pointCount: Int
    let format: String // "raw_depth", "point_cloud"
    let compressedSize: Int
    let minDepth: Float // meters
    let maxDepth: Float // meters
    let hasConfidenceData: Bool // Whether depth confidence map is available

    init(timestamp: UInt64, width: Int, height: Int, pointCount: Int, format: String, size: Int, minDepth: Float, maxDepth: Float, hasConfidenceData: Bool = false) {
        self.timestampNs = timestamp
        self.width = width
        self.height = height
        self.pointCount = pointCount
        self.format = format
        self.compressedSize = size
        self.minDepth = minDepth
        self.maxDepth = maxDepth
        self.hasConfidenceData = hasConfidenceData
    }
}

// MARK: - Point Cloud

/// 3D point cloud from LiDAR or ARKit depth
struct PointCloud {
    let timestamp: UInt64
    let points: [SIMD3<Float>] // xyz positions
    let colors: [SIMD3<UInt8>]? // rgb colors (optional)
    let confidenceLevels: [UInt8]? // Confidence per point: 0=low, 1=medium, 2=high (optional)

    /// Convert to PLY format binary data
    func toPLY() -> Data {
        var ply = Data()

        // PLY header
        let colorProps = colors != nil ? "property uchar red\nproperty uchar green\nproperty uchar blue\n" : ""
        let confidenceProps = confidenceLevels != nil ? "property uchar confidence\n" : ""
        let header = """
        ply
        format binary_little_endian 1.0
        element vertex \(points.count)
        property float x
        property float y
        property float z
        \(colorProps)\(confidenceProps)end_header

        """
        ply.append(header.data(using: .utf8)!)

        // Vertex data
        for i in 0..<points.count {
            var point = points[i]
            ply.append(Data(bytes: &point, count: MemoryLayout<SIMD3<Float>>.size))

            if let colors = colors {
                var color = colors[i]
                ply.append(Data(bytes: &color, count: MemoryLayout<SIMD3<UInt8>>.size))
            }

            if let confidence = confidenceLevels {
                var conf = confidence[i]
                ply.append(Data(bytes: &conf, count: MemoryLayout<UInt8>.size))
            }
        }

        return ply
    }
}
