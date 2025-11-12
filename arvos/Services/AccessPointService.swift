//
//  AccessPointService.swift
//  arvos
//
//  Personal Hotspot detection and management
//

import Foundation
import Network
import SystemConfiguration
import Combine

#if canImport(UIKit)
import UIKit
#endif

class AccessPointService: ObservableObject {
    @Published var isHotspotActive: Bool = false
    @Published var hotspotIP: String = ""
    @Published var hotspotSSID: String = ""
    
    private var monitor: NWPathMonitor?
    private let monitorQueue = DispatchQueue(label: "com.arvos.hotspot-monitor")
    
    init() {
        detectHotspot()
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    // MARK: - Hotspot Detection
    
    func detectHotspot() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            
            let interfaces = self.getNetworkInterfaces()
            var foundHotspot = false
            var hotspotAddress = ""
            
            // Look for bridge interface (Personal Hotspot)
            for interface in interfaces {
                if interface.name.hasPrefix("bridge") {
                    foundHotspot = true
                    hotspotAddress = interface.address
                    print("📱 Personal Hotspot detected on \(interface.name): \(hotspotAddress)")
                    break
                }
            }
            
            // If no bridge interface, check for ap* interface (older iOS)
            if !foundHotspot {
                for interface in interfaces {
                    if interface.name.hasPrefix("ap") {
                        foundHotspot = true
                        hotspotAddress = interface.address
                        print("📱 Personal Hotspot detected on \(interface.name): \(hotspotAddress)")
                        break
                    }
                }
            }
            
            // Update on main thread
            DispatchQueue.main.async {
                self.isHotspotActive = foundHotspot
                self.hotspotIP = hotspotAddress.isEmpty ? "172.20.10.1" : hotspotAddress
                
                #if canImport(UIKit)
                self.hotspotSSID = UIDevice.current.name
                #endif
            }
        }
    }
    
    // MARK: - Network Monitoring
    
    func startMonitoring() {
        monitor = NWPathMonitor()
        
        monitor?.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            
            // Re-detect hotspot when network changes
            if path.status == .satisfied {
                self.detectHotspot()
            }
        }
        
        monitor?.start(queue: monitorQueue)
    }
    
    func stopMonitoring() {
        monitor?.cancel()
        monitor = nil
    }
    
    // MARK: - Connection URLs
    
    func getHotspotConnectionURL(scheme: String = "ws", port: Int = 9090) -> String {
        return "\(scheme)://\(hotspotIP):\(port)"
    }
    
    func getQRCodeData(scheme: String = "ws", port: Int = 9090) -> String {
        return getHotspotConnectionURL(scheme: scheme, port: port)
    }
    
    // MARK: - Network Interface Discovery
    
    private func getNetworkInterfaces() -> [NetworkInterface] {
        var interfaces: [NetworkInterface] = []
        
        // Get list of all interfaces
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else {
            return interfaces
        }
        defer { freeifaddrs(ifaddr) }
        
        var ptr = ifaddr
        while ptr != nil {
            defer { ptr = ptr?.pointee.ifa_next }
            
            guard let interface = ptr else { continue }
            let name = String(cString: interface.pointee.ifa_name)
            
            // Only process IPv4 addresses
            let addr = interface.pointee.ifa_addr.pointee
            guard addr.sa_family == UInt8(AF_INET) else { continue }
            
            // Convert address to string
            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            getnameinfo(interface.pointee.ifa_addr,
                       socklen_t(interface.pointee.ifa_addr.pointee.sa_len),
                       &hostname,
                       socklen_t(hostname.count),
                       nil,
                       socklen_t(0),
                       NI_NUMERICHOST)
            
            let address = String(cString: hostname)
            
            // Skip localhost
            guard address != "127.0.0.1" else { continue }
            
            interfaces.append(NetworkInterface(name: name, address: address))
        }
        
        return interfaces
    }
    
    // MARK: - Helper Methods
    
    func isPersonalHotspotEnabled() -> Bool {
        return isHotspotActive
    }
    
    func getConnectionInstructions() -> String {
        if isHotspotActive {
            return """
            ✅ Personal Hotspot is active!
            
            Connect your computer to: \(hotspotSSID)
            Then use this URL: \(getHotspotConnectionURL())
            """
        } else {
            return """
            Enable Personal Hotspot:
            
            1. Go to Settings → Personal Hotspot
            2. Turn ON "Allow Others to Join"
            3. Note your Wi-Fi password
            4. Connect your computer to this iPhone's hotspot
            5. Return to this app
            """
        }
    }
}

// MARK: - Network Interface Model

struct NetworkInterface {
    let name: String
    let address: String
}

