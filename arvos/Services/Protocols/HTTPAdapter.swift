//
//  HTTPAdapter.swift
//  arvos
//
//  Implements the StreamingProtocol over simple HTTP POST requests.
//

import Foundation

final class HTTPAdapter: NSObject, StreamingProtocol {
    weak var delegate: StreamingProtocolDelegate?
    
    private(set) var state: ConnectionState = .disconnected {
        didSet {
            if oldValue != state {
                delegate?.streamingProtocol(self, didChangeState: state)
            }
        }
    }
    
    private let protocolDisplayName = "HTTP"
    private var session: URLSession?
    private var baseURL: URL?
    
    private var bytesSent: Int64 = 0
    private var messagesSent: Int64 = 0
    private var queuedMessages: Int = 0
    private var reconnectAttempts: Int = 0
    
    private let workQueue = DispatchQueue(label: "com.arvos.http-adapter")
    
    var protocolName: String {
        protocolDisplayName
    }
    
    func connect(config: ConnectionConfig) async throws {
        guard let baseURL = makeBaseURL(from: config) else {
            throw StreamingProtocolError.invalidConfiguration("Invalid HTTP base URL for \(config.host):\(config.port)")
        }
        
        self.baseURL = baseURL
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 10
        configuration.httpAdditionalHeaders = ["User-Agent": "arvos-ios-http-adapter"]
        session = URLSession(configuration: configuration)
        
        // Perform a quick health check – if it fails we still attempt to operate but surface the error.
        state = .connecting
        do {
            try await performHealthCheck()
            state = .connected
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
            throw StreamingProtocolError.connectionFailed("HTTP session not initialized")
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
        
        enqueue(request: request, bodySize: body.count, via: session)
    }
    
    func send(data: Data) throws {
        guard state == .connected else {
            throw StreamingProtocolError.notConnected
        }
        guard let session = session, let baseURL = baseURL else {
            throw StreamingProtocolError.connectionFailed("HTTP session not initialized")
        }
        
        var request = URLRequest(url: baseURL.appendingPathComponent("binary"))
        request.httpMethod = "POST"
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        request.httpBody = data
        
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
        true
    }
    
    // MARK: - Helpers
    
    private func makeBaseURL(from config: ConnectionConfig) -> URL? {
        var components = URLComponents()
        components.scheme = config.useTLS ? "https" : "http"
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
                        self.delegate?.streamingProtocol(self, didEncounterError: error)
                        return
                    }
                    
                    if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                        let err = StreamingProtocolError.sendFailed("HTTP \(httpResponse.statusCode)")
                        self.delegate?.streamingProtocol(self, didEncounterError: err)
                        return
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


