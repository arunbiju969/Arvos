# Arvos - iPhone Sensor Streaming App

Turn your iPhone into a powerful sensor robot for robotics, 3D mapping, and research. Arvos streams real-time sensor data from your iPhone to any computer over Wi-Fi.

## Features

### 📡 Real-Time Sensor Streaming
- **Camera**: RGB video at up to 30 FPS with JPEG compression
- **LiDAR/Depth**: 3D point clouds at 1-10 FPS (iPhone Pro models)
- **IMU**: Accelerometer + gyroscope at 50-400 Hz
- **ARKit Pose**: 6DOF camera tracking at 10-60 Hz
- **GPS**: Location data for outdoor mapping

### 🎯 Six Streaming Modes

1. **Live Stream** - Low-latency streaming for visualization
   - Camera: 10 FPS | IMU: 100 Hz | Pose: 30 Hz | Depth: 5 Hz

2. **Mapping** - High-fidelity data for 3D reconstruction
   - Camera: 30 FPS | IMU: 200 Hz | Pose: 60 Hz | Depth: 10 Hz | GPS: 1 Hz
   - Auto-recording enabled

3. **Telemetry** - Lightweight streaming for long-term logging
   - IMU: 100 Hz | Pose: 30 Hz | GPS: 1 Hz

4. **Burst Scan** - Quick 30-60s high-quality capture
   - Auto-stops after duration | Records automatically

5. **Low Power** - Minimal sensors for battery conservation
   - Camera: 2 FPS | IMU: 50 Hz

6. **Replay** - Stream from recorded files

### 💾 Multi-Format Recording
- **MCAP**: Industry-standard format for all sensor data
- **PLY**: Point clouds for 3D visualization
- **H264/MOV**: Video recording at configurable bitrate

### 🔗 Connection Methods
- **QR Code**: Scan server QR for instant connection
- **Manual Entry**: Enter IP address and port
- Native WebSocket streaming (JSON + binary)

### ⏱️ Timestamp Synchronization
- Nanosecond-precision timestamps
- Optional NTP sync with server
- Clock offset tracking

## Requirements

- **iPhone**: iPhone 12 or later recommended
  - LiDAR: iPhone 12 Pro and later (other models use ARKit depth estimation)
- **iOS**: 16.0+
- **ARKit**: Required for depth and pose tracking

## Installation

1. Clone the repository:
```bash
git clone https://github.com/jaskirat1616/Arvos.git
cd arvos
```

2. Open in Xcode:
```bash
open arvos.xcodeproj
```

3. Select your iPhone as the deployment target
4. Build and run (⌘R)

## Usage

### Quick Start

1. **Launch Arvos** on your iPhone
2. **Connect to Server**:
   - Tap "Connect to Server"
   - Scan QR code from your computer OR enter IP manually
   - Default port: 9090

3. **Select Mode**:
   - Swipe through mode cards
   - Tap to select (Live Stream, Mapping, etc.)

4. **Start Streaming**:
   - Tap "Start Streaming"
   - Grant camera, location, and motion permissions when prompted
   - Watch real-time sensor status indicators

5. **Stop Streaming**:
   - Tap "Stop Streaming"
   - Recorded files saved to Files tab

### Tabs

- **Stream**: Main interface with mode selector and controls
- **Settings**: Adjust sensor rates (FPS, Hz)
- **Files**: Browse and manage recordings
- **Debug**: Technical info, sensor status, performance metrics

## Network Protocol

### WebSocket Endpoint
```
ws://<host>:<port>
```

### Message Types

#### JSON Messages (Small Data)
```json
{
  "type": "imu",
  "timestampNs": 1700000000000,
  "angularVelocity": [0.01, -0.02, 0.005],
  "linearAcceleration": [0.1, 0.0, -0.01]
}
```

#### Binary Messages (Images, Point Clouds)
Format: `[Header Size (4 bytes)][JSON Header][Binary Data]`

Header:
```json
{
  "type": "camera",
  "timestampNs": 1700000000000,
  "dataSize": 12345,
  "metadata": {...}
}
```

