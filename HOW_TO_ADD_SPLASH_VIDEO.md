# How to Add Your Splash Video

## ✅ Setup Complete!

Your app now has:
- **iPhone**: Video splash screen (8 seconds)
- **iPad**: Black splash with "ARVOS" text (2 seconds)

---

## 📹 Adding Your Video

### Step 1: Prepare Your Video

Your video should be:
- **Format**: `.mp4` (H.264 codec recommended)
- **Duration**: ~8 seconds
- **Resolution**:
  - For best quality: 1080x1920 (portrait) or 1920x1080 (landscape)
  - App will auto-scale to fit any iPhone screen
- **File name**: `splash.mp4` (exactly this name)

### Step 2: Add Video to Xcode

1. **Open Xcode**
   ```bash
   open arvos.xcodeproj
   ```

2. **Add the video file**:
   - In Xcode's left sidebar (Project Navigator), right-click on the `arvos` folder
   - Select **"Add Files to arvos..."**
   - Choose your `splash.mp4` file
   - **IMPORTANT**: Make sure these options are checked:
     - ✅ "Copy items if needed"
     - ✅ "Add to targets: arvos" (NOT arvosWatchApp)
   - Click **"Add"**

3. **Verify the video is added**:
   - You should see `splash.mp4` in the `arvos` folder in Xcode
   - Click on the file
   - In the right sidebar (File Inspector), verify "Target Membership" shows:
     - ✅ arvos
     - ❌ arvosWatchApp (should NOT be checked)

### Step 3: Test

1. **Build and run** in simulator or device
2. You should see:
   - **iPhone**: Your video plays for 8 seconds, then fades to main app
   - **iPad**: Black screen with "ARVOS" text for 2 seconds

---

## 🎬 Current Behavior

### iPhone
```
[App Launch] → [Video plays (8 sec)] → [Fade transition (0.5 sec)] → [Main App]
```

### iPad
```
[App Launch] → [Black "ARVOS" text (2 sec)] → [Fade transition (0.5 sec)] → [Main App]
```

---

## 🔧 Customization Options

### Change Video Duration

Edit `arvos/arvosApp.swift` line 27:
```swift
let duration: Double = UIDevice.current.userInterfaceIdiom == .pad ? 2.0 : 8.0
//                                                                          ↑
//                                                    Change this number (seconds)
```

### Use Different Video Filename

Edit `arvos/Views/Screens/SplashScreenView.swift` line 95:
```swift
guard let videoURL = Bundle.main.url(forResource: "splash", withExtension: "mp4") else {
//                                                    ↑              ↑
//                                           Change filename    Change extension
```

### Adjust Transition Speed

Edit `arvos/arvosApp.swift` line 29:
```swift
withAnimation(.easeOut(duration: 0.5)) {
//                              ↑
//                    Change fade duration (seconds)
```

### Enable Video Sound

Edit `arvos/Views/Screens/SplashScreenView.swift` line 101:
```swift
player?.isMuted = true  // Change to false to enable sound
```

---

## 🎨 Video Design Tips

For best results, your splash video should:

1. **Start with a fade-in** (first 0.5 sec) - smoother app launch
2. **End with a fade-out** (last 0.5 sec) - smoother transition
3. **Use black letterboxing** if aspect ratio doesn't match screen
4. **Keep file size reasonable** (<10MB) - faster app launch
5. **Export at 30fps** - smooth playback on all devices

### Recommended Export Settings (From Final Cut / Premiere / After Effects):
- **Codec**: H.264
- **Profile**: Main or High
- **Resolution**: 1080p (1920x1080)
- **Frame Rate**: 30 fps
- **Bitrate**: 5-10 Mbps (balances quality vs file size)
- **Audio**: AAC 128kbps (or none if silent)

---

## 📱 Supported Devices

### iPhone (Video Splash)
- All iPhones running iOS 16.0+
- Video auto-scales to fit:
  - iPhone SE: 1334x750
  - iPhone 14/15: 2532x1170
  - iPhone 14/15 Pro Max: 2778x1284

### iPad (Black Text Splash)
- All iPads running iOS 16.0+
- Shows simple black background with "ARVOS" text

---

## ⚠️ Troubleshooting

### Video doesn't play
1. **Check filename**: Must be exactly `splash.mp4`
2. **Check target membership**: Video must be added to `arvos` target
3. **Check console**: Look for "⚠️ Splash video not found" message
4. **Verify format**: Must be `.mp4` with H.264 codec

### Video is too large
1. **Compress the video**:
   ```bash
   ffmpeg -i your-video.mp4 -vcodec h264 -crf 23 -preset fast splash.mp4
   ```
2. **Or use lower resolution**: 720p instead of 1080p

### Video aspect ratio looks wrong
- App uses `.ignoresSafeArea()` to fill entire screen
- Use black letterboxing in your video to maintain aspect ratio
- Or crop video to match iPhone aspect ratio (9:19.5 for modern iPhones)

---

## 📁 File Structure

```
arvos/
├── arvos.xcodeproj
├── arvos/
│   ├── arvosApp.swift           ← Splash duration settings
│   ├── Views/
│   │   └── Screens/
│   │       └── SplashScreenView.swift  ← Video player code
│   └── splash.mp4               ← YOUR VIDEO GOES HERE
```

---

## ✅ Build Status

**Current Status**: ✅ **BUILD SUCCEEDED**

The app is ready to receive your video file. Just add `splash.mp4` to the project and you're done!

---

## 🎯 Next Steps

1. Export your 8-second splash video as `splash.mp4`
2. Add it to Xcode using the steps above
3. Build and test on a device/simulator
4. Adjust timing if needed

**Note**: Without the video file, the app will show a fallback "ARVOS" text on iPhone (same as iPad) until you add your video.
