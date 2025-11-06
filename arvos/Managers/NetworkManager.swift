//
//  NetworkManager.swift
//  arvos
//
//  Coordinates network streaming of all sensor data
//

import Foundation
import Combine

class NetworkManager: ObservableObject {
    static let shared = NetworkManager()

    @Published private(set) var connectionState: ConnectionState = .disconnected
    @Published private(set) var statistics: NetworkStatistics?

    private let webSocketService = WebSocketService()
    private var cancellables = Set<AnyCancellable>()

    private init() {
        webSocketService.delegate = self
    }

    // MARK: - Connection

    func connect(host: String, port: Int) {
        guard let url = URL(string: "ws://\(host):\(port)") else {
            print("Invalid WebSocket URL")
            return
        }

        webSocketService.connect(to: url)
        webSocketService.startHeartbeat()
    }

    func disconnect() {
        webSocketService.disconnect()
    }

    // MARK: - Streaming

    /// Stream IMU data
    func stream(imuData: IMUData) {
        do {
            try webSocketService.send(json: imuData)
        } catch {
            print("Failed to stream IMU data: \(error)")
        }
    }

    /// Stream GPS data
    func stream(gpsData: GPSData) {
        do {
            try webSocketService.send(json: gpsData)
        } catch {
            print("Failed to stream GPS data: \(error)")
        }
    }

    /// Stream pose data
    func stream(poseData: PoseData) {
        do {
            try webSocketService.send(json: poseData)
        } catch {
            print("Failed to stream pose data: \(error)")
        }
    }

    /// Stream camera frame (binary message)
    func stream(cameraFrame: CameraFrame) {
        do {
            let metadata = cameraFrame.metadata()
            let header = try BinaryMessageHeader(metadata: metadata, dataSize: cameraFrame.data.count)

            // Create binary message
            let message = BinaryMessage(header: header, data: cameraFrame.data)
            let encoded = message.encode()

            webSocketService.send(data: encoded, asText: false)
        } catch {
            print("Failed to stream camera frame: \(error)")
        }
    }

    /// Stream depth frame (binary message)
    func stream(depthFrame: DepthFrame) {
        do {
            let plyData = depthFrame.pointCloud.toPLY()
            let metadata = depthFrame.metadata()
            let header = try BinaryMessageHeader(metadata: metadata, dataSize: plyData.count)

            let message = BinaryMessage(header: header, data: plyData)
            let encoded = message.encode()

            webSocketService.send(data: encoded, asText: false)
        } catch {
            print("Failed to stream depth frame: \(error)")
        }
    }

    /// Send mode configuration
    func sendModeConfig(_ mode: StreamMode) {
        let config = ModeConfigMessage(mode: mode, timestamp: TimestampManager.shared.now())

        do {
            try webSocketService.send(json: config)
        } catch {
            print("Failed to send mode config: \(error)")
        }
    }

    /// Send status message
    func sendStatus(_ status: String, message: String? = nil, sessionId: String? = nil) {
        let statusMsg = StatusMessage(
            timestamp: TimestampManager.shared.now(),
            status: status,
            message: message,
            sessionId: sessionId
        )

        do {
            try webSocketService.send(json: statusMsg)
        } catch {
            print("Failed to send status: \(error)")
        }
    }

    /// Send error message
    func sendError(_ error: String, details: String? = nil) {
        let errorMsg = ErrorMessage(
            timestamp: TimestampManager.shared.now(),
            error: error,
            details: details
        )

        do {
            try webSocketService.send(json: errorMsg)
        } catch {
            print("Failed to send error: \(error)")
        }
    }

    // MARK: - Statistics

    func updateStatistics() {
        statistics = webSocketService.getStatistics()
    }

    func resetStatistics() {
        webSocketService.resetStatistics()
        updateStatistics()
    }
}

// MARK: - WebSocketServiceDelegate

extension NetworkManager: WebSocketServiceDelegate {
    func webSocketService(_ service: WebSocketService, didChangeState state: ConnectionState) {
        DispatchQueue.main.async {
            self.connectionState = state
        }
    }

    func webSocketService(_ service: WebSocketService, didReceiveMessage message: String) {
        // Handle incoming messages from server (commands, acknowledgments, etc.)
        print("Received message: \(message)")

        // Parse and handle server commands
        if let data = message.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {

            if let type = json["type"] as? String {
                switch type {
                case "command":
                    handleCommand(json)
                case "ack":
                    // Message acknowledged
                    break
                default:
                    break
                }
            }
        }
    }

    func webSocketService(_ service: WebSocketService, didEncounterError error: Error) {
        print("WebSocket error: \(error.localizedDescription)")
        sendError("websocket_error", details: error.localizedDescription)
    }

    private func handleCommand(_ json: [String: Any]) {
        // Handle server commands (e.g., change mode, start/stop recording)
        guard let command = json["command"] as? String else { return }

        switch command {
        case "start_recording":
            // Notify app to start recording
            NotificationCenter.default.post(name: .startRecording, object: nil)
        case "stop_recording":
            // Notify app to stop recording
            NotificationCenter.default.post(name: .stopRecording, object: nil)
        case "change_mode":
            if let modeString = json["mode"] as? String,
               let mode = StreamMode.allCases.first(where: { $0.rawValue == modeString }) {
                NotificationCenter.default.post(name: .changeMode, object: mode)
            }
        default:
            break
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let startRecording = Notification.Name("startRecording")
    static let stopRecording = Notification.Name("stopRecording")
    static let changeMode = Notification.Name("changeMode")
}
