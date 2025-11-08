# ARVOS

**Stream iPhone sensors to your computer for AR/robotics research.**

## What It Does

ARVOS streams sensor data from your iPhone to desktop applications over WiFi:

- **Camera**: 30 FPS @ 1920x1080 (JPEG)
- **Depth**: 5 FPS LiDAR point clouds (PLY)
- **IMU**: 100 Hz accelerometer + gyroscope
- **Pose**: 30 Hz 6DOF tracking (ARKit)
- **GPS**: 1 Hz location

## How To Use

### 1. Start Server (Python)
```bash
pip install arvos-sdk
python -m arvos.examples.basic_server
```

### 2. Connect iPhone
1. Open ARVOS app
2. Tap "CONNECT TO SERVER"
3. Enter your computer's IP address
4. Tap "CONNECT"

### 3. Stream
1. Tap slider icon to enable/disable sensors
2. Tap "START"
3. Data flows to your server

## For Researchers

- **SLAM**: Real-time camera + depth + IMU
- **ROS 2**: Bridge to robot systems (see SDK examples)
- **ML**: Collect training datasets
- **Sensor Fusion**: All sensors time-synchronized

## Requirements

- iPhone 12 Pro or newer (for LiDAR)
- iOS 14.0+
- Same WiFi network as computer

## SDK

Documentation: `/Users/jaskiratsingh/Desktop/arvos-sdk/`

Examples:
- `basic_server.py` - Simple data receiver
- `camera_viewer.py` - Live video display
- `point_cloud_viewer.py` - 3D visualization
- `ros2_bridge.py` - ROS 2 integration
- `save_to_csv.py` - Data export

## Data Format

WebSocket on port 9090 (default):
- JSON messages: IMU, GPS, Pose
- Binary messages: Camera (JPEG), Depth (PLY)
- Timestamps in nanoseconds

## Build

1. Open `arvos.xcodeproj` in Xcode
2. Select your iPhone
3. Build & Run

---

**Clean. Reliable. Professional.**
