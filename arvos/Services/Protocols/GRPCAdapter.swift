//
//  GRPCAdapter.swift
//  arvos
//
//  gRPC streaming adapter using Protocol Buffers
//  Note: Requires iOS 18+ due to GRPCCore API
//

import Foundation
#if canImport(GRPCCore)
import GRPCCore
import GRPCProtobuf
#endif
import SwiftProtobuf

@available(iOS 18.0, *)
final class GRPCAdapter: NSObject, StreamingProtocol {
    weak var delegate: StreamingProtocolDelegate?
    
    private(set) var state: ConnectionState = .disconnected {
        didSet {
            if oldValue != state {
                delegate?.streamingProtocol(self, didChangeState: state)
            }
        }
    }
    
    private let protocolDisplayName = "gRPC"
    
    private var client: Arvos_SensorStream.Client<GRPCCore.ClientConnection>?
    private var requestStream: GRPCCore.AsyncStream<Arvos_SensorMessage>.Continuation?
    private var responseTask: Task<Void, Never>?
    
    private var bytesSent: Int64 = 0
    private var messagesSent: Int64 = 0
    private var queuedMessages: Int = 0
    private var reconnectAttempts: Int = 0
    
    var protocolName: String {
        protocolDisplayName
    }
    
    func connect(config: ConnectionConfig) async throws {
        guard state != .connected else { return }
        state = .connecting
        
        do {
            // Create connection
            let connection = try await GRPCCore.ClientConnection.insecure(
                target: .host(config.host, port: config.port)
            )
            
            // Create client
            let serializer = GRPCProtobuf.MessageSerializer<Arvos_SensorMessage>()
            let deserializer = GRPCProtobuf.MessageDeserializer<Arvos_ControlMessage>()
            let grpcClient = GRPCCore.GRPCClient(connection: connection)
            let client = Arvos_SensorStream.Client(wrapping: grpcClient)
            
            // Create request stream
            var requestContinuation: GRPCCore.AsyncStream<Arvos_SensorMessage>.Continuation?
            let requestStream = GRPCCore.AsyncStream<Arvos_SensorMessage> { continuation in
                requestContinuation = continuation
            }
            
            guard let continuation = requestContinuation else {
                throw StreamingProtocolError.connectionFailed("Failed to create request stream")
            }
            
            self.requestStream = continuation
            self.client = client
            
            // Start bidirectional streaming
            let responseTask = Task {
                do {
                    try await client.streamSensors(
                        request: .stream(requestStream),
                        serializer: serializer,
                        deserializer: deserializer,
                        options: .defaults
                    ) { response in
                        for try await controlMessage in response {
                            await self.handleControlMessage(controlMessage)
                        }
                    }
                } catch {
                    await MainActor.run {
                        self.state = .error
                        self.delegate?.streamingProtocol(self, didEncounterError: error)
                    }
                }
            }
            
            self.responseTask = responseTask
            
            // Send handshake
            let handshake = createHandshake()
            continuation.yield(handshake)
            
            state = .connected
            print("✅ Connected using gRPC to \(config.host):\(config.port)")
        } catch {
            state = .error
            throw StreamingProtocolError.connectionFailed(error.localizedDescription)
        }
    }
    
    func disconnect() {
        requestStream?.finish()
        requestStream = nil
        responseTask?.cancel()
        responseTask = nil
        client = nil
        state = .disconnected
    }
    
    func send<T: Encodable>(json object: T) throws {
        guard state == .connected else {
            throw StreamingProtocolError.notConnected
        }
        guard let requestStream = requestStream else {
            throw StreamingProtocolError.notConnected
        }
        
        // Convert SensorData to protobuf message
        let message: Arvos_SensorMessage
        do {
            message = try convertToProtobuf(object)
        } catch {
            throw StreamingProtocolError.encodingFailed(error.localizedDescription)
        }
        
        queuedMessages += 1
        requestStream.yield(message)
        messagesSent += 1
        bytesSent += Int64(message.serializedData().count)
        queuedMessages = max(0, queuedMessages - 1)
    }
    
    func send(data: Data) throws {
        guard state == .connected else {
            throw StreamingProtocolError.notConnected
        }
        guard let requestStream = requestStream else {
            throw StreamingProtocolError.notConnected
        }
        
        // For binary data, we need metadata. Try to parse it from the binary message format.
        // If we can't, create a generic message with binary_data field.
        var message = Arvos_SensorMessage()
        message.timestampNs = TimestampManager.shared.now()
        message.binaryData = data
        
        queuedMessages += 1
        requestStream.yield(message)
        messagesSent += 1
        bytesSent += Int64(data.count)
        queuedMessages = max(0, queuedMessages - 1)
    }
    
    func getStatistics() -> StreamingProtocolStatistics {
        return StreamingProtocolStatistics(
            state: state,
            bytesSent: bytesSent,
            messagesSent: messagesSent,
            queuedMessages: queuedMessages,
            reconnectAttempts: reconnectAttempts,
            protocolName: protocolName
        )
    }
    
    func resetStatistics() {
        bytesSent = 0
        messagesSent = 0
        queuedMessages = 0
        reconnectAttempts = 0
    }
    
