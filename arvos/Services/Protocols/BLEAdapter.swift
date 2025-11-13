//
//  BLEAdapter.swift
//  arvos
//
//  Low-bandwidth transport using CoreBluetooth peripheral mode.
//

import Foundation
import CoreBluetooth
#if canImport(UIKit)
import UIKit
#endif

final class BLEAdapter: NSObject, StreamingProtocol {
    weak var delegate: StreamingProtocolDelegate?
    
    private(set) var state: ConnectionState = .disconnected {
        didSet {
            if oldValue != state {
                delegate?.streamingProtocol(self, didChangeState: state)
            }
        }
    }
    
    private let protocolDisplayName = "BLE"
    private let workQueue = DispatchQueue(label: "com.arvos.ble-adapter")
    
    private var peripheralManager: CBPeripheralManager?
    private var dataCharacteristic: CBMutableCharacteristic?
    private var controlCharacteristic: CBMutableCharacteristic?
    private var subscribedCentrals: [CBCentral] = []
    
    private var pendingChunks: [Data] = []
    
    private var bytesSent: Int64 = 0
    private var messagesSent: Int64 = 0
    private var reconnectAttempts: Int = 0
    
    private let maxChunkSize = 180 // conservative MTU for BLE notifications
    
    private var advertisedName: String = UIDevice.current.name
    
    var protocolName: String {
        protocolDisplayName
    }
    
    // MARK: - StreamingProtocol
    
