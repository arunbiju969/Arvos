# Arvos App Store Listing

## App Name
Arvos: Sensor Data Streaming

## Subtitle (30 characters max)
Stream iPhone sensors to studio

## Description (4000 characters max)

Arvos turns your iPhone into a powerful sensor streaming device. Capture and stream camera, depth, LiDAR, IMU, GPS, and Apple Watch data in real time to visualize on any computer running the web studio.

Perfect for robotics research, AR/VR development, computer vision projects, SLAM testing, and spatial computing experiments. Arvos gives you direct access to your iPhone's advanced sensors with zero cloud dependencies.

STREAMING MODES

Full Sensor Mode: Stream everything at once including camera, depth, IMU, pose tracking, and GPS data. Get a complete picture of your environment.

Camera Only: High framerate video streaming up to 60 FPS for computer vision and image processing tasks.

Depth Only: LiDAR and depth sensor streaming for 3D reconstruction, point cloud generation, and spatial mapping.

Custom Mode: Choose exactly which sensors you want. Mix and match camera, depth, IMU, pose, and GPS based on your needs.

PROFESSIONAL SENSORS

Camera: 1920x1440 resolution at 30-60 FPS with JPEG compression. Full access to the rear wide camera.

Depth & LiDAR: True depth data with confidence mapping. Point clouds with RGB color. Works with both LiDAR equipped devices and regular depth sensors.

IMU: Accelerometer, gyroscope, and magnetometer data at 100 Hz. Essential for motion tracking and orientation.

Pose Tracking: ARKit world tracking with 6DOF position and orientation. Know exactly where your device is in 3D space.

GPS: Location tracking with accuracy indicators. Perfect for outdoor mapping and navigation research.

Apple Watch: Pair your watch to add heart rate, activity data, and wrist motion sensors to your stream.

STREAMING PROTOCOLS

WebSocket: Direct connection to the web studio or Python SDK. No servers, no latency.

Cloud Relay: Stream over the internet when devices are on different networks.

gRPC: High performance Protocol Buffers for research applications.

MQTT: Publish sensor data to any MQTT broker for IoT integration.

HTTP/REST: Simple REST API for quick integration.

MCAP: Record to industry standard MCAP format compatible with Foxglove Studio.

RECORDING & EXPORT

Record locally to your iPhone while streaming. Everything saves to MCAP format for later analysis in Foxglove Studio, ROS 2, or custom tools.

Export to KITTI format for autonomous driving research. TUM format support for SLAM benchmarking.

STUDIO COMPANION

The web studio runs in any browser. Connect your iPhone and see real time visualization of camera feeds, 3D point clouds, IMU charts, GPS maps, and pose trajectories.

No installation required. Works on Mac, Windows, Linux. Open source and available at studio.arvos.app.

USE CASES

Robotics: Test SLAM algorithms with real sensor data. Validate visual odometry and mapping systems.

Computer Vision: Capture training data for machine learning. Stream video for real time inference.

AR/VR Development: Debug spatial tracking. Visualize world anchors and scene understanding.

Research: Collect sensor datasets. Benchmark algorithms against real world data.

Education: Learn about sensor fusion. Experiment with computer vision and robotics concepts.

DEVELOPER FRIENDLY

Python SDK available with examples for WebSocket servers, data parsers, and visualization tools.

Open protocol documentation. Works with any tool that speaks WebSocket, gRPC, or MQTT.

Source code examples for integration with ROS 2, Rerun, and custom applications.

PRIVACY FIRST

All data stays on your device or your own server. No cloud uploads unless you choose cloud relay.

No account required. No tracking. Your sensor data is yours.

Works completely offline with local network streaming.

REQUIREMENTS

iPhone 12 or newer recommended for LiDAR (iPhone XR and newer work with depth sensors)
iOS 16.0 or later
Apple Watch Series 4 or newer for watch features (optional)

Get started in seconds. Point your iPhone at the world and stream real sensor data to your studio.

## Keywords (100 characters max)
sensor,lidar,depth,camera,streaming,robotics,slam,computer vision,imu,point cloud,dataset,research

