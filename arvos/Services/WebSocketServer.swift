//
//  WebSocketServer.swift
//  arvos
//
//  Embedded WebSocket server running on iPhone (Foxglove-style architecture)
//

import Foundation
import Network

/// WebSocket server that runs ON the iPhone, allowing Studio to connect as a client
/// This follows Foxglove Studio's architecture where the data source is the server
class WebSocketServer: NSObject {
    private var listener: NWListener?
    private var connections: Set<WebSocketConnection> = []
    private let port: UInt16
    private let queue = DispatchQueue(label: "com.arvos.websocket.server")

    weak var delegate: WebSocketServiceDelegate?
    private(set) var isRunning = false

    init(port: UInt16 = 8765) {
        self.port = port
        super.init()
    }

    func start() throws {
        guard !isRunning else { return }

        let parameters = NWParameters.tcp
        parameters.allowLocalEndpointReuse = true

        // CRITICAL: Accept connections on all interfaces (WiFi, Cellular, Hotspot)
        // By default NWListener only listens on localhost - we need external connections!
        parameters.acceptLocalOnly = false
        parameters.requiredInterfaceType = nil  // Allow all interface types

        // Enable WebSocket upgrade
        let wsOptions = NWProtocolWebSocket.Options()
        parameters.defaultProtocolStack.applicationProtocols.insert(wsOptions, at: 0)

        do {
            listener = try NWListener(using: parameters, on: NWEndpoint.Port(integerLiteral: port))
        } catch {
            throw WebSocketServerError.failedToStart(error.localizedDescription)
        }

        listener?.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                print("📡 WebSocket server started on port \(self?.port ?? 0)")
                self?.isRunning = true
                self?.printConnectionInfo()
            case .failed(let error):
                print("❌ Server failed: \(error)")
                self?.isRunning = false
            case .cancelled:
                print("🛑 Server cancelled")
                self?.isRunning = false
            default:
                break
            }
        }

        listener?.newConnectionHandler = { [weak self] connection in
            self?.handleNewConnection(connection)
        }

        listener?.start(queue: queue)
    }

    func stop() {
        listener?.cancel()
        connections.forEach { $0.connection.cancel() }
        connections.removeAll()
        isRunning = false
    }

    func broadcast(data: Data) {
        connections.forEach { conn in
            conn.send(data: data)
        }
    }

    func broadcast<T: Encodable>(json: T) throws {
        let data = try JSONEncoder().encode(json)
        broadcast(data: data)
    }

    private func handleNewConnection(_ nwConnection: NWConnection) {
        print("✅ New client connected")

        let conn = WebSocketConnection(connection: nwConnection)
        connections.insert(conn)

        conn.onDisconnect = { [weak self] in
            self?.connections.remove(conn)
            print("👋 Client disconnected (\(self?.connections.count ?? 0) remaining)")
        }

        conn.start()
        // Note: WebSocketServer doesn't use delegate - it broadcasts to all connections
    }

    private func printConnectionInfo() {
        let ips = getLocalIPAddresses()
        print("\n🌐 Connect Studio to:")
        for ip in ips {
            print("   ws://\(ip):\(port)")
        }
        print("")
    }

    func getLocalIPAddresses() -> [String] {
        var addresses: [String] = []
        var ifaddr: UnsafeMutablePointer<ifaddrs>?

        guard getifaddrs(&ifaddr) == 0 else { return [] }
        defer { freeifaddrs(ifaddr) }

        var ptr = ifaddr
        while ptr != nil {
            defer { ptr = ptr?.pointee.ifa_next }

            guard let interface = ptr?.pointee else { continue }
            let addrFamily = interface.ifa_addr.pointee.sa_family

            if addrFamily == UInt8(AF_INET) {
                let name = String(cString: interface.ifa_name)
                if name.starts(with: "en") || name.starts(with: "pdp_ip") {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                               &hostname, socklen_t(hostname.count),
                               nil, socklen_t(0), NI_NUMERICHOST)
                    addresses.append(String(cString: hostname))
                }
            }
        }

        return addresses
    }

    var connectionCount: Int {
        return connections.count
    }
}

/// Individual WebSocket connection to a client
class WebSocketConnection: Hashable {
    let connection: NWConnection
    let id = UUID()
    var onDisconnect: (() -> Void)?

    init(connection: NWConnection) {
        self.connection = connection
    }

    func start() {
        connection.stateUpdateHandler = { [weak self] state in
            if case .cancelled = state {
                self?.onDisconnect?()
            }
        }
        connection.start(queue: .global())
    }

    func send(data: Data) {
        let metadata = NWProtocolWebSocket.Metadata(opcode: .binary)
        let context = NWConnection.ContentContext(identifier: "data", metadata: [metadata])

        connection.send(content: data, contentContext: context, isComplete: true, completion: .idempotent)
    }

    static func == (lhs: WebSocketConnection, rhs: WebSocketConnection) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

enum WebSocketServerError: LocalizedError {
    case failedToStart(String)

    var errorDescription: String? {
        switch self {
        case .failedToStart(let reason):
            return "Failed to start WebSocket server: \(reason)"
        }
    }
}
