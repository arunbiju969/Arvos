# Arvos Foxglove-Style Testing Guide

## 🎉 IMPLEMENTATION COMPLETE!

All code is implemented and deployed. Ready for testing!

## 📱 What Was Implemented

### iOS App ✅
- **WebSocketServer** - Embedded server runs on iPhone (port 8765)
- **NetworkManager** - Server mode enabled by default  
- **SensorManager** - Auto-starts server when streaming
- **ServerStatusView** - Shows QR code + IP addresses
- **QRCodeGenerator** - Creates connection QR codes

### Web Studio ✅
- **StudioInterface** - Connects to iPhone as client
- **ConnectionPanel** - iPhone IP input (simplified)
- **Deployed to Vercel** - https://arvos-studio-l6qejdzox-jaskirat1616s-projects.vercel.app

## 🧪 HOW TO TEST

### Prerequisites
- iPhone and computer on **same WiFi network**
- OR iPhone creating **cellular hotspot** (computer connects to it)

### Step 1: Build iOS App (2 minutes)
```bash
cd /Users/jaskiratsingh/Desktop/arvos
open arvos.xcodeproj  # Opens in Xcode
# Select your iPhone device
# Click Run (Cmd+R)
```

### Step 2: Start Streaming on iPhone (1 minute)
1. Open Arvos app on iPhone
2. Select a mode (e.g., "Full Sensor" or "RGBD Camera")
3. Tap "**Start Streaming**" button
4. **QR code appears** showing connection info!
5. **Note the IP address** shown (e.g., `ws://192.168.1.100:8765`)

### Step 3: Connect Studio (1 minute)
1. Open Studio: https://arvos-studio-l6qejdzox-jaskirat1616s-projects.vercel.app/studio
2. Click "**Connect**" button
3. Enter iPhone IP: `192.168.1.100` (your iPhone's IP)
4. Click "**Connect**"
5. **Watch data flow!** 🎉

### Expected Results ✅
- iPhone shows: "**1 client(s) connected**"
- Studio shows: "**Connected**" status
- Point clouds appear in 3D viewer
- Camera frames update
- IMU data visualizes
- FPS counter updates

## 🐛 Troubleshooting

### Problem: Studio can't connect
**Check:**
- ✅ Both devices on same WiFi network?
- ✅ iPhone shows "STREAMING" status?
- ✅ Entered correct IP from iPhone QR code?
- ✅ Used `ws://` protocol (not `wss://`)?

**Solution:**
- Check iPhone IP: Settings → WiFi → (i) icon
- Disable VPN if enabled
- Try iPhone hotspot instead of WiFi

### Problem: No QR code appears
**Check:**
- ✅ Did you tap "Start Streaming"?
- ✅ Is server mode enabled?

**Solution:**
- Check console logs for "📡 Server started"
- Rebuild app from latest code

### Problem: Connection drops
**Check:**
- ✅ iPhone didn't go to sleep?
- ✅ WiFi didn't disconnect?

**Solution:**
- Keep iPhone awake during streaming
- Use iPhone hotspot for more reliable connection

## 📊 What You Should See

### On iPhone:
```
📡 Server Running

[QR CODE]

Connect Studio to:
ws://192.168.1.100:8765
ws://10.0.0.50:8765

1 client(s) connected
```

### On Studio:
```
Status: Connected ✅
FPS: 15.3
Mode: RGBD

[3D Point Cloud Viewer showing live data]
[Camera feed updating]
[IMU visualization rotating]
```

## 🚀 Next Steps After Testing

### If Everything Works:
1. ✅ Celebrate! The Foxglove architecture is working!
2. Add mDNS discovery (auto-find iPhone on network)
3. Support multiple Studio clients
4. Add recording in Studio
5. Publish to TestFlight

### If Issues Occur:
1. Check Xcode console for errors
2. Check browser console for WebSocket errors
3. Share error messages for debugging
4. Check ARCHITECTURE.md for design details

## 📖 Architecture Summary

```
OLD (Cloud Relay):
iPhone → Cloud Server ← Studio
❌ Scalability issues
❌ Cloud costs
❌ Higher latency

NEW (Foxglove):
iPhone (SERVER:8765) ← Studio (client)
✅ No scalability issues
✅ Zero cloud costs
✅ Lower latency
✅ Complete privacy
```

## 🎯 Performance Targets

- **FPS**: 10-30 fps (depending on mode)
- **Latency**: < 100ms (on same WiFi)
- **Connection Time**: < 2 seconds
- **Stability**: Should run for hours without disconnecting

## 📝 Deployment URLs

- **Studio**: https://arvos-studio-l6qejdzox-jaskirat1616s-projects.vercel.app
- **iOS**: Build from Xcode (latest commit)
- **GitHub iOS**: https://github.com/jaskirat1616/Arvos
- **GitHub Studio**: https://github.com/jaskirat1616/Arvos-web

## ✅ Testing Checklist

- [ ] Build iOS app from Xcode
- [ ] Start streaming on iPhone
- [ ] QR code appears with IP address
- [ ] Open Studio in browser
- [ ] Enter iPhone IP and connect
- [ ] See "Connected" status
- [ ] Point cloud data appears
- [ ] Camera frames update
- [ ] IMU visualization works
- [ ] Test all modes (Full Sensor, RGBD, Custom, etc.)
- [ ] Test disconnecting and reconnecting
- [ ] Test with iPhone hotspot

---

**Ready to test!** Build the app and start streaming! 🚀