## Promotional Text (170 characters max)
Stream camera, LiDAR, depth, IMU, and GPS from your iPhone to any computer. Perfect for robotics, AR development, and computer vision research. No cloud required.

## What's New (4000 characters max)

### Version 1.0

Initial release of Arvos brings professional sensor streaming to iPhone.

Stream camera, depth, LiDAR, IMU, pose, and GPS data in real time. Multiple streaming modes let you choose exactly what you need. Custom mode gives complete control over which sensors are active.

Web studio provides instant visualization with 3D point clouds, camera feeds, IMU charts, and GPS maps. Works in any browser with zero installation.

Record locally to MCAP format for analysis in Foxglove Studio and ROS 2. Export datasets to KITTI and TUM formats for research.

Connect via WebSocket for local streaming or use cloud relay for internet based connections. Support for gRPC, MQTT, and HTTP protocols.

Apple Watch integration adds heart rate and activity data to your streams.

Built for robotics researchers, computer vision developers, and anyone who needs access to real sensor data.

## Support URL
https://arvos.app/support

## Marketing URL  
https://arvos.app

## Privacy Policy URL
https://arvos.app/privacy

## Copyright
© 2024 Arvos. All rights reserved.

## Category
Primary: Developer Tools
Secondary: Utilities

## Age Rating
4+

## App Store Screenshots Required

### iPhone 6.7" (Required)
1. Streaming view showing live FPS, mode, and connection status
2. Full sensor mode with all data types streaming
3. 3D point cloud visualization in test view
4. Connection settings with protocol selection
5. Recording interface with duration and file size

### iPhone 6.5" (Required)  
Same as 6.7"

### iPhone 5.5" (Optional)
Same layout, smaller screen

### iPad Pro 12.9" (Optional)
1. Streaming view optimized for iPad with larger UI
2. Split view showing stats and visualizations
3. Connection panel with server options

## App Preview Videos (Optional but Recommended)

### iPhone Video (15-30 seconds)
1. Launch app
2. Select Full Sensor mode
3. Tap Start Streaming
4. Show FPS counter updating
5. Show connection IPs
6. Switch to web studio
7. Show live 3D point cloud
8. Show camera feed
9. Highlight real time updates

### Narration Script
"Arvos streams your iPhone sensors in real time. Choose your mode, start streaming, and visualize everything in the web studio. Camera, depth, LiDAR, IMU, and GPS. All streaming live from your iPhone."

## App Review Notes

### Demo Account
Not required. App works without login.

### Testing Instructions

1. Install app on iPhone 12 or newer (LiDAR works best)
2. Open app and tap "Start Streaming"  
3. Note one of the IP addresses shown on screen
4. On a computer on the same WiFi network:
   - Open browser to https://studio.arvos.app
   - Enter the iPhone IP address
   - Click Connect
5. You should see camera feed and point cloud data streaming

Alternatively, test with the cloud relay:
1. In app, tap connection settings
2. Tap "Use Cloud Relay"
3. Tap Connect
4. Tap Start Streaming
5. Open studio.arvos.app on any device
6. Click "Use Cloud Relay" 
7. Click Connect

The WebSocket server runs on the iPhone itself. The studio connects to it directly. No external servers needed for local mode.

### Special Permissions

Camera: Required for video streaming
Location: Optional, only used if GPS mode is selected  
Motion & Fitness: Required for IMU data
Local Network: Required for WebSocket server
Bluetooth: Optional, only for Apple Watch pairing

All permissions are requested with clear explanations when first needed.

### Privacy Compliance

All sensor data stays on device or streams to user's chosen destination. No data collection. No analytics. No tracking. Works completely offline.

Privacy policy explains data handling: user controls all data, nothing uploaded to our servers, local or self hosted streaming only.

### Additional Notes

The app creates a WebSocket server on the iPhone. This is the core functionality. When streaming starts, other devices connect to the iPhone as clients (similar to how Foxglove Studio or ROS tools work).

Point cloud visualization uses Metal for hardware acceleration. May generate heat during extended use (normal for real time 3D rendering).

Apple Watch features require paired watch. Works without watch if not available.

Some features require iPhone 12+ for LiDAR. Depth sensors work on all devices with Face ID.

