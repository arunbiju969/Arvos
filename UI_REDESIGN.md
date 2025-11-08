# Arvos iOS App - Glassy UI Redesign

## What Changed

### ✅ Beautiful Minimal Design
- **Glass morphism** - Ultra-thin material with blur
- **Minimal colors** - Black background, white text, subtle accents
- **No gradients** - Clean, flat design
- **Glassy overlays** - Top and bottom bars with transparency

### ✅ Data Source Picker
- **Toggle switches** for each sensor
- **Color-coded icons** for each data type
- **Real-time preview** of active sensors
- **Apply settings** before streaming

### ✅ Removed Clutter
- ❌ No more sensor status badges (moved to picker)
- ❌ No more mode cards (simplified to toggles)
- ❌ No more busy top bar (minimal FPS indicator)
- ✅ Clean, focused interface

## New UI Elements

### Top Bar (Glassy)
```
[● Connected] [25 FPS]                    [⚙️]
```
- Minimal connection indicator
- FPS counter when streaming
- Settings button (opens data picker)

### Bottom Bar (Glassy)
```
[📷 Camera] [🔮 Depth] [📍 GPS]  <- Active sensors chips

[        ▶️ Start        ]        <- Big glassy button
```
- Active sensor chips (only when streaming)
- Large start/stop button with shadow
- Red when stopping, blue when starting

### Data Source Picker (Modal)
```
┌─────────────────────────────┐
│      📊 Data Sources        │
│  Select sensors to stream   │
│                             │
│  [📷] Camera (30 FPS)    [✓]│
│  [🔮] Depth (5 FPS)      [✓]│
│  [🎯] IMU (100 Hz)       [✓]│
│  [📍] 6DOF Pose (30 Hz)  [✓]│
│  [🗺] GPS (1 Hz)         [✓]│
│                             │
│      [    Apply    ]        │
└─────────────────────────────┘
```

## Design Principles

1. **Minimal** - Only show what's needed
2. **Glassy** - Use .ultraThinMaterial everywhere
3. **Monochrome** - White on black, minimal colors
4. **Focused** - One task at a time
5. **Clean** - No visual noise

## Color Palette

- **Background:** Black
- **Text:** White (primary), Gray (secondary)
- **Accents:**
  - Blue: Camera
  - Purple: Depth
  - Orange: IMU
  - Green: Pose
  - Red: GPS
- **Materials:** .ultraThinMaterial (0.7 opacity)

## Files Modified

- `StreamView.swift` - Completely redesigned
- `StreamView_Old.swift` - Backup of original

## Next Steps

To make this fully functional, add to `StreamingViewModel.swift`:

```swift
func updateDataSources(
    camera: Bool,
    depth: Bool,
    imu: Bool,
    pose: Bool,
    gps: Bool
) {
    // Create custom mode configuration
    var config = ModeConfiguration()
    config.cameraEnabled = camera
    config.depthEnabled = depth
    config.imuEnabled = imu
    config.poseEnabled = pose
    config.gpsEnabled = gps

    // Apply to current mode
    SensorManager.shared.applyCustomConfig(config)
}
```

## Screenshots

### Before (Busy)
- Multiple sensor badges
- Mode selection cards
- Lots of metrics
- Colorful, gradient-heavy

### After (Clean)
- Minimal top bar
- Glassy bottom controls
- Active sensors as small chips
- Monochrome with subtle accents

## Build & Run

1. Open Xcode project
2. Build and run on iPhone
3. Tap ⚙️ icon to open data source picker
4. Toggle sensors on/off
5. Tap "Apply"
6. Tap "Start" to begin streaming

The UI now matches modern iOS design patterns with glass morphism and minimal aesthetics!
