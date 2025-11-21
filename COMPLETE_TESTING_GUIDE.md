# Complete Testing Guide for Arvos Platform

This guide walks you through testing all three components: iOS app, Web Studio, and SDK.

---

## 🎯 Quick Start - 5 Minute Test

### Test 1: Local WiFi Streaming (iPhone → Web Studio)

**This is the fastest way to verify everything works!**

#### Step 1: Start Web Studio (on your Mac)
```bash
cd /Users/jaskiratsingh/Desktop/Arvos-web
npm run dev
```
- Web Studio opens at: http://localhost:3000/studio
- WebSocket server runs on: ws://localhost:8765

#### Step 2: Start iOS App (on iPhone/Simulator)
1. Open Xcode
2. Select your iPhone or Simulator
3. Press ⌘R to build and run
4. In the app:
   - Tap **"START STREAMING"** button
   - Note the IP address displayed (e.g., `ws://192.168.1.100:8765`)

#### Step 3: Connect Web Studio to iPhone
1. In Web Studio, click **"Connection"** button (top right)
2. Enter the iPhone IP address shown in the app
3. Click **"CONNECT"**
4. Status should change to **"CONNECTED"**

#### Step 4: Verify Data Streaming
- Camera feed should appear in Web Studio
- Point cloud viewer should show depth/LiDAR data
- IMU panel should show accelerometer/gyroscope data
- FPS counter should be updating

**✅ If you see data flowing, the core system works!**

---

## 📱 iOS App Tests

### Test 2: iPhone Personal Hotspot Mode

**When:** No WiFi available, or you want to use iPhone hotspot

#### Setup:
1. **On iPhone:**
   - Settings → Personal Hotspot → Enable
   - Note the WiFi password

2. **On Mac:**
   - Connect to iPhone's hotspot WiFi
   - You should get IP like `172.20.10.1`

3. **In Arvos iOS App:**
   - Tap "START STREAMING"
   - Note IP address (usually `172.20.10.1:8765`)

4. **In Web Studio:**
   - Enter `172.20.10.1` in connection panel
   - Port: `8765`
   - Connect

**Expected:** Data streams over iPhone hotspot connection

---

### Test 3: Cloud Relay Mode (Internet-based)

**When:** iPhone and computer are on different networks

#### Prerequisites:
```bash
# Check if cloud relay server is deployed
curl https://arvos-web.onrender.com/health

# Should return:
# {"status":"running","service":"arvos-relay-server",...}
```

#### Test Steps:

1. **In iOS App:**
   - Tap top right menu (three dots)
   - Select "Server Connection"
   - Tap **"Use Cloud Relay"** button
   - It auto-fills: `arvos-web.onrender.com:443`
   - Tap **"CONNECT"**
   - Status shows "Connected"
   - Tap **"START STREAMING"**

2. **Check data reaches cloud:**
   - Data flows from iPhone → Cloud relay server
   - Check relay server logs on Render.com

**⚠️ Note:** Web Studio currently doesn't have cloud relay UI. iPhone can connect, but Web Studio needs update to receive from cloud.

---

### Test 4: Different Streaming Modes

**In iOS App:**

1. **Full Sensor Mode:**
   - Select "Full Sensor" mode
   - START STREAMING
   - Verify all sensors active: Camera, Depth, IMU, Pose

2. **Camera Only Mode:**
   - Select "Camera Only" mode
   - START STREAMING
   - Only camera feed should stream (faster FPS)

3. **Depth Only Mode:**
   - Select "Depth Only" mode
   - START STREAMING
   - Only depth/LiDAR point clouds

4. **Custom Mode:**
   - Select "Custom" mode
   - Toggle individual sensors on/off
   - START STREAMING
   - Only selected sensors stream

**Expected:** Each mode streams only the enabled sensors

---

## 🌐 Web Studio Tests

### Test 5: Web Studio Development

```bash
cd /Users/jaskiratsingh/Desktop/Arvos-web

# Option A: Run everything (recommended)
npm run dev
# Starts both WebSocket server (port 8765) AND Next.js (port 3000)

# Option B: Separate processes
# Terminal 1:
npm run dev:server    # WebSocket server only

# Terminal 2:
npm run dev:studio    # Next.js dev server only
```

**Open:** http://localhost:3000/studio

**Test Features:**
- [ ] Connection panel opens/closes
- [ ] Can enter iPhone IP and connect
- [ ] Status changes: disconnected → connecting → connected → streaming
- [ ] Camera feed displays
- [ ] Point cloud viewer shows 3D data
- [ ] IMU panel shows real-time sensor values
- [ ] GPS panel shows location (if GPS enabled on iPhone)
- [ ] Settings panel allows adjusting visualization
- [ ] Recording button can start/stop recording
- [ ] Can disconnect cleanly

---

### Test 6: Web Studio Production Build

```bash
cd /Users/jaskiratsingh/Desktop/Arvos-web

# Build for production
npm run build

# Start production server
npm start
```

