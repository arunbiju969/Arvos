//
//  WebSocketAdapter.swift
//  arvos
//
//  Adapter that bridges the legacy WebSocketService into the
//  new StreamingProtocol abstraction so the connection pipeline
//  works for both existing and future transports.
//

import Foundation

final class WebSocketAdapter: StreamingProtocol {
    weak var delegate: StreamingProtocolDelegate?

    private let service: WebSocketService
    private let protocolDisplayName = "WebSocket"

    init(service: WebSocketService) {
        self.service = service
    }

    var state: ConnectionState {
        return service.state
    }

    var protocolName: String {
        return protocolDisplayName
    }

    func connect(config: ConnectionConfig) async throws {
        guard let url = makeURL(from: config) else {
            throw StreamingProtocolError.invalidConfiguration("Invalid host/port: \(config.host):\(config.port)")
        }

        await MainActor.run {
            service.connect(to: url)
            service.startHeartbeat()
        }
    }

    func disconnect() {
        service.disconnect()
    }

    func send<T: Encodable>(json object: T) throws {
        do {
            try service.send(json: object)
        } catch {
            throw StreamingProtocolError.sendFailed(error.localizedDescription)
        }
    }

    func send(data: Data) throws {
        service.send(data: data, asText: false)
    }

    func getStatistics() -> StreamingProtocolStatistics {
        let stats = service.getStatistics()
        return StreamingProtocolStatistics(networkStats: stats, protocolName: protocolDisplayName)
    }

    func resetStatistics() {
        service.resetStatistics()
    }

    static func isAvailable() -> Bool {
        return true
    }

    // MARK: - Helpers

    private func makeURL(from config: ConnectionConfig) -> URL? {
        var components = URLComponents()
        components.scheme = config.useTLS ? "wss" : "ws"
        components.host = config.host
        components.port = config.port

        return components.url
    }
}


