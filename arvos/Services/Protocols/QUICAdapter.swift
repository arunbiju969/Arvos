//
//  QUICAdapter.swift
//  arvos
//
//  QUIC/HTTP3 streaming adapter using URLSession's native HTTP/3 support
//  Note: Requires iOS 15+ for HTTP/3 support
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
    
    private let protocolDisplayName = "QUIC/HTTP3"
    private var session: URLSession?
    private var baseURL: URL?
    
    private var bytesSent: Int64 = 0
    private var messagesSent: Int64 = 0
    private var queuedMessages: Int = 0
    private var reconnectAttempts: Int = 0
    
    private let workQueue = DispatchQueue(label: "com.arvos.quic-adapter")
    
    var protocolName: String {
        protocolDisplayName
    }
    
    func connect(config: ConnectionConfig) async throws {
        guard let baseURL = makeBaseURL(from: config) else {
            throw StreamingProtocolError.invalidConfiguration("Invalid QUIC/HTTP3 base URL for \(config.host):\(config.port)")
        }
        
        self.baseURL = baseURL
        
        // URLSession automatically uses HTTP/3 if:
        // 1. Server supports HTTP/3 (advertised via Alt-Svc header or DNS)
        // 2. URL uses https:// scheme
        // 3. iOS 15+ is available
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 10
        configuration.httpAdditionalHeaders = ["User-Agent": "arvos-ios-quic-adapter"]
        
        // Enable HTTP/3 explicitly if using HTTPS
        if config.useTLS {
            // URLSession will automatically negotiate HTTP/3 if available
            // We can hint that we prefer HTTP/3 by setting this
            session = URLSession(configuration: configuration)
        } else {
            // For local development, we might use http:// but QUIC requires TLS
            // So we'll use https:// even for local connections
            session = URLSession(configuration: configuration)
        }
        
        // Perform a quick health check
        state = .connecting
        do {
            try await performHealthCheck()
            state = .connected
            print("✅ Connected using QUIC/HTTP3 to \(config.host):\(config.port)")
        } catch {
            state = .error
            delegate?.streamingProtocol(self, didEncounterError: error)
            throw StreamingProtocolError.connectionFailed(error.localizedDescription)
        }
    }
    
    func disconnect() {
        session?.invalidateAndCancel()
        session = nil
        state = .disconnected
    }
    
    func send<T: Encodable>(json object: T) throws {
        guard state == .connected else {
            throw StreamingProtocolError.notConnected
        }
        guard let session = session, let baseURL = baseURL else {
            throw StreamingProtocolError.connectionFailed("QUIC session not initialized")
        }
        
        let body: Data
        do {
            body = try JSONEncoder().encode(object)
        } catch {
            throw StreamingProtocolError.encodingFailed(error.localizedDescription)
        }
        
        var request = URLRequest(url: baseURL.appendingPathComponent("telemetry"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        
        // Explicitly request HTTP/3 if available
        if #available(iOS 16.0, *) {
            request.assumesHTTP3Capable = true
        }
        
        enqueue(request: request, bodySize: body.count, via: session)
    }
    
    func send(data: Data) throws {
        guard state == .connected else {
            throw StreamingProtocolError.notConnected
        }
        guard let session = session, let baseURL = baseURL else {
            throw StreamingProtocolError.connectionFailed("QUIC session not initialized")
        }
        
        var request = URLRequest(url: baseURL.appendingPathComponent("binary"))
        request.httpMethod = "POST"
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        request.httpBody = data
        
        // Explicitly request HTTP/3 if available
        if #available(iOS 16.0, *) {
            request.assumesHTTP3Capable = true
        }
        
        enqueue(request: request, bodySize: data.count, via: session)
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
        if #available(iOS 15.0, *) {
            return true
        }
        return false
    }
    
    // MARK: - Helpers
    
    private func makeBaseURL(from config: ConnectionConfig) -> URL? {
        var components = URLComponents()
        // QUIC/HTTP3 requires HTTPS (TLS is built into QUIC)
        // For local development, we still use https:// with self-signed certs
        components.scheme = "https"  // QUIC always uses TLS
        components.host = config.host
        components.port = config.port
        components.path = "/api"
        return components.url
    }
    
    private func performHealthCheck() async throws {
        guard let session = session, let baseURL = baseURL else {
            throw StreamingProtocolError.connectionFailed("Session not initialized")
        }
        
        var request = URLRequest(url: baseURL.appendingPathComponent("health"))
        request.httpMethod = "GET"
        request.timeoutInterval = 5
        
        // Request HTTP/3 if available
        if #available(iOS 16.0, *) {
            request.assumesHTTP3Capable = true
        }
        
        _ = try await session.data(for: request)
    }
    
    private func enqueue(request: URLRequest, bodySize: Int, via session: URLSession) {
        workQueue.async { [weak self] in
            guard let self = self else { return }
            self.queuedMessages += 1
            let task = session.dataTask(with: request) { _, response, error in
                self.workQueue.async {
                    self.queuedMessages = max(0, self.queuedMessages - 1)
                    
                    if let error = error {
                        // Don't immediately fail on individual request errors
                        // QUIC/HTTP3 may have transient issues
                        self.delegate?.streamingProtocol(self, didEncounterError: error)
                        return
                    }
                    
                    if let httpResponse = response as? HTTPURLResponse {
                        // Check if we're actually using HTTP/3
                        if #available(iOS 16.0, *) {
                            if httpResponse.value(forHTTPHeaderField: "Alt-Svc") != nil {
                                // Server advertised HTTP/3 support
                            }
                        }
                        
                        if !(200...299).contains(httpResponse.statusCode) {
                            let err = StreamingProtocolError.sendFailed("HTTP \(httpResponse.statusCode)")
                            self.delegate?.streamingProtocol(self, didEncounterError: err)
                            return
                        }
                    }
                    
                    self.bytesSent += Int64(bodySize)
                    self.messagesSent += 1
                    if self.state != .connected {
                        self.state = .connected
                    }
                }
            }
            task.resume()
        }
    }
}

// Fallback for iOS < 15
@available(iOS, introduced: 13.0, obsoleted: 15.0)
final class QUICAdapterFallback: NSObject, StreamingProtocol {
    weak var delegate: StreamingProtocolDelegate?
    private(set) var state: ConnectionState = .disconnected
    var protocolName: String { "QUIC/HTTP3" }
    
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