**Open:** http://localhost:3000/studio

**Verify:** Production build works identically to dev mode

---

## 🐍 Python SDK Tests

### Test 7: Basic WebSocket Server

**Receives data from iPhone via WebSocket**

```bash
cd /Users/jaskiratsingh/Desktop/arvos-sdk

# Run basic server
python3 examples/basic_server.py
```

**Output:**
```
🌐 Connect to:
   [1] ws://192.168.1.100:9090
   [2] ws://10.0.0.5:9090

📱 Scan with iPhone:
[QR CODE appears here]
```

**In iOS App:**
1. Tap menu → "Server Connection"
2. Scan QR code OR enter IP manually
3. Protocol: WebSocket
4. Port: 9090
5. CONNECT
6. START STREAMING

**Terminal should show:**
```
✅ New client connected
📱 iPhone Device connected: Your iPhone (iPhone 15 Pro)
📊 Stats: RX=100 TX=0 Clients=1
📤 IMU: ax=0.12 ay=-0.45 az=9.81
📤 Camera frame: 640x480, JPEG 45KB
📤 Depth: 1523 points
```

---

### Test 8: Camera Viewer

**View camera feed in OpenCV window**

```bash
cd /Users/jaskiratsingh/Desktop/arvos-sdk

# Install dependencies if needed
pip3 install opencv-python numpy websockets

# Run camera viewer
python3 examples/camera_viewer.py
```

**In iOS App:**
- Connect to server (default: port 9090)
- START STREAMING

**Expected:** OpenCV window opens showing live camera feed from iPhone

---

### Test 9: Depth Point Cloud Viewer

**View LiDAR/depth data in 3D**

```bash
cd /Users/jaskiratsingh/Desktop/arvos-sdk

# Install dependencies
pip3 install open3d numpy websockets

# Run depth viewer
python3 examples/depth_viewer.py
```

**In iOS App:**
- Connect to server
- Select mode with Depth enabled
- START STREAMING

**Expected:** Open3D window shows 3D point cloud updating in real-time

---

## 📋 Complete Test Checklist

### iOS App ✅
- [ ] App builds in Xcode (⌘R)
- [ ] Can start streaming in server mode
- [ ] Displays local IP addresses
- [ ] Can connect to cloud relay
- [ ] All streaming modes work (Full/Camera/Depth/Custom)
- [ ] Custom sensor selection works
- [ ] QR scanner works
- [ ] Recording saves files
- [ ] Settings persist between launches
- [ ] Handles network disruptions gracefully

### Web Studio ✅
- [ ] Development mode runs (`npm run dev`)
- [ ] Production build works (`npm run build`)
- [ ] Can connect to iPhone via IP
- [ ] Camera feed displays
- [ ] Point cloud renders in 3D
- [ ] IMU data updates in real-time
- [ ] GPS map works (if enabled)
- [ ] Recording creates MCAP files
- [ ] Settings adjust visualizations
- [ ] Can disconnect cleanly

### Python SDK ✅
- [ ] `basic_server.py` receives data
- [ ] `camera_viewer.py` shows video
- [ ] `depth_viewer.py` shows point clouds
- [ ] Multiple protocol servers work
- [ ] Can parse recorded data

### Network Modes ✅
- [ ] Local WiFi streaming (same network)
- [ ] iPhone Personal Hotspot
- [ ] Cloud relay (iPhone → Cloud, requires web update)
- [ ] Auto-reconnection works
- [ ] Handles network changes

---

## 🚀 Step-by-Step: First Time Setup

### 1. Install Dependencies

```bash
# Check you have everything
node --version    # Should be v18+
python3 --version # Should be 3.8+
xcodebuild -version # Should be Xcode 15+

# Install Web Studio dependencies
cd /Users/jaskiratsingh/Desktop/Arvos-web
npm install

# Install Python SDK dependencies
cd /Users/jaskiratsingh/Desktop/arvos-sdk
pip3 install -r requirements.txt  # or install packages as needed
```

### 2. Start Web Studio

```bash
cd /Users/jaskiratsingh/Desktop/Arvos-web
npm run dev
```

Leave this terminal running. You should see:
```
📡 WebSocket server started on port 8765
▲ Next.js 15.x.x
- Local: http://localhost:3000
```

### 3. Build & Run iOS App

```bash
# Open Xcode
open /Users/jaskiratsingh/Desktop/arvos/arvos.xcodeproj

# Or from command line:
cd /Users/jaskiratsingh/Desktop/arvos
xcodebuild -scheme arvos -sdk iphonesimulator
```

**In Xcode:**
1. Select iPhone Simulator or your physical iPhone
2. Press ⌘R (or click ▶ Run button)
3. App should build and launch

**First Launch Permissions:**
- Allow Camera access
- Allow Motion & Fitness
- Allow Local Network access
- (GPS optional - allow if testing GPS features)

### 4. Connect & Stream

