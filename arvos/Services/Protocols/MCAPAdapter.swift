//
//  MCAPAdapter.swift
//  arvos
//
//  Streams telemetry to a remote MCAP writer over TCP.
//

import Foundation
import Network

final class MCAPAdapter: NSObject, StreamingProtocol {
    weak var delegate: StreamingProtocolDelegate?

    private(set) var state: ConnectionState = .disconnected {
        didSet {
            if oldValue != state {
                delegate?.streamingProtocol(self, didChangeState: state)
            }
        }
    }

    private let protocolDisplayName = "MCAP Stream"
    private let queue = DispatchQueue(label: "com.arvos.mcap-adapter")

    private var connection: NWConnection?
    private var pendingHandshakeContinuation: CheckedContinuation<Void, Error>?

    private var bytesSent: Int64 = 0
    private var messagesSent: Int64 = 0
    private var queuedMessages: Int = 0
    private var reconnectAttempts: Int = 0

    private let encoder = JSONEncoder()

    var protocolName: String { protocolDisplayName }

    // MARK: - Connection

    func connect(config: ConnectionConfig) async throws {
        guard state != .connected else { return }

        guard let port = NWEndpoint.Port(rawValue: UInt16(config.port)) else {
            throw StreamingProtocolError.invalidConfiguration("Invalid port \(config.port)")
        }

        let host = NWEndpoint.Host(config.host)

        return try await withCheckedThrowingContinuation { continuation in
            queue.async { [weak self] in
                guard let self else { return }

                self.state = .connecting
                let connection = NWConnection(host: host, port: port, using: .tcp)
                self.connection = connection

                connection.stateUpdateHandler = { [weak self] newState in
                    guard let self else { return }
                    switch newState {
                    case .ready:
                        self.state = .connected
                        continuation.resume()
                        self.sendHandshake()
                    case .failed(let error):
                        self.state = .error
                        continuation.resume(throwing: error)
                    case .cancelled:
                        if self.state != .disconnected {
                            self.state = .disconnected
                        }
                    case .waiting(let error):
                        self.reconnectAttempts += 1
                        self.delegate?.streamingProtocol(self, didEncounterError: error)
                    default:
                        break
                    }
                }

                connection.start(queue: self.queue)
            }
        }
    }

    func disconnect() {
        queue.async { [weak self] in
            guard let self else { return }
            self.connection?.cancel()
            self.connection = nil
            self.state = .disconnected
        }
    }

    // MARK: - Sending

    func send<T: Encodable>(json object: T) throws {
        guard state == .connected else {
            throw StreamingProtocolError.notConnected
        }

        let payload = try encoder.encode(object)
        guard let jsonObject = try JSONSerialization.jsonObject(with: payload) as? [String: Any] else {
            throw StreamingProtocolError.encodingFailed("Unable to encode payload for MCAP")
        }

        let envelope = makeEnvelope(from: jsonObject)
        let envelopeData = try JSONSerialization.data(withJSONObject: envelope)
        sendFrame(envelopeData)
    }

    func send(data: Data) throws {
        guard state == .connected else {
            throw StreamingProtocolError.notConnected
        }

        let timestamp = TimestampManager.shared.now()
        let envelope: [String: Any] = [
            "topic": "/binary",
            "timestampNs": timestamp,
            "payloadEncoding": "base64",
            "payload": data.base64EncodedString()
        ]

        let envelopeData = try JSONSerialization.data(withJSONObject: envelope)
        sendFrame(envelopeData)
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

    private func sendHandshake() {
        let handshake = HandshakeMessage(timestamp: TimestampManager.shared.now())
        do {
            try send(json: handshake)
        } catch {
            delegate?.streamingProtocol(self, didEncounterError: error)
        }
    }

    private func makeEnvelope(from json: [String: Any]) -> [String: Any] {
        var topic = "/misc"

        if let sensorType = json["sensorType"] as? String {
            topic = "/sensor/\(sensorType)"
        } else if let type = json["type"] as? String {
            topic = "/control/\(type)"
        }

        let timestampNs: UInt64
        if let value = json["timestampNs"] as? NSNumber {
            timestampNs = value.uint64Value
        } else {
            timestampNs = TimestampManager.shared.now()
        }

        return [
            "topic": topic,
            "timestampNs": timestampNs,
            "payloadEncoding": "json",
            "payload": json
        ]
    }

    private func sendFrame(_ data: Data) {
        queue.async { [weak self] in
            guard let self, let connection = self.connection else { return }

            var length = UInt32(data.count).littleEndian
            var frame = Data(bytes: &length, count: MemoryLayout<UInt32>.size)
            frame.append(data)

            self.queuedMessages += 1
            connection.send(content: frame, completion: .contentProcessed { [weak self] error in
                guard let self else { return }
                self.queuedMessages = max(0, self.queuedMessages - 1)

                if let error = error {
                    self.delegate?.streamingProtocol(self, didEncounterError: error)
                    return
                }

                self.bytesSent += Int64(frame.count)
                self.messagesSent += 1
            })
        }
    }
}


