# ARVOS

**Stream iPhone + Apple Watch sensors to your computer for AR/robotics research.**

Turn your iPhone (and optional Apple Watch) into a professional research sensor platform with LiDAR, cameras, IMU, ARKit pose tracking, wearable motion activity, and gestures.

---

## 🌐 Quickest Start: Web Viewer (No Install!)

Stream to your browser in 30 seconds:

```bash
cd arvos-sdk/web-viewer
./start-viewer.sh
# Scan QR code with iPhone → Done!
```

[→ Full Web Viewer Guide](https://github.com/jaskirat1616/arvos-sdk/tree/main/web-viewer)

---

## 📱 What It Streams

- **Camera**: 30 FPS @ 1920x1080 RGB
- **LiDAR Depth**: 5 FPS point clouds with confidence maps
- **IMU**: 100-200 Hz accelerometer + gyroscope + gravity
- **ARKit Pose**: 30-60 Hz 6DOF tracking with quality flags
- **GPS**: 1 Hz location (outdoor)
- **Apple Watch** *(optional)*:
  - 50-100 Hz IMU (accelerometer + gyroscope + gravity)
  - Attitude (quaternion + pitch/roll/yaw)
  - Motion activity classifier (walking, running, cycling, vehicle, stationary)

**All sensors nanosecond-synchronized** for research-grade data.

---

## 🚀 Getting Started

### Option 1: Web Viewer (Recommended)
No Python needed - works on ANY device with a browser:
```bash
cd arvos-sdk/web-viewer
./start-viewer.sh
```

### Option 2: Python SDK
For custom applications and ROS 2 integration:
```bash
pip install arvos-sdk
python examples/01_quickstart.py
```

### Connect iPhone
1. Open **ARVOS** app
2. Tap **"CONNECT TO SERVER"**
3. Scan QR code (or enter IP manually)
4. Tap **"START"** to stream

---

## 🎯 Use Cases

**For Researchers:**
- SLAM algorithm development with ARKit ground truth
- Sensor fusion experiments
- ML dataset collection
- Real-time 3D reconstruction

**For Robotics Engineers:**
- ROS 2 perception testing
- Mobile sensor platform
- Algorithm prototyping
- Live demos

**For Students:**
- Computer vision learning
- AR experiments
- Sensor data visualization
- Course projects

---

## 📦 Features

- ✅ **7 Streaming Modes** - RGBD, Visual-Inertial, LiDAR, Full Sensor, etc.
- ✅ **Research Metadata** - Depth confidence, IMU calibration, pose quality
- ✅ **Local Recording** - MCAP format with H.264 video
- ✅ **Zero-Install Option** - Web viewer works everywhere
- ✅ **Professional Tools** - CLI for batch export (KITTI, TUM, EuRoC)
- ✅ **Open Formats** - PLY, CSV, ROS bags
- ✅ **Apple Watch Companion** - Stream wearable IMU, pose, and motion activity data in sync with iPhone sensors

---

## 💻 Requirements

**iPhone:**
- iPhone 12 Pro or newer (for LiDAR)
- iOS 17.0+
- Same WiFi network as computer

**Computer:**
- Any OS with Python 3.8+ or modern browser
- Same WiFi network as iPhone
- Firewall allows port 8765

**Apple Watch (optional):**
- Apple Watch Series 6 or newer (watchOS 9.0+)
- Paired with the streaming iPhone
- arvos watch companion app installed (see below)

---

## ⌚ Apple Watch Companion

Augment iPhone data with wearable motion sensing—perfect for robotics operators, telepresence rigs, and human-in-the-loop research.

**What you get**
- 50 Hz wearable IMU with nanosecond timestamps
- Attitude (quaternion & Euler angles)
- Motion activity classification (running, walking, cycling, vehicle, stationary)
- Live UI on both watch and iPhone

**Setup (once)**
1. Follow [`WATCH_XCODE_SETUP.md`](WATCH_XCODE_SETUP.md) to add the watch target in Xcode
2. Build & run the iOS app — the watch app installs automatically on the paired watch
3. Toggle "Apple Watch" in **Sensor Test** to visualize wearable data
4. Stream or record — watch packets flow through the existing WebSocket/MCAP pipeline

**Deep dive docs**
- [`WATCH_INTEGRATION.md`](WATCH_INTEGRATION.md) – architecture & transport details
- [`WATCH_TESTING_GUIDE.md`](WATCH_TESTING_GUIDE.md) – validation checklist
- [`WATCH_IMPLEMENTATION_SUMMARY.md`](WATCH_IMPLEMENTATION_SUMMARY.md)

---

## 📚 Documentation

- **Web Viewer**: [arvos-sdk/web-viewer/README.md](https://github.com/jaskirat1616/arvos-sdk/tree/main/web-viewer)
- **Python SDK**: [arvos-sdk/README.md](https://github.com/jaskirat1616/arvos-sdk)
- **Examples**: [arvos-sdk/examples/](https://github.com/jaskirat1616/arvos-sdk/tree/main/examples)
- **Watch Companion Guides**: [`WATCH_INTEGRATION.md`](WATCH_INTEGRATION.md), [`WATCH_XCODE_SETUP.md`](WATCH_XCODE_SETUP.md), [`WATCH_TESTING_GUIDE.md`](WATCH_TESTING_GUIDE.md)
- **CLI Tools**: [arvos-sdk/arvos/cli/](https://github.com/jaskirat1616/arvos-sdk/tree/main/arvos/cli)

---

## 🤝 Contributing

Found a bug? Have a feature request? [Open an issue!](https://github.com/jaskirat1616/arvos/issues)

---

## 📜 License

MIT License - Use freely in your research and projects

---

**Made for the robotics and AR research community** ❤️

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