    static func isAvailable() -> Bool {
        if #available(iOS 18.0, *) {
            return true
        }
        return false
    }
    
    // MARK: - Private Helpers
    
    private func createHandshake() -> Arvos_SensorMessage {
        var message = Arvos_SensorMessage()
        message.timestampNs = TimestampManager.shared.now()
        
        var handshake = Arvos_HandshakeData()
        #if canImport(UIKit)
        handshake.deviceName = UIDevice.current.name
        handshake.deviceModel = UIDevice.current.model
        handshake.osVersion = UIDevice.current.systemVersion
        #else
        handshake.deviceName = "ARVOS Device"
        handshake.deviceModel = "Unknown"
        handshake.osVersion = "Unknown"
        #endif
        handshake.appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        
        var capabilities = Arvos_DeviceCapabilities()
        capabilities.hasLidar_p = true // Assume LiDAR-capable device
        capabilities.hasArkit_p = true
        capabilities.hasGps_p = true
        capabilities.hasImu_p = true
        capabilities.hasWatch_p = false // Will be set if watch is connected
        capabilities.supportedModes = ["Full Sensor", "Mapping", "IMU Only"]
        
        handshake.capabilities = capabilities
        message.data = .handshake(handshake)
        
        return message
    }
    
    private func convertToProtobuf<T: Encodable>(_ object: T) throws -> Arvos_SensorMessage {
        var message = Arvos_SensorMessage()
        
        // Try to decode as SensorData to determine type
        if let sensorData = object as? (any SensorData) {
            message.timestampNs = sensorData.timestampNs
            
            switch sensorData.sensorType {
            case "imu":
                if let imuData = object as? IMUData {
                    var imu = Arvos_IMUData()
                    imu.angularVelocity = convertVector3(imuData.angularVelocity)
                    imu.linearAcceleration = convertVector3(imuData.linearAcceleration)
                    imu.gravity = convertVector3(imuData.gravity)
                    message.data = .imu(imu)
                }
                
            case "gps":
                if let gpsData = object as? GPSData {
                    var gps = Arvos_GPSData()
                    gps.latitude = gpsData.latitude
                    gps.longitude = gpsData.longitude
                    gps.altitude = gpsData.altitude
                    gps.horizontalAccuracy = gpsData.horizontalAccuracy
                    gps.verticalAccuracy = gpsData.verticalAccuracy
                    gps.speed = gpsData.speed
                    gps.course = gpsData.course
                    message.data = .gps(gps)
                }
                
            case "pose":
                if let poseData = object as? PoseData {
                    var pose = Arvos_PoseData()
                    pose.position = convertVector3(poseData.position)
                    pose.orientation = convertQuaternion(poseData.orientation)
                    pose.trackingState = poseData.trackingState
                    message.data = .pose(pose)
                }
                
            default:
                // Unknown sensor type - encode as JSON in status message
                let jsonData = try JSONEncoder().encode(object)
                if let jsonString = String(data: jsonData, encoding: .utf8) {
                    var status = Arvos_StatusData()
                    status.status = "data"
                    status.message = jsonString
                    message.data = .status(status)
                }
            }
        } else {
            // Not a SensorData - encode as JSON in status message
            let jsonData = try JSONEncoder().encode(object)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                var status = Arvos_StatusData()
                status.status = "data"
                status.message = jsonString
                message.timestampNs = TimestampManager.shared.now()
                message.data = .status(status)
            }
        }
        
        return message
    }
    
    private func convertVector3(_ simd: SIMD3<Double>) -> Arvos_Vector3 {
        var vec = Arvos_Vector3()
        vec.x = Float(simd.x)
        vec.y = Float(simd.y)
        vec.z = Float(simd.z)
        return vec
    }
    
    private func convertVector3(_ simd: SIMD3<Float>) -> Arvos_Vector3 {
        var vec = Arvos_Vector3()
        vec.x = simd.x
        vec.y = simd.y
        vec.z = simd.z
        return vec
    }
    
    private func convertQuaternion(_ simd: SIMD4<Float>) -> Arvos_Quaternion {
        var quat = Arvos_Quaternion()
        quat.x = simd.x
        quat.y = simd.y
        quat.z = simd.z
        quat.w = simd.w
        return quat
    }
    
    @MainActor
    private func handleControlMessage(_ control: Arvos_ControlMessage) {
        switch control.command {
        case .startRecording(let cmd):
            delegate?.streamingProtocol(self, didReceiveMessage: "Start recording: \(cmd.sessionID)")
        case .stopRecording(let cmd):
            delegate?.streamingProtocol(self, didReceiveMessage: "Stop recording: \(cmd.sessionID)")
        case .changeMode(let cmd):
            delegate?.streamingProtocol(self, didReceiveMessage: "Change mode: \(cmd.mode)")
        case .ack(let cmd):
            delegate?.streamingProtocol(self, didReceiveMessage: "Ack: \(cmd.messageID) - \(cmd.success)")
        case .none:
            break
        }
    }
}

// Fallback for iOS < 18
@available(iOS, introduced: 16.0, obsoleted: 18.0)
final class GRPCAdapterFallback: NSObject, StreamingProtocol {
    weak var delegate: StreamingProtocolDelegate?
    private(set) var state: ConnectionState = .disconnected
    var protocolName: String { "gRPC" }
    
    func connect(config: ConnectionConfig) async throws {
        throw StreamingProtocolError.protocolNotSupported
    }
    
    func disconnect() {}
    func send<T: Encodable>(json object: T) throws {
        throw StreamingProtocolError.protocolNotSupported
    }
    func send(data: Data) throws {
        throw StreamingProtocolError.protocolNotSupported
    }
    func getStatistics() -> StreamingProtocolStatistics {
        return StreamingProtocolStatistics(
            state: .error,
            bytesSent: 0,
            messagesSent: 0,
            queuedMessages: 0,
            reconnectAttempts: 0,
            protocolName: protocolName
        )
    }
    func resetStatistics() {}
    static func isAvailable() -> Bool { false }
}
#endif

