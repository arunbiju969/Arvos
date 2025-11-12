//
//  StreamingProtocol.swift
//  arvos
//
//  Protocol abstraction layer for multiple streaming methods
//

import Foundation
import Combine

// MARK: - Connection Configuration

struct ConnectionConfig {
    var host: String
    var port: Int
    var useTLS: Bool = false
    var additionalParams: [String: Any] = [:]
    
    init(host: String, port: Int, useTLS: Bool = false, additionalParams: [String: Any] = [:]) {
        self.host = host
        self.port = port
        self.useTLS = useTLS
        self.additionalParams = additionalParams
    }
    
    // Convenience initializers for specific protocols
    static func websocket(host: String, port: Int = 9090) -> ConnectionConfig {
        return ConnectionConfig(host: host, port: port)
    }
    
    static func grpc(host: String, port: Int = 50051, useTLS: Bool = false) -> ConnectionConfig {
        return ConnectionConfig(host: host, port: port, useTLS: useTLS)
    }
    
    static func mqtt(host: String, port: Int = 1883, brokerURL: String? = nil) -> ConnectionConfig {
        var params: [String: Any] = [:]
        if let broker = brokerURL {
            params["brokerURL"] = broker
        }
        return ConnectionConfig(host: host, port: port, additionalParams: params)
    }
    
    static func http(host: String, port: Int = 8080, useTLS: Bool = false) -> ConnectionConfig {
        return ConnectionConfig(host: host, port: port, useTLS: useTLS)
    }
    
    static func quic(host: String, port: Int = 4433, useTLS: Bool = true) -> ConnectionConfig {
        return ConnectionConfig(host: host, port: port, useTLS: useTLS)
    }
}

// MARK: - Streaming Protocol Statistics

struct StreamingProtocolStatistics {
    let state: ConnectionState
    let bytesSent: Int64
    let messagesSent: Int64
    let queuedMessages: Int
    let reconnectAttempts: Int
    let protocolName: String
    
    init(state: ConnectionState,
         bytesSent: Int64,
         messagesSent: Int64,
         queuedMessages: Int,
         reconnectAttempts: Int,
         protocolName: String) {
        self.state = state
        self.bytesSent = bytesSent
        self.messagesSent = messagesSent
        self.queuedMessages = queuedMessages
        self.reconnectAttempts = reconnectAttempts
        self.protocolName = protocolName
    }
    
    init(networkStats: NetworkStatistics, protocolName: String) {
        self.init(state: networkStats.state,
                  bytesSent: networkStats.bytesSent,
                  messagesSent: networkStats.messagesSent,
                  queuedMessages: networkStats.queuedMessages,
                  reconnectAttempts: networkStats.reconnectAttempts,
                  protocolName: protocolName)
    }
    
    var bandwidth: String {
        if bytesSent < 1024 {
            return "\(bytesSent) B"
        } else if bytesSent < 1024 * 1024 {
            return String(format: "%.1f KB", Double(bytesSent) / 1024.0)
        } else {
            return String(format: "%.1f MB", Double(bytesSent) / (1024.0 * 1024.0))
        }
    }
}

// MARK: - Streaming Protocol Delegate

protocol StreamingProtocolDelegate: AnyObject {
    func streamingProtocol(_ protocol: StreamingProtocol, didChangeState state: ConnectionState)
    func streamingProtocol(_ protocol: StreamingProtocol, didReceiveMessage message: String)
    func streamingProtocol(_ protocol: StreamingProtocol, didEncounterError error: Error)
}

// MARK: - Streaming Protocol

protocol StreamingProtocol: AnyObject {
    /// Delegate for handling protocol events
    var delegate: StreamingProtocolDelegate? { get set }
    
    /// Current connection state
    var state: ConnectionState { get }
    
    /// Protocol name (for display/logging)
    var protocolName: String { get }
    
    /// Connect to remote endpoint
    func connect(config: ConnectionConfig) async throws
    
    /// Disconnect from remote endpoint
    func disconnect()
    
    /// Send JSON-encoded message
    func send<T: Encodable>(json object: T) throws
    
    /// Send raw binary data
    func send(data: Data) throws
    
    /// Get current statistics
    func getStatistics() -> StreamingProtocolStatistics
    
    /// Reset statistics counters
    func resetStatistics()
    
    /// Check if protocol is available on this device
    static func isAvailable() -> Bool
}

// MARK: - Default Implementations

extension StreamingProtocol {
    static func isAvailable() -> Bool {
        return true // Most protocols available by default
    }
}

// MARK: - Protocol Errors

enum StreamingProtocolError: LocalizedError {
    case notConnected
    case connectionFailed(String)
    case sendFailed(String)
    case encodingFailed(String)
    case protocolNotSupported
    case invalidConfiguration(String)
    
    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "Not connected to server"
        case .connectionFailed(let reason):
            return "Connection failed: \(reason)"
        case .sendFailed(let reason):
            return "Failed to send message: \(reason)"
        case .encodingFailed(let reason):
            return "Failed to encode message: \(reason)"
        case .protocolNotSupported:
            return "Protocol not supported on this device"
        case .invalidConfiguration(let reason):
            return "Invalid configuration: \(reason)"
        }
    }
}

