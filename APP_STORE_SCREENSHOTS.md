# App Store Screenshot Captions

## Screenshot 1: Main Streaming View
**Caption:** Real time sensor streaming with live FPS counter and stats

**What to show:**
- StreamView in streaming mode
- FPS counter showing 30+ FPS
- Mode badge showing "Full Sensor"
- Clean bento box layout with stats
- Recording indicator if recording active
- IMU magnitude chart with activity

## Screenshot 2: Streaming Modes
**Caption:** Choose from Full Sensor, Camera Only, Depth Only, or Custom modes

**What to show:**
- Mode selector screen or
- Custom mode with sensor toggles showing
- Camera, Depth, IMU, Pose, GPS toggles
- Clear labels for each sensor type
- Toggle states visible

## Screenshot 3: 3D Point Cloud Test View
**Caption:** Visualize LiDAR and depth data in real time 3D point clouds

**What to show:**
- DepthPointCloudView with visible point cloud
- Colorful 3D points forming a scene
- Clear depth perception
- FPS counter showing smooth performance
- Back button visible

## Screenshot 4: Connection Options
**Caption:** Multiple protocols: WebSocket, gRPC, MQTT, HTTP, and cloud relay

**What to show:**
- ConnectionSheet with protocol picker
- List of protocols visible
- WebSocket selected (highlighted)
- Host and port fields
- Professional looking interface

## Screenshot 5: Web Studio Companion
**Caption:** Free web studio visualizes all sensor data in your browser

**What to show:**
- Screenshot of web studio running
- Camera feed visible
- 3D point cloud rendering
- IMU charts updating
- Connection status showing "Streaming"
- Multiple panels visible

**Alternative:** Show iPad view with larger UI elements

---

# Additional Marketing Assets

## App Icon Requirements
- 1024x1024 PNG (no transparency, no alpha)
- Should represent sensor/streaming concept
- Clean, modern design
- Recognizable at small sizes

