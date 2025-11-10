# Debug Summary - LiDAR Visualization

## Current Status

### ✅ What's Working
- ARKit session starts successfully
- LiDAR depth data is being captured
- Camera frames at 1920×1440
- Depth frames being processed (~2000-3000 points)
- Tracking state: `normal` after initialization
- Scene depth available: `true`

### ⚠️ Issues to Address

#### 1. Low Point Count (CRITICAL)
**Current:** ~2000-3000 points per frame
**Expected:** 49,152 points (256×192 full depth resolution)

**Root Cause:** The point cloud is being created on CPU in `createPointCloud()` which:
- Samples the depth map (not using every pixel)
- Filters by confidence
- Only keeps a subset of points

**Solution:** The DepthPointCloudView should be receiving the raw depth buffer and rendering ALL pixels as points in the Metal shader.

**Action Items:**
1. Verify DepthVisualizationSample is being emitted (✅ code is there)
2. Check if SensorTestViewModel is receiving it (needs debug logging)
3. Verify DepthPointCloudView is being updated
4. Check Metal texture creation from CVPixelBuffer

#### 2. Fig Capture Errors
```
<<<< FigCaptureSourceRemote >>>> Fig assert: "err == 0" at bail
(Fig) signalled err=-12710
```

**Cause:** ARKit camera initialization issues - these are iOS-level warnings
**Impact:** Minimal - system recovers and tracking becomes normal
**Action:** These are expected during ARKit initialization, can be ignored

#### 3. SLAM Initialization Warnings
```
Skipping integration due to poor slam at time: vio_initialized(0)
```

**Cause:** ARKit SLAM (Simultaneous Localization and Mapping) initializing
**Impact:** Temporary - resolves as device moves
**Action:** User needs to move device for SLAM to initialize properly

#### 4. GPS Permission Warning
```
This method can cause UI unresponsiveness if invoked on the main thread
```

**Cause:** iOS warning about checking location authorization on main thread
**Impact:** None - code already dispatches correctly
**Action:** This is an iOS system warning, can add authorization delegate

## Expected vs Actual Flow

### Expected Flow (for Metal rendering):
1. ARKit captures depth at 256×192 resolution
2. ARKitService emits DepthVisualizationSample with CVPixelBuffer
3. SensorTestViewModel receives sample
4. DepthPointCloudView creates Metal textures
5. Vertex shader processes ALL 49,152 pixels
6. Each pixel becomes a 3D point on GPU
7. Result: Dense point cloud at 30 FPS

### Actual Flow (what's happening):
1. ARKit captures depth ✅
2. ARKitService emits DepthVisualizationSample ✅ (code exists)
3. ??? SensorTestViewModel receives ??? (needs verification)
4. Old PointCloudMetalView is rendering CPU-generated points ❌
5. Result: Sparse point cloud

## Debug Steps Needed

### 1. Add Logging to SensorTestViewModel
```swift
func arKitService(_ service: ARKitService, didOutputDepthSample sample: DepthVisualizationSample) {
    print("🔍 Received depth sample: \(sample.width)×\(sample.height)")
    DispatchQueue.main.async {
        if self.showLiDAR {
            print("🔍 Updating latestDepthSample")
            self.latestDepthSample = sample
        }
    }
}
```

### 2. Add Logging to DepthPointCloudView
```swift
func updateDepthSample(_ sample: DepthVisualizationSample?) {
    guard let sample = sample, let device = device else {
        print("🔍 DepthPointCloudView: No sample or device")
        return
    }

    print("🔍 DepthPointCloudView: Creating textures for \(sample.width)×\(sample.height)")
    self.depthSample = sample
    createTexturesFromDepthSample(device: device, sample: sample)
}
```

### 3. Check SensorTestView Binding
Verify that `latestDepthSample` is properly bound to DepthPointCloudView.

## Quick Fixes

### Fix #1: Ensure Test View Uses Depth Renderer
Check that `SensorTestView` is using `DepthPointCloudView` and not `PointCloudMetalView`.

Current code (should be):
```swift
if let depthSample = viewModel.latestDepthSample {
    DepthPointCloudView(depthSample: depthSample)  // ✅ Correct
        .frame(height: 400)
} else {
    ProgressView()  // Show loading
}
```

### Fix #2: Add Print Statements
Temporarily add prints to trace the data flow:
- ARKitService when emitting sample
- ViewModel when receiving sample
- View when updating sample
- Metal view when creating textures

### Fix #3: Verify Depth Sample Dimensions
The depth map should be:
- Width: 256 pixels
- Height: 192 pixels
- Total: 49,152 pixels to render

## Performance Expectations

Once fixed:
- **Point count:** 49,152 (every depth pixel)
- **Frame rate:** 30 FPS (Metal rendering)
- **CPU usage:** <5% (GPU does the work)
- **Latency:** <16ms (real-time)

## Next Steps

1. **Add debug logging** to trace depth sample flow
2. **Verify view binding** in SensorTestView
3. **Test on device** and check console output
4. **Confirm Metal rendering** is being used
5. **Validate texture creation** from CVPixelBuffer

## Expected Console Output (when fixed)

```
🚀 Starting ARKit session
✅ Depth frame #1: 1826 points (CPU point cloud)
🔍 Received depth sample: 256×192 (Metal rendering)
🔍 Updating latestDepthSample
🔍 DepthPointCloudView: Creating textures for 256×192
✅ Metal rendering: 49152 vertices
```

This would confirm both paths are working:
- CPU point cloud (for export/processing)
- GPU Metal rendering (for visualization)
