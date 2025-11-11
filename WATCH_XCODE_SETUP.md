# Apple Watch - Xcode Project Setup Guide

## Overview

This guide walks through adding the watchOS app target to the Xcode project. The watch app code is complete and ready to be integrated into the build system.

## Prerequisites

- Xcode 15.0 or later
- macOS with watchOS SDK installed
- Apple Developer account (for device testing)
- Paired Apple Watch (for testing)

## Step-by-Step Setup

### 1. Open Project in Xcode

```bash
cd /Users/jaskiratsingh/Desktop/arvos
open arvos.xcodeproj
```

### 2. Add Watch App Target

1. **File → New → Target...**
2. Select **watchOS** tab
3. Choose **Watch App**
4. Click **Next**

**Configuration:**
- **Product Name:** `arvosWatchApp`
- **Team:** Select your team
- **Organization Identifier:** `supesclub.com`
- **Bundle Identifier:** `supesclub.com.arvos.watchkitapp`
- **Language:** Swift
- **User Interface:** SwiftUI
- **Include Notification Scene:** No
- **Embed in iOS App:** arvos

5. Click **Finish**
6. When prompted "Activate scheme?", click **Activate**

### 3. Configure Watch App Target

#### 3.1 Delete Auto-Generated Files

Xcode creates default files that we don't need:

1. In Project Navigator, expand `arvosWatchApp` group
2. Delete these auto-generated files (Move to Trash):
   - `arvosWatchAppApp.swift` (we have our own)
   - `ContentView.swift` (we have WatchContentView)
   - Any other default files

#### 3.2 Add Existing Watch App Files

1. Right-click `arvosWatchApp` target in Project Navigator
2. Select **Add Files to "arvos"...**
3. Navigate to `arvosWatchApp/` folder
4. Select all files:
   - `arvosWatchApp.swift`
   - `WatchContentView.swift`
   - `WatchSensorService.swift`
   - `Info.plist`
   - `Assets.xcassets/`
5. **Important:** Check **"Add to targets"** → `arvosWatchApp` only
6. Click **Add**

#### 3.3 Add Shared Files to Both Targets

1. Right-click project root in Project Navigator
2. Select **Add Files to "arvos"...**
3. Navigate to `Shared/` folder
4. Select all files:
   - `Models/WatchSensorPacket.swift`
   - `Services/WatchConnectivityService.swift`
5. **Important:** Check **"Add to targets"** → Both `arvos` AND `arvosWatchApp`
6. Click **Add**

### 4. Configure Build Settings

#### 4.1 Watch App Target Settings

Select `arvosWatchApp` target → **Build Settings**:

**Deployment:**
- **watchOS Deployment Target:** 9.0
- **Supported Platforms:** watchOS

**Signing:**
- **Signing & Capabilities** tab
- Enable **Automatically manage signing**
- Select your **Team**

**Info.plist:**
- Already configured in `arvosWatchApp/Info.plist`
- Verify `WKCompanionAppBundleIdentifier` = `supesclub.com.arvos`

#### 4.2 iOS App Target Settings

Select `arvos` target → **Build Settings**:

**Watch App Embedding:**
- Should automatically embed watch app
- Verify in **General** tab → **Frameworks, Libraries, and Embedded Content**
- `arvosWatchApp.app` should be listed

### 5. Add Capabilities

#### 5.1 iOS App Capabilities

Select `arvos` target → **Signing & Capabilities**:

1. Click **+ Capability**
2. Add **Background Modes**
   - Check: ☑️ Remote notifications (if not already)
3. Click **+ Capability**
4. Add **Push Notifications** (if needed)

**WatchConnectivity** doesn't require explicit capability (it's automatic)

#### 5.2 Watch App Capabilities

Select `arvosWatchApp` target → **Signing & Capabilities**:

1. Click **+ Capability**
2. Add **Background Modes**
   - Check: ☑️ Remote notifications (if needed)

**Motion Usage** is already configured in `Info.plist`

### 6. Configure Schemes

#### 6.1 Watch App Scheme

1. **Product → Scheme → Edit Scheme...**
2. Select `arvosWatchApp` scheme
3. **Run** section:
   - **Build Configuration:** Debug
   - **Executable:** arvosWatchApp.app
   - **Launch:** Automatically

#### 6.2 iOS App Scheme

1. Select `arvos` scheme
2. Verify watch app is included in build
3. **Build** section → check `arvosWatchApp` is listed

### 7. Verify File Structure

Your project should now have this structure:

```
arvos/
├── arvos/                          (iOS app - existing)
│   ├── Managers/
│   │   ├── SensorManager.swift
│   │   └── WatchSensorManager.swift  ← Updated
│   ├── Models/
│   │   └── StreamMode.swift          ← Updated
│   ├── ViewModels/
│   │   └── SensorTestViewModel.swift ← Updated
│   └── Views/
│       └── Screens/
│           ├── SensorTestView.swift  ← Updated
│           └── SettingsView.swift    ← Updated
├── arvosWatchApp/                  (Watch app - new)
│   ├── arvosWatchApp.swift
│   ├── WatchContentView.swift
│   ├── WatchSensorService.swift
│   ├── Info.plist
│   └── Assets.xcassets/
├── Shared/                         (Shared code - new)
│   ├── Models/
│   │   └── WatchSensorPacket.swift
│   └── Services/
│       └── WatchConnectivityService.swift
└── arvos.xcodeproj/
```

