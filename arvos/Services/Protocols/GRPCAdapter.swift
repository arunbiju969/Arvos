//
//  GRPCAdapter.swift
//  arvos
//
//  gRPC adapter for streaming sensor data (iOS 18+)
//

import Foundation

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
    
    private var bytesSent: Int64 = 0
    private var messagesSent: Int64 = 0
    private var queuedMessages: Int = 0
    private var reconnectAttempts: Int = 0
    
    var protocolName: String { "gRPC" }
    
    override init() {
        super.init()
    }
    
    func connect(config: ConnectionConfig) async throws {
        state = .connecting
        
        // TODO: Implement gRPC connection using grpc-swift
        // For now, just mark as error
        state = .error
        throw StreamingProtocolError.protocolNotSupported
    }
    
    func disconnect() {
        state = .disconnected
    }
    
    func send<T: Encodable>(json object: T) throws {
        guard state == .connected else {
            throw StreamingProtocolError.notConnected
        }
        // TODO: Implement gRPC send
    }
    
    func send(data: Data) throws {
        guard state == .connected else {
            throw StreamingProtocolError.notConnected
        }
        // TODO: Implement gRPC send
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
        } else {
            return false
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
    func send<T: Encodable>(json object: T) throws { throw StreamingProtocolError.protocolNotSupported }
    func send(data: Data) throws { throw StreamingProtocolError.protocolNotSupported }
    func getStatistics() -> StreamingProtocolStatistics {
        StreamingProtocolStatistics(state: .error, bytesSent: 0, messagesSent: 0, queuedMessages: 0, reconnectAttempts: 0, protocolName: protocolName)
    }
    func resetStatistics() {}
    static func isAvailable() -> Bool { return false }
}