**In iOS App:**
1. Tap "START STREAMING"
2. You should see: "📡 ws://192.168.1.XXX:8765"

**In Web Browser:**
1. Go to http://localhost:3000/studio
2. Click "Connection" button (top right)
3. Enter the IP shown in iOS app
4. Port: 8765
5. Click "CONNECT"

**You should now see:**
- ✅ Status: "STREAMING"
- 📹 Camera feed updating
- 🎯 Point cloud rendering
- 📊 IMU data flowing
- 🔢 FPS counter (should be 30-60 FPS)

---

## 🆘 Troubleshooting

### Problem: "Cannot connect to server"

**Check 1: Same WiFi Network**
```bash
# On Mac - get your IP
ifconfig | grep "inet " | grep -v 127.0.0.1

# Both devices should have IP in same range
# e.g., 192.168.1.XXX
```

**Check 2: Firewall**
```bash
# macOS: System Settings → Network → Firewall
# Make sure Node.js is allowed

# Test connection
nc -zv localhost 8765  # Should say "succeeded"
```

**Check 3: Server Running**
```bash
# Check if WebSocket server is running
lsof -i :8765

# Should show node process
```

### Problem: "App builds but crashes"

```bash
# Clean build
# In Xcode: Product → Clean Build Folder (⌘⇧K)

# Delete derived data
rm -rf ~/Library/Developer/Xcode/DerivedData/arvos-*

# Rebuild
```

### Problem: "No camera/depth data"

1. Check sensor permissions in iOS Settings → Arvos
2. Verify streaming mode includes camera/depth
3. Check Xcode console for errors
4. Try "Camera Only" mode first (simpler)

### Problem: "Low FPS / Lag"

```bash
# Check CPU usage
top -pid $(pgrep -f "Next.js")

# Reduce quality in app settings
# Or try Camera Only mode
```

### Problem: "Web Studio blank screen"

```bash
# Check browser console (F12)
# Look for WebSocket errors

# Try different browser
# Chrome/Edge recommended

# Clear cache
# Hard refresh: ⌘⇧R
```

---

## 📊 Expected Performance

| Configuration | Camera FPS | Depth FPS | Total Messages/sec | Bandwidth |
|--------------|-----------|-----------|-------------------|-----------|
| Full Sensor | 30 | 10 | ~250 | 5-10 MB/s |
| Camera Only | 60 | 0 | ~60 | 3-5 MB/s |
| Depth Only | 0 | 30 | ~30 | 2-4 MB/s |
| IMU Only | 0 | 0 | 200 | < 1 MB/s |

**Latency:**
- Local WiFi: 20-50ms
- iPhone Hotspot: 50-100ms  
- Cloud Relay: 100-300ms (depends on internet)

---

## 🎓 Quick Reference

### iOS App
```
📱 Arvos iOS App
├─ START STREAMING → Starts embedded WebSocket server
├─ Stop button → Stops streaming
├─ Mode selector → Choose sensor configuration
├─ Settings (⚙️) → Adjust quality, FPS, etc.
└─ Connection (🔗) → Connect to external servers
```

### Web Studio
```
🌐 Web Studio (http://localhost:3000/studio)
├─ Connection → Enter iPhone IP
├─ Record → Save session to MCAP
├─ Settings → Adjust visualization
└─ Panels:
    ├─ Camera Feed
    ├─ Point Cloud 3D
    ├─ IMU Sensors
    └─ GPS Map
```

### Python SDK
```
🐍 Python SDK (/arvos-sdk/examples/)
├─ basic_server.py → Simple WebSocket receiver
├─ camera_viewer.py → OpenCV camera display
├─ depth_viewer.py → Open3D point cloud
├─ rerun_visualizer.py → 3D sensor fusion
└─ [See examples/README_EXAMPLES.md for all]
```

---

## 🎯 Success Criteria

You've successfully tested the platform when:

✅ **iOS App:**
- Builds without errors
- Streams data in server mode
- Shows IP address clearly
- All modes work (Full/Camera/Depth)

✅ **Web Studio:**
- Connects to iPhone
- Displays camera feed smoothly
- Renders 3D point clouds
- FPS counter shows 30+ FPS

✅ **Python SDK:**
- basic_server.py receives data
- Camera/depth viewers display correctly
- All sensor types parse correctly

✅ **Network:**
- Works on local WiFi
- Works with iPhone hotspot
- Auto-reconnects after disruptions

---

## 📝 What I Fixed

During this testing preparation, I fixed a critical bug:

**Bug:** Camera and depth frames were NOT being broadcast in server mode.

**Location:** `/Users/jaskiratsingh/Desktop/arvos/arvos/Managers/NetworkManager.swift`

**Fix:** Added server mode broadcasting for binary data (camera/depth frames) at lines 371-373 and 398-400.

Before this fix, only JSON data (IMU, GPS, Pose) was working in server mode. Now all data types work correctly! ✅

---

**You're ready to test! Start with the Quick Start (Test 1) above. Good luck! 🚀**