### 8. Build and Test

#### 8.1 Build iOS App

1. Select `arvos` scheme
2. Select iPhone device or simulator
3. **Product → Build** (⌘B)
4. Fix any compilation errors

#### 8.2 Build Watch App

1. Select `arvosWatchApp` scheme
2. Select Watch device or simulator
3. **Product → Build** (⌘B)
4. Fix any compilation errors

#### 8.3 Run on Simulator

**Note:** Watch simulator has limited sensor support. Physical devices required for full testing.

1. Select paired iPhone + Watch simulator
2. Select `arvos` scheme
3. **Product → Run** (⌘R)
4. iOS app should launch
5. Watch app should install automatically

#### 8.4 Run on Physical Devices

**Required for sensor testing:**

1. Connect iPhone via USB
2. Ensure Watch is paired and on wrist
3. Select iPhone device
4. Select `arvos` scheme
5. **Product → Run** (⌘R)
6. iOS app launches on iPhone
7. Watch app installs on Watch (may take a minute)
8. Launch watch app from watch face

### 9. Troubleshooting

#### Build Errors

**"Cannot find 'WatchSensorPacket' in scope"**
- Solution: Ensure `Shared/` files added to both targets
- Check: Target Membership in File Inspector

**"Missing required module 'WatchConnectivity'"**
- Solution: WatchConnectivity is automatic, but verify:
- iOS Deployment Target ≥ 17.6
- watchOS Deployment Target ≥ 9.0

**"Duplicate symbol"**
- Solution: Check file isn't added twice to same target
- File Inspector → Target Membership

#### Watch App Not Installing

**Watch app doesn't appear on watch:**
1. Check iPhone Watch app → My Watch → Available Apps
2. Find arvos and tap Install
3. Wait for installation (can take 1-2 minutes)
4. Check watch storage isn't full

**Watch app crashes on launch:**
1. Check Console.app for crash logs
2. Verify all files added to watch target
3. Verify Info.plist configured correctly
4. Clean build folder (⇧⌘K) and rebuild

#### Connectivity Issues

**"Watch Not Connected" in settings:**
1. Verify watch paired in iPhone Watch app
2. Check Bluetooth enabled on both devices
3. Restart both devices
4. Check console logs for WCSession errors

### 10. Verification Checklist

Before proceeding to testing:

- [ ] Both targets build without errors
- [ ] iOS app runs on simulator
- [ ] Watch app runs on simulator (limited)
- [ ] iOS app runs on physical iPhone
- [ ] Watch app installs on physical Watch
- [ ] Watch app launches successfully
- [ ] Settings shows "Watch Connected: Yes"
- [ ] Sensor Test shows watch section
- [ ] No console errors related to WatchConnectivity

### 11. Next Steps

Once Xcode setup is complete:

1. **Run Test Suite:** Follow `WATCH_TESTING_GUIDE.md`
2. **Validate Data:** Verify sensor data accuracy
3. **Performance Test:** Measure battery and latency
4. **Fix Issues:** Address any bugs found
5. **Optimize:** Tune sample rates and buffering

## Common Xcode Issues

### Issue: "Provisioning profile doesn't support WatchKit"

**Solution:**
1. Xcode → Preferences → Accounts
2. Select your team
3. Click "Download Manual Profiles"
4. Or: Create new App ID in Apple Developer portal with Watch capability

### Issue: "Watch app requires iOS app to be installed"

**Solution:**
- This is expected behavior
- Watch app automatically installs when iOS app installed
- Cannot install watch app independently

### Issue: "Code signing failed"

**Solution:**
1. Select target → Signing & Capabilities
2. Enable "Automatically manage signing"
3. Select your team
4. Xcode will create necessary certificates

### Issue: "Build fails with Swift version mismatch"

**Solution:**
1. Select both targets
2. Build Settings → Swift Language Version
3. Set to same version (Swift 5.0)

## Reference

### Bundle Identifiers
- **iOS App:** `supesclub.com.arvos`
- **Watch App:** `supesclub.com.arvos.watchkitapp`

### Deployment Targets
- **iOS:** 17.6+
- **watchOS:** 9.0+

### Required Frameworks
- **iOS:** WatchConnectivity (automatic)
- **watchOS:** WatchConnectivity, CoreMotion

### Info.plist Keys
- **Watch:** `NSMotionUsageDescription` (already configured)
- **iOS:** No additional keys required for WatchConnectivity

## Support

If you encounter issues not covered here:

1. Check Xcode console for error messages
2. Review `WATCH_INTEGRATION.md` for architecture details
3. Consult `WATCH_TESTING_GUIDE.md` for validation steps
4. Check Apple's WatchConnectivity documentation
5. Search for specific error messages

## Success Criteria

Setup is complete when:
- ✅ Both targets build successfully
- ✅ iOS app runs on device
- ✅ Watch app installs and launches
- ✅ Settings shows watch connected
- ✅ Sensor Test displays watch data
- ✅ No console errors

**Ready to proceed to testing!** 🎉