### Handshake
On connection, Arvos sends device capabilities:
```json
{
  "type": "handshake",
  "deviceName": "iPhone 15 Pro",
  "deviceModel": "iPhone",
  "osVersion": "17.0",
  "capabilities": {
    "hasLiDAR": true,
    "hasARKit": true,
    "hasGPS": true,
    "supportedModes": [...]
  }
}
```

## Server Examples

### Python Example
```python
import asyncio
import websockets
import json

async def receive_data(websocket):
    async for message in websocket:
        if isinstance(message, str):
            # JSON message (IMU, GPS, pose)
            data = json.loads(message)
            print(f"Received {data['type']}: {data}")
        else:
            # Binary message (camera, depth)
            # Parse header size (first 4 bytes)
            header_size = int.from_bytes(message[:4], 'little')
            header = json.loads(message[4:4+header_size])
            binary_data = message[4+header_size:]
            print(f"Received {header['type']}: {len(binary_data)} bytes")

async def main():
    async with websockets.serve(receive_data, "0.0.0.0", 9090):
        print("Server started on port 9090")
        await asyncio.Future()

asyncio.run(main())
```

### ROS 2 Bridge
Coming soon - Python bridge to convert Arvos streams to ROS topics.

## File Formats

### MCAP
- Multi-channel container with separate topics per sensor
- Channels: `/camera`, `/depth`, `/imu`, `/pose`, `/gps`
- Compatible with Foxglove Studio and MCAP tools

### PLY Point Clouds
```
ply
format binary_little_endian 1.0
element vertex <count>
property float x
property float y
property float z
property uchar red
property uchar green
property uchar blue
end_header
<binary vertex data>
```

## Architecture

```
arvos/
├── Models/               # Data structures
│   ├── StreamMode.swift
│   ├── SensorData.swift
│   └── NetworkMessage.swift
├── Services/            # Sensor interfaces
│   ├── CameraService.swift
│   ├── ARKitService.swift
│   ├── IMUService.swift
│   ├── GPSService.swift
│   ├── WebSocketService.swift
│   ├── MCAPWriter.swift
│   └── VideoRecorder.swift
├── Managers/            # Coordinators
│   ├── SensorManager.swift
│   ├── NetworkManager.swift
│   ├── RecordingManager.swift
│   └── TimestampManager.swift
├── ViewModels/          # MVVM
│   └── StreamingViewModel.swift
└── Views/               # SwiftUI UI
    ├── Screens/
    └── Components/
```

## Customization

### Adjust Sensor Rates
Settings tab → Sliders for each sensor:
- Camera FPS: 1-30
- Depth FPS: 1-10
- IMU Hz: 50-400
- Pose Hz: 10-60

### Create Custom Modes
Edit `Models/StreamMode.swift`:
```swift
case myCustomMode = "My Custom Mode"

var config: ModeConfiguration {
    switch self {
    case .myCustomMode:
        return ModeConfiguration(
            cameraEnabled: true,
            cameraFPS: 15,
            // ... configure other sensors
        )
    }
}
```

## Troubleshooting

### Camera Not Streaming
- Check camera permission: Settings → Arvos → Camera
- Ensure camera is not in use by another app
- Try switching modes

### Connection Issues
- Verify iPhone and computer on same Wi-Fi network
- Check firewall isn't blocking port 9090
- Test connection: `nc -l 9090` on computer, then connect from app

### Poor Performance
- Reduce FPS/Hz in Settings tab
- Use Low Power mode for extended battery
- Close other apps running in background

### No LiDAR Depth
- LiDAR requires iPhone 12 Pro or later
- ARKit depth estimation used as fallback
- Check depth sensor status in Debug tab

## Contributing

We welcome contributions! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

[Add your license here]

## Credits

Built by [Your Name/Team]

Uses:
- ARKit for depth and pose tracking
- CoreMotion for IMU data
- AVFoundation for camera capture
- Native URLSession WebSocket (no external dependencies)

## Contact

- GitHub: https://github.com/jaskirat1616/Arvos
- Issues: https://github.com/jaskirat1616/Arvos/issues

---

**Arvos**: Turn your iPhone into a sensor robot 🤖📱
