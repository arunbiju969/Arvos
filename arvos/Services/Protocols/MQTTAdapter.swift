//
//  MQTTAdapter.swift
//  arvos
//
//  Minimal MQTT 3.1.1 publisher implemented with Network.framework.
//

import Foundation
import Network

final class MQTTAdapter: NSObject, StreamingProtocol {
    weak var delegate: StreamingProtocolDelegate?
    
    private(set) var state: ConnectionState = .disconnected {
        didSet {
            if oldValue != state {
                delegate?.streamingProtocol(self, didChangeState: state)
            }
        }
    }
    
    private let protocolDisplayName = "MQTT"
    private var connection: NWConnection?
    private var host: NWEndpoint.Host?
    private var port: NWEndpoint.Port = 1883
    private var topicTelemetry: String = "arvos/telemetry"
    private var topicBinary: String = "arvos/binary"
    private var clientId: String = "arvos-ios-\(UUID().uuidString.prefix(8))"
    
    private var bytesSent: Int64 = 0
    private var messagesSent: Int64 = 0
    private var queuedMessages: Int = 0
    private var reconnectAttempts: Int = 0
    
    var protocolName: String { protocolDisplayName }
    
    func connect(config: ConnectionConfig) async throws {
        guard state != .connected else { return }
        state = .connecting
        
        guard let endpointPort = NWEndpoint.Port(rawValue: UInt16(config.port)) else {
            throw StreamingProtocolError.invalidConfiguration("Invalid MQTT port \(config.port)")
        }
        
        host = NWEndpoint.Host(config.host)
        port = endpointPort
        if let telemetry = config.additionalParams["topicTelemetry"] as? String {
            topicTelemetry = telemetry
        }
        if let binary = config.additionalParams["topicBinary"] as? String {
            topicBinary = binary
        }
        if let client = config.additionalParams["clientId"] as? String {
            clientId = client
        }
        
        let connection = NWConnection(host: host!, port: port, using: .tcp)
        self.connection = connection
        
        return try await withCheckedThrowingContinuation { continuation in
            connection.stateUpdateHandler = { [weak self] newState in
                guard let self else { return }
                switch newState {
                case .ready:
                    self.sendConnectPacket { result in
                        switch result {
                        case .success:
                            self.state = .connected
                            continuation.resume()
                        case .failure(let error):
                            continuation.resume(throwing: StreamingProtocolError.connectionFailed(error.localizedDescription))
                        }
                    }
                case .failed(let error):
                    self.state = .error
                    continuation.resume(throwing: StreamingProtocolError.connectionFailed(error.localizedDescription))
                case .cancelled:
                    if self.state != .disconnected {
                        self.state = .disconnected
                    }
                default:
                    break
                }
            }
            
            connection.start(queue: .global(qos: .utility))
        }
    }
    
    func disconnect() {
        guard let connection = connection else { return }
        connection.send(content: Data([0xE0, 0x00]), completion: .contentProcessed { _ in })
        connection.cancel()
        self.connection = nil
        state = .disconnected
    }
    
    func send<T: Encodable>(json object: T) throws {
        guard state == .connected, let connection = connection else {
            throw StreamingProtocolError.notConnected
        }
        
        let payload: Data
        do {
            payload = try JSONEncoder().encode(object)
        } catch {
            throw StreamingProtocolError.encodingFailed(error.localizedDescription)
        }
        
        let packet = buildPublishPacket(topic: topicTelemetry, payload: payload)
        queuedMessages += 1
        connection.send(content: packet, completion: .contentProcessed { [weak self] error in
            guard let self else { return }
            self.queuedMessages = max(0, self.queuedMessages - 1)
            if let error {
                self.state = .error
                self.delegate?.streamingProtocol(self, didEncounterError: error)
                return
            }
            self.messagesSent += 1
            self.bytesSent += Int64(packet.count)
        })
    }
    
    func send(data: Data) throws {
        guard state == .connected, let connection = connection else {
            throw StreamingProtocolError.notConnected
        }
        
        let packet = buildPublishPacket(topic: topicBinary, payload: data)
        queuedMessages += 1
        connection.send(content: packet, completion: .contentProcessed { [weak self] error in
            guard let self else { return }
            self.queuedMessages = max(0, self.queuedMessages - 1)
            if let error {
                self.state = .error
                self.delegate?.streamingProtocol(self, didEncounterError: error)
                return
            }
            self.messagesSent += 1
            self.bytesSent += Int64(packet.count)
        })
    }
    
    func getStatistics() -> StreamingProtocolStatistics {
        StreamingProtocolStatistics(
            state: state,
            bytesSent: bytesSent,
            messagesSent: messagesSent,
            queuedMessages: queuedMessages,
            reconnectAttempts: reconnectAttempts,
            protocolName: protocolDisplayName
        )
    }
    
    func resetStatistics() {
        bytesSent = 0
        messagesSent = 0
        queuedMessages = 0
        reconnectAttempts = 0
    }
    
    static func isAvailable() -> Bool {
        true
    }
    
    // MARK: - MQTT Packet Builders
    
    private func sendConnectPacket(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let connection = connection else {
            completion(.failure(StreamingProtocolError.connectionFailed("No connection")))
            return
        }
        
        let payload = encodeConnectPayload()
        let header = encodeFixedHeader(type: 0x10, remainingLength: payload.count)
        let packet = header + payload
        
        connection.send(content: Data(packet), completion: .contentProcessed { [weak self] error in
            if let error {
                completion(.failure(error))
                return
            }
            self?.waitForConnAck(completion: completion)
        })
    }
    
    private func waitForConnAck(completion: @escaping (Result<Void, Error>) -> Void) {
        connection?.receive(minimumIncompleteLength: 4, maximumLength: 4) { _, _, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            completion(.success(()))
        }
    }
    
    private func encodeConnectPayload() -> [UInt8] {
        var bytes: [UInt8] = []
        
        func appendString(_ value: String) {
            let data = Data(value.utf8)
            bytes.append(UInt8((data.count >> 8) & 0xFF))
            bytes.append(UInt8(data.count & 0xFF))
            bytes.append(contentsOf: data)
        }
        
        // Variable header
        appendString("MQTT")
        bytes.append(0x04) // Protocol level 4 (3.1.1)
        bytes.append(0x02) // Clean session
        bytes.append(0x00) // Keep alive MSB
        bytes.append(0x3C) // Keep alive LSB (60s)
        
        // Payload
        appendString(clientId)
        
        return bytes
    }
    
    private func buildPublishPacket(topic: String, payload: Data) -> Data {
        var bytes: [UInt8] = []
        var variableHeader: [UInt8] = []
        
        let topicData = Data(topic.utf8)
        variableHeader.append(UInt8((topicData.count >> 8) & 0xFF))
        variableHeader.append(UInt8(topicData.count & 0xFF))
        variableHeader.append(contentsOf: topicData)
        
        let remainingLength = variableHeader.count + payload.count
        bytes.append(contentsOf: encodeFixedHeader(type: 0x30, remainingLength: remainingLength))
        bytes.append(contentsOf: variableHeader)
        bytes.append(contentsOf: payload)
        
        return Data(bytes)
    }
    
    private func encodeFixedHeader(type: UInt8, remainingLength: Int) -> [UInt8] {
        var header: [UInt8] = [type]
        var length = remainingLength
        repeat {
            var encodedByte = UInt8(length % 128)
            length /= 128
            if length > 0 {
                encodedByte |= 0x80
            }
            header.append(encodedByte)
        } while length > 0
        return header
    }
}


