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

    // MARK: - Protocol Type Selection
    
    enum ProtocolType: String, CaseIterable, Identifiable {
        case websocket = "WebSocket"
        case grpc = "gRPC"
        case mqtt = "MQTT"
        case quic = "QUIC/HTTP3"
        case mcapStream = "MCAP Stream"
        case http = "HTTP/REST"
        
        var id: String { self.rawValue }
        
        var defaultPort: Int {
            switch self {
            case .websocket: return 9090
            case .grpc: return 50051
            case .mqtt: return 1883
            case .quic: return 4433
            case .mcapStream: return 9090  // Uses WebSocket underneath
            case .http: return 8080
            }
        }
        
        var description: String {
            switch self {
            case .websocket:
                return "Standard WebSocket (default)"
            case .grpc:
                return "gRPC - High performance, research standard"
            case .mqtt:
                return "MQTT - IoT, multi-subscriber"
            case .quic:
                return "QUIC/HTTP3 - Low latency (iOS 15+)"
            case .mcapStream:
                return "MCAP Stream - Robotics research"
            case .http:
                return "HTTP/REST - Simple integration"
            }
        }
    }

    @Published var selectedProtocol: ProtocolType = .websocket
    @Published private(set) var connectionState: ConnectionState = .disconnected
    @Published private(set) var statistics: NetworkStatistics?

    // Protocol adapter (abstraction layer)
    private var adapter: StreamingProtocol?
    
    // Legacy WebSocket service (for backward compatibility)
    private let webSocketService = WebSocketService()
    private var cancellables = Set<AnyCancellable>()

    private init() {
        webSocketService.delegate = self
    }

    // MARK: - Connection

    /// Connect using currently selected protocol
    func connect(host: String, port: Int? = nil) {
        let actualPort = port ?? selectedProtocol.defaultPort
        let config = ConnectionConfig(host: host, port: actualPort)
        connect(protocolType: selectedProtocol, config: config)
    }
    
    /// Connect using specific protocol
    func connect(protocolType: ProtocolType, config: ConnectionConfig) {
        selectedProtocol = protocolType
        
        // Create appropriate adapter
        adapter = createAdapter(for: protocolType)
        
        // Connect using adapter
        Task {
            do {
                try await adapter?.connect(config: config)
                print("✅ Connected using \(protocolType.rawValue)")
            } catch {
                print("❌ Failed to connect using \(protocolType.rawValue): \(error)")
                DispatchQueue.main.async {
                    self.connectionState = .error
                }
            }
        }
    }
    
    /// Legacy WebSocket connection (backward compatibility)
    func connectWebSocket(host: String, port: Int) {
        guard let url = URL(string: "ws://\(host):\(port)") else {
            print("Invalid WebSocket URL")
            return
        }

        webSocketService.connect(to: url)
        webSocketService.startHeartbeat()
    }

    func disconnect() {
        if let adapter = adapter {
            adapter.disconnect()
        } else {
            // Legacy path
        webSocketService.disconnect()
        }
    }
    
    // MARK: - Protocol Adapter Factory
    
    private func createAdapter(for protocolType: ProtocolType) -> StreamingProtocol? {
        switch protocolType {
        case .websocket:
            return createWebSocketAdapter()
        case .grpc:
            return createGRPCAdapter()
        case .mqtt:
            return createMQTTAdapter()
        case .quic:
            return createQUICAdapter()
        case .mcapStream:
            return createMCAPStreamAdapter()
        case .http:
            return createHTTPAdapter()
        }
    }
    
    private func createWebSocketAdapter() -> StreamingProtocol? {
        // Will be implemented with WebSocketAdapter
        print("⚠️ WebSocketAdapter not yet implemented, using legacy WebSocketService")
        return nil
    }
    
    private func createGRPCAdapter() -> StreamingProtocol? {
        // Will be implemented in Phase 3
        print("⚠️ GRPCAdapter not yet implemented")
        return nil
    }
    
    private func createMQTTAdapter() -> StreamingProtocol? {
        // Will be implemented in Phase 4
        print("⚠️ MQTTAdapter not yet implemented")
        return nil
    }
    
    private func createQUICAdapter() -> StreamingProtocol? {
        // Will be implemented in Phase 7
        print("⚠️ QUICAdapter not yet implemented")
        return nil
    }
    
    private func createMCAPStreamAdapter() -> StreamingProtocol? {
        // Will be implemented in Phase 5
        print("⚠️ MCAPStreamAdapter not yet implemented")
        return nil
    }
    
    private func createHTTPAdapter() -> StreamingProtocol? {
        // Will be implemented in Phase 6
        print("⚠️ HTTPAdapter not yet implemented")
        return nil
    }

    // MARK: - Streaming

    /// Stream IMU data
    func stream(imuData: IMUData) {
        do {
            if let adapter = adapter {
                try adapter.send(json: imuData)
            } else {
                // Legacy path
            try webSocketService.send(json: imuData)
            }
        } catch {
            print("Failed to stream IMU data: \(error)")
        }
    }

    /// Stream GPS data
    func stream(gpsData: GPSData) {
        do {
            print("📤 Sending GPS: (\(gpsData.latitude), \(gpsData.longitude)), accuracy: ±\(gpsData.horizontalAccuracy)m")
            if let adapter = adapter {
                try adapter.send(json: gpsData)
            } else {
                // Legacy path
            try webSocketService.send(json: gpsData)
            }
        } catch {
            print("❌ Failed to stream GPS data: \(error)")
        }
    }

    /// Stream pose data
    func stream(poseData: PoseData) {
        do {
            if let adapter = adapter {
                try adapter.send(json: poseData)
            } else {
                // Legacy path
            try webSocketService.send(json: poseData)
            }
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

            print("📤 Sending camera frame: \(cameraFrame.data.count) bytes, encoded: \(encoded.count) bytes")
            
            if let adapter = adapter {
                try adapter.send(data: encoded)
            } else {
                // Legacy path
            webSocketService.send(data: encoded, asText: false)
            }
        } catch {
            print("❌ Failed to stream camera frame: \(error)")
        }
    }

    /// Stream depth frame (binary message)
    func stream(depthFrame: DepthFrame) {
        do {
            let plyData = depthFrame.pointCloud.toPLY()
            print("📤 Sending depth frame: \(depthFrame.pointCloud.points.count) points, PLY size: \(plyData.count) bytes")
            let metadata = depthFrame.metadata()
            let header = try BinaryMessageHeader(metadata: metadata, dataSize: plyData.count)

            let message = BinaryMessage(header: header, data: plyData)
            let encoded = message.encode()

            if let adapter = adapter {
                try adapter.send(data: encoded)
            } else {
                // Legacy path
            webSocketService.send(data: encoded, asText: false)
            }
        } catch {
            print("Failed to stream depth frame: \(error)")
        }
    }

    /// Send mode configuration
    func sendModeConfig(_ mode: StreamMode) {
        let config = ModeConfigMessage(mode: mode, timestamp: TimestampManager.shared.now())

        do {
            if let adapter = adapter {
                try adapter.send(json: config)
            } else {
                // Legacy path
            try webSocketService.send(json: config)
            }
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
            if let adapter = adapter {
                try adapter.send(json: statusMsg)
            } else {
                // Legacy path
            try webSocketService.send(json: statusMsg)
            }
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
            if let adapter = adapter {
                try adapter.send(json: errorMsg)
            } else {
                // Legacy path
            try webSocketService.send(json: errorMsg)
            }
        } catch {
            print("Failed to send error: \(error)")
        }
    }

    // MARK: - Statistics

    func updateStatistics() {
        if let adapter = adapter {
            statistics = adapter.getStatistics()
        } else {
            // Legacy path
        statistics = webSocketService.getStatistics()
        }
    }

    func resetStatistics() {
        if let adapter = adapter {
            adapter.resetStatistics()
        } else {
            // Legacy path
        webSocketService.resetStatistics()
        }
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