    func connect(config: ConnectionConfig) async throws {
        guard state != .connected else { return }
        state = .connecting
        advertisedName = config.additionalParams["deviceName"] as? String ?? UIDevice.current.name
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            workQueue.async {
                self.peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
                self.waitForPowerOn(continuation: continuation)
            }
        }
    }
    
    func disconnect() {
        workQueue.async {
            self.peripheralManager?.stopAdvertising()
            self.peripheralManager?.removeAllServices()
            self.peripheralManager = nil
            self.subscribedCentrals.removeAll()
            self.pendingChunks.removeAll()
            self.state = .disconnected
        }
    }
    
    func send<T: Encodable>(json object: T) throws {
        guard state == .connected else {
            throw StreamingProtocolError.notConnected
        }
        
        let data: Data
        do {
            data = try JSONEncoder().encode(object)
        } catch {
            throw StreamingProtocolError.encodingFailed(error.localizedDescription)
        }
        
        enqueue(data: data)
    }
    
    func send(data: Data) throws {
        // BLE transport is meant for low-bandwidth telemetry only.
        print("⚠️ BLEAdapter: binary payload dropped (not supported over BLE)")
    }
    
    func getStatistics() -> StreamingProtocolStatistics {
        StreamingProtocolStatistics(
            state: state,
            bytesSent: bytesSent,
            messagesSent: messagesSent,
            queuedMessages: pendingChunks.count,
            reconnectAttempts: reconnectAttempts,
            protocolName: protocolDisplayName
        )
    }
    
    func resetStatistics() {
        bytesSent = 0
        messagesSent = 0
        pendingChunks.removeAll()
    }
    
    static func isAvailable() -> Bool {
        if #available(iOS 13.0, *) {
            let auth = CBCentralManager.authorization
            return auth == .allowedAlways || auth == .notDetermined
        } else {
            return true
        }
    }
    
    // MARK: - Helpers
    
    private func waitForPowerOn(continuation: CheckedContinuation<Void, Error>) {
        guard let manager = peripheralManager else {
            continuation.resume(throwing: StreamingProtocolError.connectionFailed("Peripheral manager not created"))
            return
        }
        
        switch manager.state {
        case .poweredOn:
            setupServices()
            startAdvertising()
            state = .connected
            continuation.resume()
        case .unsupported, .unauthorized, .poweredOff:
            continuation.resume(throwing: StreamingProtocolError.connectionFailed("Bluetooth not available (\(manager.state.rawValue))"))
        case .resetting, .unknown:
            // Wait for delegate callback
            manager.delegate = self
            managerQueueContinuation = continuation
        @unknown default:
            continuation.resume(throwing: StreamingProtocolError.connectionFailed("Unknown Bluetooth state"))
        }
    }
    
    private func setupServices() {
        guard let manager = peripheralManager else { return }
        
        manager.removeAllServices()
        
        let serviceUUID = CBUUID(string: "5B6A38A0-2A0E-4A5F-8C96-5ED26F1935B8")
        let dataUUID = CBUUID(string: "3E2E3101-0BC0-4B53-9CF0-9E9981F357F1")
        let controlUUID = CBUUID(string: "552BD131-1604-452B-9A37-7F29A2DC3C32")
        
        let dataCharacteristic = CBMutableCharacteristic(
            type: dataUUID,
            properties: [.notify],
            value: nil,
            permissions: []
        )
        
        let controlCharacteristic = CBMutableCharacteristic(
            type: controlUUID,
            properties: [.writeWithoutResponse],
            value: nil,
            permissions: [.writeable]
        )
        
        let service = CBMutableService(type: serviceUUID, primary: true)
        service.characteristics = [dataCharacteristic, controlCharacteristic]
        
        manager.add(service)
        self.dataCharacteristic = dataCharacteristic
        self.controlCharacteristic = controlCharacteristic
    }
    
    private func startAdvertising() {
        guard let manager = peripheralManager else { return }
        let advertisement: [String: Any] = [
            CBAdvertisementDataLocalNameKey: advertisedName,
            CBAdvertisementDataServiceUUIDsKey: [CBUUID(string: "5B6A38A0-2A0E-4A5F-8C96-5ED26F1935B8")]
        ]
        manager.startAdvertising(advertisement)
    }
    
    private func enqueue(data: Data) {
        workQueue.async {
            guard !self.subscribedCentrals.isEmpty else {
                print("⚠️ BLEAdapter: no subscribed centrals, dropping message")
                return
            }
            
            guard let characteristic = self.dataCharacteristic else {
                print("⚠️ BLEAdapter: data characteristic missing")
                return
            }
            
            var framed = Data()
            var length = UInt32(data.count).littleEndian
            framed.append(Data(bytes: &length, count: MemoryLayout<UInt32>.size))
            framed.append(data)
            
            self.messagesSent += 1
            self.bytesSent += Int64(framed.count)
            
            var offset = 0
            while offset < framed.count {
                let end = min(offset + self.maxChunkSize, framed.count)
                let chunk = framed.subdata(in: offset..<end)
                if !(self.peripheralManager?.updateValue(chunk, for: characteristic, onSubscribedCentrals: nil) ?? false) {
                    self.pendingChunks.append(chunk)
                    break
                }
                offset = end
            }
        }
    }
    
    private var managerQueueContinuation: CheckedContinuation<Void, Error>?
}

// MARK: - CBPeripheralManagerDelegate

extension BLEAdapter: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn:
            setupServices()
            startAdvertising()
            state = .connected
            managerQueueContinuation?.resume()
            managerQueueContinuation = nil
        case .poweredOff, .unauthorized, .unsupported:
            state = .error
            let error = StreamingProtocolError.connectionFailed("Bluetooth state \(peripheral.state.rawValue)")
            delegate?.streamingProtocol(self, didEncounterError: error)
            managerQueueContinuation?.resume(throwing: error)
            managerQueueContinuation = nil
        case .resetting, .unknown:
            break
        @unknown default:
            break
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        workQueue.async {
            if !self.subscribedCentrals.contains(where: { $0.identifier == central.identifier }) {
                self.subscribedCentrals.append(central)
            }
            self.state = .connected
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        workQueue.async {
            self.subscribedCentrals.removeAll(where: { $0.identifier == central.identifier })
        }
    }
    
    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        workQueue.async {
            guard let characteristic = self.dataCharacteristic, !self.pendingChunks.isEmpty else { return }
            while !self.pendingChunks.isEmpty {
                let chunk = self.pendingChunks.removeFirst()
                if !(peripheral.updateValue(chunk, for: characteristic, onSubscribedCentrals: nil)) {
                    self.pendingChunks.insert(chunk, at: 0)
                    break
                }
            }
        }
    }
}


