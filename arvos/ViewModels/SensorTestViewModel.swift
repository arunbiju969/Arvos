//
//  SensorTestViewModel.swift
//  arvos
//
//  ViewModel for real-time sensor testing and visualization
//

import SwiftUI
import Combine
import CoreLocation

class SensorTestViewModel: ObservableObject {
    // Managers
    private let sensorManager = SensorManager.shared

    // Published state
    @Published var isRunning = false

    // Sensor toggles
    @Published var showLiDAR = true
    @Published var showCamera = true
    @Published var showIMU = true
    @Published var showPose = true
    @Published var showGPS = true

    // Latest sensor data
    @Published var latestPointCloud: PointCloud?
    @Published var latestDepthSample: DepthVisualizationSample?
    @Published var latestCameraImage: UIImage?
    @Published var latestIMU: IMUData?
    @Published var latestPose: PoseData?
    @Published var latestGPS: GPSData?

    // Metadata
    @Published var cameraResolution: String?

    private var cancellables = Set<AnyCancellable>()

    init() {
        setupBindings()
    }

    private func setupBindings() {
        // Observe sensor manager updates
        sensorManager.$isStreaming
            .assign(to: &$isRunning)
    }

    func toggleTesting() {
        if isRunning {
            stopTesting()
        } else {
            startTesting()
        }
    }

    func startTesting() {
        // Set mode to full sensor for testing
        sensorManager.setMode(.fullSensor)

        // Set delegates to capture data
        sensorManager.arKitService.delegate = self
        sensorManager.cameraService.delegate = self
        sensorManager.imuService.delegate = self
        sensorManager.gpsService.delegate = self

        // Start streaming
        sensorManager.startStreaming()
    }

    func stopTesting() {
        sensorManager.stopStreaming()

        // Clear data
        latestPointCloud = nil
        latestDepthSample = nil
        latestCameraImage = nil
        latestIMU = nil
        latestPose = nil
        latestGPS = nil
        cameraResolution = nil
    }
}

// MARK: - ARKitServiceDelegate

extension SensorTestViewModel: ARKitServiceDelegate {
    func arKitService(_ service: ARKitService, didCapture frame: CameraFrame) {
        DispatchQueue.main.async {
            if self.showCamera {
                self.latestCameraImage = UIImage(data: frame.data)
                self.cameraResolution = "\(frame.width)×\(frame.height)"
            }
        }
    }

    func arKitService(_ service: ARKitService, didCapture frame: DepthFrame) {
        DispatchQueue.main.async {
            if self.showLiDAR {
                self.latestPointCloud = frame.pointCloud
            }
        }
    }

    func arKitService(_ service: ARKitService, didOutputDepthSample sample: DepthVisualizationSample) {
        DispatchQueue.main.async {
            if self.showLiDAR {
                self.latestDepthSample = sample
            }
        }
    }

    func arKitService(_ service: ARKitService, didUpdate pose: PoseData) {
        DispatchQueue.main.async {
            if self.showPose {
                self.latestPose = pose
            }
        }
    }

    func arKitService(_ service: ARKitService, didEncounterError error: Error) {
        print("❌ ARKit error: \(error)")
    }
}

// MARK: - CameraServiceDelegate

extension SensorTestViewModel: CameraServiceDelegate {
    func cameraService(_ service: CameraService, didCapture frame: CameraFrame) {
        DispatchQueue.main.async {
            if self.showCamera && !self.sensorManager.usingARKitCamera {
                self.latestCameraImage = UIImage(data: frame.data)
                self.cameraResolution = "\(frame.width)×\(frame.height)"
            }
        }
    }

    func cameraService(_ service: CameraService, didEncounterError error: Error) {
        print("❌ Camera error: \(error)")
    }
}

// MARK: - IMUServiceDelegate

extension SensorTestViewModel: IMUServiceDelegate {
    func imuService(_ service: IMUService, didUpdate data: IMUData) {
        DispatchQueue.main.async {
            if self.showIMU {
                self.latestIMU = data
            }
        }
    }

    func imuService(_ service: IMUService, didEncounterError error: Error) {
        print("❌ IMU error: \(error)")
    }
}

// MARK: - GPSServiceDelegate

extension SensorTestViewModel: GPSServiceDelegate {
    func gpsService(_ service: GPSService, didUpdate location: GPSData) {
        DispatchQueue.main.async {
            if self.showGPS {
                self.latestGPS = location
            }
        }
    }

    func gpsService(_ service: GPSService, didEncounterError error: Error) {
        print("❌ GPS error: \(error)")
    }
}
