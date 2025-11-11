# Debug Depth Visualization

## Changes Made

Added comprehensive debug logging to `DepthPointCloudView.swift` to diagnose why the depth point cloud isn't visible.

### Debug Outputs Added

1. **Depth Value Range Logging**
   ```
   🔍 Depth range: X.XXm to Y.YYm, valid points in sample: Z/100
   ```
   - Shows the min/max depth values in the first 100 pixels
   - Helps verify depth values are reasonable (typically 0.1m - 5m)
   - Shows how many valid (non-zero) depth points exist

2. **Camera Intrinsics Logging**
   ```
   🔍 Camera intrinsics fx=XXX.XX, fy=XXX.XX
   ```
   - Shows the focal lengths used for unprojection
   - Should be around 500-600 for typical iPhone cameras

3. **Draw Call Logging** (every 30 frames)
   ```
   🎨 Drawing XXXXX points at frame XX
   ```
   - Confirms Metal rendering is happening
   - Shows vertex count being rendered

4. **Guard Failure Logging**
   ```
   ❌ Draw guard failed: device=true, pipeline=true, depthSample=false, depthTexture=false
   ```
   - Shows which resources are missing if rendering fails

## Testing Instructions

1. **Open the app on a physical device** (LiDAR requires real hardware)
2. **Navigate to Sensor Test** (settings icon → Sensor Test)
3. **Start streaming** (tap Start button)
4. **Switch to "Full" renderer** (use the segmented control)
5. **Watch the Xcode console output**

## What to Look For

### Expected Console Output

```
🔍 Depth range: 0.5m to 3.2m, valid points in sample: 95/100
🔍 Camera intrinsics fx=578.45, fy=578.45
🎨 Drawing 49152 points at frame 30
🎨 Drawing 49152 points at frame 60
```

### Problem Scenarios

**If depth range shows 0.0m to 0.0m:**
- Depth data isn't reaching Metal textures
- Check ARKitService is emitting depth samples

**If valid points is 0/100:**
- All depth values are zero (no scene detected)
- Point device at visible objects with good lighting

**If no draw calls appear:**
- Rendering isn't happening
- Check pipeline state creation

**If intrinsics are 0.0:**
- Camera calibration data is missing
- ARFrame.camera.intrinsics not being passed correctly

## Known Issues

### ARFrame Retention Warning

You may see:
```
ARSession is retaining 11 ARFrames
```

This happens because:
1. `DepthVisualizationSample` holds CVPixelBuffer references
2. CVPixelBuffers keep the ARFrame alive even after copying
3. SwiftUI's update mechanism stores the sample in the ViewModel

**Solution in progress:**
- Extract Metal textures immediately
- Release CVPixelBuffers after texture creation
- Don't store samples longer than necessary

## Comparison: Test vs Full Renderer

### Test Renderer (Working ✅)
- Shows 3 colored dots (Red, Green, Blue)
- Confirms Metal pipeline is functional
- Simple hardcoded vertices

### Full Renderer (Debugging 🔍)
- Should show 49,152 depth points as 3D scene
- Uses depth buffer unprojection
- Complex transformation pipeline

## Next Steps Based on Debug Output

1. **If depth values look good but nothing renders:**
   - Problem is in unprojection or transformation math
   - Points may be outside view frustum
   - Try simplifying camera transforms

2. **If no depth data:**
   - Problem is in data pipeline
   - Check ARKitService is running
   - Verify LiDAR is available on device

3. **If intrinsics are wrong:**
   - Problem is in camera calibration
   - Check ARFrame.camera.intrinsics extraction

4. **If everything looks correct but still no visualization:**
   - Points may be too small to see (try increasing pointSize)
   - Points may be behind camera or too far away
   - Check view/projection matrix calculations

## Reference Implementation

Based on Apple's sample code:
https://developer.apple.com/documentation/arkit/displaying-a-point-cloud-using-scene-depth

Key formula:
```
position_3d = inverse(intrinsics) * [x, y, 1] * depth
world_position = cameraTransform * position_3d
```

## Files Modified

- `arvos/Views/Components/DepthPointCloudView.swift` - Added debug logging
  - Line 202-217: Depth value range logging
  - Line 114-173: Draw call logging and guard diagnostics