## Color Palette Used in App
- Primary: Blue (#3B82F6)
- Success: Green (#10B981)  
- Warning: Amber (#F59E0B)
- Danger: Red (#EF4444)
- Background: System background
- Text: System primary/secondary

## Key Visual Elements
- Monospaced fonts for technical data
- Clean cards with rounded corners
- Subtle shadows for depth
- Icon based navigation
- Real time updating charts

---

# Social Media Copy

## Twitter/X (280 characters)
Turn your iPhone into a sensor streaming powerhouse. Stream camera, LiDAR, depth, IMU, and GPS data in real time. Perfect for robotics research and computer vision. No cloud required.

Download: [App Store Link]

## LinkedIn Post
Introducing Arvos: Professional sensor streaming for iPhone

Stream camera, depth, LiDAR, IMU, pose, and GPS data from your iPhone to any computer. Built for robotics researchers, computer vision developers, and anyone working with real world sensor data.

Key features:
• Multiple streaming modes
• Real time 3D visualization  
• MCAP recording compatible with Foxglove and ROS 2
• WebSocket, gRPC, MQTT, HTTP protocols
• Privacy first: all data stays on your device
• Free web studio for visualization

Works completely offline with local network streaming. No account required.

Perfect for SLAM testing, AR/VR development, dataset collection, and robotics research.

Available now on the App Store.

## Reddit Post (r/robotics, r/computervision)
Title: Released Arvos: Stream iPhone sensors (camera, LiDAR, IMU, GPS) to your computer

I built a tool that turns your iPhone into a sensor streaming device for robotics and computer vision work.

What it does:
Stream camera (1920x1440), depth/LiDAR, IMU (100Hz), ARKit pose, and GPS from iPhone to any computer over WiFi. The phone runs a WebSocket server and your computer connects to it directly.

Why I built it:
Needed an easy way to test SLAM algorithms with real sensor data. Existing tools either required expensive equipment or complicated setup. iPhones have great sensors, so why not use them?

Features:
• Multiple modes: stream everything or just what you need
• Web studio for real time 3D visualization (runs in browser)
• Record to MCAP format (works with Foxglove Studio and ROS 2)
• Python SDK included
• Multiple protocols: WebSocket, gRPC, MQTT, HTTP
• Privacy focused: everything stays on your device

Free web studio at studio.arvos.app
Python SDK on GitHub

The app is on the App Store. Would love feedback from the community.

---

# Press Release

FOR IMMEDIATE RELEASE

Arvos Launches iPhone Sensor Streaming App for Robotics and Computer Vision Research

New iOS app provides direct access to iPhone camera, LiDAR, depth, IMU, and GPS sensors with real time streaming capabilities

[CITY, DATE] Today marks the release of Arvos, an iOS application that transforms iPhones into professional sensor streaming devices. Designed for robotics researchers, computer vision developers, and spatial computing enthusiasts, Arvos provides direct access to iPhone's advanced sensor suite with zero cloud dependencies.

"We built Arvos to solve a real problem in robotics research," said [Founder Name]. "Researchers need access to quality sensor data for testing SLAM algorithms, training computer vision models, and validating navigation systems. iPhones have incredible sensors, but accessing that data in a usable format has been challenging. Arvos changes that."

Key capabilities include:

Real Time Streaming: Stream camera (1920x1440 at 30-60 FPS), depth and LiDAR data, IMU sensors (100 Hz), ARKit pose tracking, and GPS coordinates simultaneously to any computer on the local network.

Multiple Protocols: Support for WebSocket, gRPC, MQTT, and HTTP enables integration with existing workflows and tools.

Professional Recording: Local recording to MCAP format ensures compatibility with industry standard tools like Foxglove Studio and ROS 2.

Web Based Visualization: Free companion web studio provides instant visualization of camera feeds, 3D point clouds, IMU charts, and GPS trajectories in any browser.

Privacy First Design: All sensor data remains on the device or streams to user controlled destinations. No cloud uploads, no accounts, no tracking.

Arvos is available now on the App Store for iPhone XR and newer devices running iOS 16 or later. LiDAR features require iPhone 12 Pro or newer. The companion web studio is free and open source.

For more information, visit arvos.app

---

# FAQ for App Store Support Page

**Q: What iPhone models are supported?**
A: iPhone XR and newer. LiDAR features require iPhone 12 Pro or newer.

**Q: Do I need to create an account?**
A: No. Arvos works without any account or login.

**Q: Where does my data go?**
A: Your sensor data streams directly from your iPhone to whatever device you connect. Nothing is uploaded to any cloud service unless you explicitly choose the cloud relay option.

**Q: How do I connect the web studio?**
A: Make sure your iPhone and computer are on the same WiFi network. Start streaming in the app, note the IP address shown, then open studio.arvos.app in your browser and enter that IP address.

**Q: Can I use this offline?**
A: Yes. Local network streaming works completely offline.

**Q: What is the cloud relay?**
A: An optional server that lets you stream when your iPhone and computer are on different networks. Not required for local use.

**Q: Do I need a LiDAR iPhone?**
A: No. Depth sensors work on all devices with Face ID. LiDAR provides denser point clouds but is not required.

**Q: Can I record while streaming?**
A: Yes. The app can record locally while streaming.

**Q: What format are recordings?**
A: MCAP format, compatible with Foxglove Studio, ROS 2, and other standard tools.

**Q: Is there a Python SDK?**
A: Yes. Available on GitHub with examples for WebSocket servers and data parsing.

**Q: Does this work with ROS?**
A: Yes. Record to MCAP and import to ROS 2, or use the Python SDK to create a ROS bridge.

**Q: What permissions does the app need?**
A: Camera (for video), Motion & Fitness (for IMU), Local Network (for WebSocket server). Location and Bluetooth are optional.

**Q: Why does my iPhone get warm?**
A: Real time 3D rendering and sensor processing are intensive. This is normal, especially when using the point cloud test view.

**Q: Can I stream to multiple computers?**
A: Yes. The WebSocket server supports multiple client connections.

**Q: What protocols are supported?**
A: WebSocket, gRPC, MQTT, HTTP/REST, and MCAP streaming.

