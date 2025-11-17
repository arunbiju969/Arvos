# Arvos Architecture - Foxglove-Style

## Overview

Arvos follows the **Foxglove Studio** architecture pattern where the **data source (iPhone) acts as the WebSocket SERVER**, and the **visualization tool (Studio web app) connects as a CLIENT**.

## Why This Architecture?

### ❌ OLD (Cloud Relay - BAD):
```
iPhone (client) → Cloud Relay Server → Studio (client)
```
**Problems**:
- Scalability issues (one server for all users)
- Cloud costs
- Higher latency
- Single point of failure
- Privacy concerns

### ✅ NEW (Foxglove-Style - GOOD):
```
iPhone (SERVER on port 8765) ← Studio (CLIENT)
```
**Benefits**:
- ✅ No scalability issues (each iPhone is its own server)
- ✅ Zero cloud costs
- ✅ Lower latency (direct peer-to-peer)
- ✅ No single point of failure
- ✅ Complete privacy (data never leaves local network)
- ✅ Works offline on same WiFi

## How It Works

### 1. iPhone App Startup
```swift
// iPhone starts WebSocket server on port 8765
let server = WebSocketServer(port: 8765)
try server.start()

// Prints local IP addresses:
// 📡 Connect Studio to:
//    ws://192.168.1.100:8765
//    ws://10.0.0.50:8765
```

### 2. Studio Connection
```typescript
// User opens Studio in browser
// Studio shows: "Connect to: ws://192.168.1.100:8765"
// Or scan QR code with iPhone IP

const ws = new WebSocket("ws://192.168.1.100:8765")
ws.onmessage = (event) => {
  // Receive sensor data
  handleSensorData(event.data)
}
```

### 3. Data Flow
```
Sensors (ARKit, IMU, Camera) 
  ↓
SensorManager
  ↓
NetworkManager
  ↓
WebSocketServer.broadcast(data) ← Sends to all connected Studio clients
  ↓
Studio receives and visualizes
```

## Connection Methods

### QR Code (Easiest)
1. iPhone shows QR code with `ws://[IP]:8765`
2. User scans QR with Studio
3. Studio connects automatically

### Manual Entry
1. iPhone displays IP (e.g., `192.168.1.100`)
2. User types in Studio: `192.168.1.100` 
3. Studio adds `ws://` and `:8765` automatically

### Discovery (Future)
- mDNS/Bonjour for automatic discovery on local network
- Studio scans and lists all available Arvos devices

## Network Requirements

- ✅ **Same WiFi network** (iPhone and computer running Studio)
- ✅ **Cellular hotspot** (iPhone creates hotspot, computer connects)
- ❌ Different networks won't work (unless VPN/port forwarding)

## Security

### Current (Development)
- Unencrypted WebSocket (`ws://`)
- No authentication
- Local network only

### Future (Production)
- TLS/SSL encryption (`wss://`)
- Token-based authentication
- Optional password protection

## Comparison with Foxglove

| Feature | Foxglove | Arvos |
|---------|----------|-------|
| Architecture | Robot is server | iPhone is server |
| Protocol | Foxglove WebSocket | Custom WebSocket |
| Port | 8765 (default) | 8765 (same!) |
| Discovery | Manual IP | QR Code + Manual |
| Data Format | Protobuf/JSON | Binary PLY + JSON |
| Use Case | Robotics | iPhone sensors |

## Files

### iOS App
- `arvos/Services/WebSocketServer.swift` - Server implementation
- `arvos/Managers/NetworkManager.swift` - Uses server
- `arvos/Views/Screens/StreamView.swift` - Shows connection info + QR

### Web Studio
- `components/studio/StudioInterface.tsx` - Connects as client
- `components/studio/ConnectionPanel.tsx` - Connection UI

## Future Enhancements

1. **mDNS Discovery**: Auto-find iPhones on network
2. **Multi-device**: Multiple iPhones → One Studio
3. **Recording**: Studio records data from iPhone
4. **Playback**: Studio plays back recorded sessions
5. **Cloud option**: Optional relay for remote access
