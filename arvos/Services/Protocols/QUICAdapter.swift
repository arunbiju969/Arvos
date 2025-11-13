//
//  QUICAdapter.swift
//  arvos
//
//  QUIC/HTTP3 adapter for streaming sensor data (iOS 15+)
//

import Foundation

@available(iOS 15.0, *)
final class QUICAdapter: NSObject, StreamingProtocol {
    weak var delegate: StreamingProtocolDelegate?
    
    private(set) var state: ConnectionState = .disconnected {
        didSet {
            if oldValue != state {
                delegate?.streamingProtocol(self, didChangeState: state)
            }
        }
    }
    
    private var urlSession: URLSession?
    private var baseURL: URL?
    
    private var bytesSent: Int64 = 0
    private var messagesSent: Int64 = 0
    private var queuedMessages: Int = 0
    private var reconnectAttempts: Int = 0
    
    var protocolName: String { "QUIC/HTTP3" }
    
    override init() {
        super.init()
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 10.0
        // Enable HTTP/3
        if #available(iOS 15.0, *) {
            urlSession = URLSession(configuration: configuration)
        }
    }
    
    func connect(config: ConnectionConfig) async throws {
        guard let url = URL(string: config.useTLS ? "https://\(config.host):\(config.port)" : "http://\(config.host):\(config.port)") else {
            throw StreamingProtocolError.connectionFailed("Invalid URL")
        }
        
        state = .connecting
        baseURL = url
        
        // Test connection
        do {
            let healthURL = url.appendingPathComponent("/api/health")
            let (_, response) = try await urlSession!.data(from: healthURL)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                state = .connected
            } else {
                state = .error
                throw StreamingProtocolError.connectionFailed("Health check failed")
            }
        } catch {
            state = .error
            throw StreamingProtocolError.connectionFailed(error.localizedDescription)
        }
    }
    
    func disconnect() {
        state = .disconnected
        baseURL = nil
    }
    
    func send<T: Encodable>(json object: T) throws {
        guard state == .connected, let baseURL = baseURL else {
            throw StreamingProtocolError.notConnected
        }
        
        let data = try JSONEncoder().encode(object)
        let url = baseURL.appendingPathComponent("/api/telemetry")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = data
        
        queuedMessages += 1
        
        Task {
            do {
                let (_, response) = try await urlSession!.data(for: request)
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    self.bytesSent += Int64(data.count)
                    self.messagesSent += 1
                }
                self.queuedMessages = max(0, self.queuedMessages - 1)
            } catch {
                self.queuedMessages = max(0, self.queuedMessages - 1)
                self.delegate?.streamingProtocol(self, didEncounterError: error)
            }
        }
    }
    
    func send(data: Data) throws {
        guard state == .connected, let baseURL = baseURL else {
            throw StreamingProtocolError.notConnected
        }
        
        let url = baseURL.appendingPathComponent("/api/binary")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        request.httpBody = data
        
        queuedMessages += 1
        
        Task {
            do {
                let (_, response) = try await urlSession!.data(for: request)
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    self.bytesSent += Int64(data.count)
                    self.messagesSent += 1
                }
                self.queuedMessages = max(0, self.queuedMessages - 1)
            } catch {
                self.queuedMessages = max(0, self.queuedMessages - 1)
                self.delegate?.streamingProtocol(self, didEncounterError: error)
            }
        }
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
        if #available(iOS 15.0, *) {
            return true
        } else {
            return false
        }
    }
}

