# Apple Watch Integration - Testing & Validation Guide

## Test Environment Setup

### Requirements
- iPhone with iOS 17.6+ running arvos
- Apple Watch with watchOS 9.0+ running arvos Watch app
- Devices paired via iPhone Watch app
- Same iCloud account on both devices
- Bluetooth enabled on both devices

### Initial Setup
1. Build and install iOS app on iPhone
2. Build and install Watch app on Apple Watch (via Xcode or iPhone Watch app)
3. Verify both apps launch successfully
4. Confirm WatchConnectivity session activates (check console logs)

## Test Cases

### 1. Pairing & Connectivity

#### TC1.1: Watch Pairing Detection
**Steps:**
1. Launch arvos on iPhone
2. Navigate to Settings
3. Scroll to "Apple Watch" section

**Expected:**
- "Watch Connected: Yes" with green indicator
- Watch sample rate displayed (0 Hz when not streaming)
- Watch samples count visible

**Validation:**
- [ ] Connection status accurate
- [ ] UI updates when watch paired/unpaired
- [ ] No crashes when watch disconnected

#### TC1.2: Reachability Changes
**Steps:**
1. Start streaming on iPhone
2. Background arvos Watch app
3. Foreground arvos Watch app
4. Observe connection indicator

**Expected:**
- Indicator changes between connected/disconnected
- Buffering activates when backgrounded
- Live messaging resumes when foregrounded

**Validation:**
- [ ] Reachability state accurate
- [ ] Smooth transition between modes
- [ ] No data loss during transitions

### 2. Sensor Streaming

#### TC2.1: Start/Stop Streaming
**Steps:**
1. Open Sensor Test view
2. Enable "Apple Watch" toggle
3. Tap "Start Testing"
4. Observe watch section
5. Tap "Stop Testing"

**Expected:**
- Watch section shows "Waiting for watch data…"
- IMU data appears within 1-2 seconds
- Sample rate displays ~50 Hz
- Data stops when testing stopped

**Validation:**
- [ ] Streaming starts successfully
- [ ] Data appears in UI
- [ ] Sample rate reasonable (45-55 Hz)
- [ ] Clean stop without errors

#### TC2.2: Data Accuracy
**Steps:**
1. Start watch streaming
2. Perform known motions (rotate, shake, tilt)
3. Observe IMU values in watch section
4. Compare with phone IMU values

**Expected:**
- Angular velocity changes with rotation
- Linear acceleration changes with motion
- Gravity vector points down (~9.81 m/s²)
- Values reasonable for motion performed

**Validation:**
- [ ] Angular velocity responds to rotation
- [ ] Acceleration responds to motion
- [ ] Gravity vector correct orientation
- [ ] No NaN or infinite values

#### TC2.3: Sample Rate Configuration
**Steps:**
1. Start streaming at 50 Hz (default)
2. Observe sample rate in UI
3. Stop and restart at 100 Hz
4. Observe sample rate changes

**Expected:**
- 50 Hz: ~45-55 Hz actual
- 100 Hz: ~90-110 Hz actual
- Higher Hz = more CPU/battery usage

**Validation:**
- [ ] Sample rate configurable
- [ ] Actual rate matches target (±10%)
- [ ] No crashes at max rate

### 3. Mode Integration

#### TC3.1: IMU Only Mode
**Steps:**
1. Select "IMU Only" mode
2. Start streaming
3. Check Settings → Apple Watch

**Expected:**
- Watch streaming starts automatically
- Watch IMU data flows to backend
- Phone IMU also active

**Validation:**
- [ ] Watch auto-enabled in IMU mode
- [ ] Both IMUs streaming simultaneously
- [ ] Data tagged correctly (phone vs watch)

#### TC3.2: Full Sensor Mode
**Steps:**
1. Select "Full Sensor" mode
2. Start streaming
3. Verify all sensors active

**Expected:**
- Camera, depth, IMU, pose, GPS, watch all active
- Watch section shows data
- No performance degradation

**Validation:**
- [ ] Watch included in full mode
- [ ] All sensors streaming
- [ ] Frame rates maintained

#### TC3.3: Mode Without Watch
**Steps:**
1. Select "RGBD Camera" mode (watch disabled)
2. Start streaming
3. Check watch section

**Expected:**
- Watch streaming not started
- Watch section shows disconnected state
- Other sensors work normally

**Validation:**
- [ ] Watch respects mode configuration
- [ ] No errors when watch disabled
- [ ] Mode works as expected

### 4. Network Integration

#### TC4.1: WebSocket Streaming
**Steps:**
1. Connect to WebSocket backend
2. Start watch streaming
3. Monitor backend logs
4. Verify watch IMU packets received

**Expected:**
- Watch IMU packets arrive at backend
- Tagged with `sensorType: "watch_imu"`
- Timestamps in nanoseconds
- Format matches phone IMU

**Validation:**
- [ ] Backend receives watch data
- [ ] Packet format correct
- [ ] Timestamps reasonable
- [ ] No parsing errors

#### TC4.2: Recording to MCAP
**Steps:**
1. Enable recording
2. Start streaming with watch
3. Record for 30 seconds
4. Stop and check MCAP file

**Expected:**
- MCAP file contains watch IMU topic
- Timestamps sequential
- Data integrity maintained
- File size reasonable

**Validation:**
- [ ] Watch data recorded
- [ ] MCAP format valid
- [ ] Timestamps monotonic
- [ ] Playback works

### 5. UI/UX

#### TC5.1: Sensor Test View
**Steps:**
1. Open Sensor Test
2. Enable watch toggle
3. Start testing
4. Observe watch section

**Expected:**
- Watch section appears
- Connection indicator accurate
- IMU values update in real-time
- Layout responsive

**Validation:**
- [ ] UI renders correctly
- [ ] Values update smoothly
- [ ] No layout issues
- [ ] Disconnected state clear

#### TC5.2: Settings View
**Steps:**
1. Open Settings
2. Navigate to Apple Watch section
3. Start/stop streaming
4. Observe statistics update

**Expected:**
- Connection status updates
- Sample rate changes live
- Sample count increments
- Instructions clear when disconnected

**Validation:**
- [ ] Statistics accurate
- [ ] Updates in real-time
- [ ] Instructions helpful
- [ ] No UI glitches

### 6. Error Handling

#### TC6.1: Watch Disconnection During Streaming
**Steps:**
1. Start streaming
2. Turn off watch or move out of range
3. Observe behavior

**Expected:**
- Connection indicator turns red
- Buffering activates
- No crashes
- Graceful degradation

**Validation:**
- [ ] Handles disconnection gracefully
- [ ] No crashes or errors
- [ ] Reconnects when available
- [ ] Data integrity maintained

#### TC6.2: Watch App Not Installed
**Steps:**
1. Unpair watch or uninstall watch app
2. Try to start streaming
3. Check UI feedback

**Expected:**
- Settings shows "Watch Not Connected"
- Sensor Test shows disconnected state
- Helpful instructions displayed
- No crashes

**Validation:**
- [ ] Detects missing watch app
- [ ] Clear user feedback
- [ ] No crashes
- [ ] Instructions actionable

#### TC6.3: Buffer Overflow
**Steps:**
1. Start streaming
2. Background both apps
3. Wait 5+ minutes
4. Foreground apps

**Expected:**
- Buffer limits enforced (1000 packets)
- Oldest packets dropped on overflow
- No memory leaks
- Smooth recovery

**Validation:**
- [ ] Buffer size limited
- [ ] No memory issues
- [ ] Recovers gracefully
- [ ] Logs overflow event

### 7. Performance

#### TC7.1: Battery Impact
**Steps:**
1. Charge both devices to 100%
2. Stream for 1 hour at 50 Hz
3. Check battery levels

**Expected:**
- Watch: 5-10% drain
- iPhone: <5% additional drain
- No overheating
- Reasonable for use case

**Validation:**
- [ ] Battery drain acceptable
- [ ] No thermal issues
- [ ] Sustainable for sessions

#### TC7.2: Latency
**Steps:**
1. Start streaming in foreground
2. Perform sharp motion
3. Observe delay in UI
4. Check backend timestamps

**Expected:**
- UI latency: <100ms
- Backend latency: <200ms
- Timestamps align with motion
- No significant drift

**Validation:**
- [ ] Latency acceptable
- [ ] Timestamps accurate
- [ ] No noticeable lag

#### TC7.3: Throughput
**Steps:**
1. Stream at 100 Hz for 5 minutes
2. Monitor packet delivery rate
3. Check for dropped packets

**Expected:**
- ~90-100 packets/second delivered
- <5% packet loss
- Stable throughput
- No degradation over time

**Validation:**
- [ ] Throughput meets target
- [ ] Low packet loss
- [ ] Stable over time

### 8. Edge Cases

#### TC8.1: Rapid Start/Stop
**Steps:**
1. Start streaming
2. Immediately stop
3. Repeat 10 times rapidly

**Expected:**
- No crashes
- Clean state transitions
- Resources properly released
- No memory leaks

**Validation:**
- [ ] Handles rapid toggling
- [ ] No resource leaks
- [ ] State consistent

#### TC8.2: Multiple Mode Switches
**Steps:**
1. Start in IMU Only mode
2. Switch to Full Sensor
3. Switch to RGBD Camera
4. Switch back to IMU Only

**Expected:**
- Watch enabled/disabled per mode
- Smooth transitions
- No orphaned connections
- State always consistent

**Validation:**
- [ ] Mode switches clean
- [ ] Watch state correct
- [ ] No lingering connections

#### TC8.3: Background/Foreground Cycling
**Steps:**
1. Start streaming
2. Background iPhone app
3. Background Watch app
4. Foreground both
5. Repeat 5 times

**Expected:**
- Buffering activates/deactivates
- Data continues flowing
- No crashes
- Reconnects reliably

**Validation:**
- [ ] Handles app lifecycle
- [ ] Data integrity maintained
- [ ] Reliable reconnection

## Automated Testing

### Unit Tests
```swift
// Test WatchSensorPacket encoding/decoding
func testWatchSensorPacketCoding()

// Test WatchConnectivityService message queue
func testMessageQueueBuffering()

// Test WatchSensorManager delegate calls
func testWatchSensorManagerDelegates()
```

### Integration Tests
```swift
// Test end-to-end data flow
func testWatchToPhoneDataFlow()

// Test mode configuration
func testModeWatchIntegration()

// Test network streaming
func testWatchDataNetworkStreaming()
```

## Validation Checklist

### Functionality
- [ ] Watch pairing detected correctly
- [ ] Sensor streaming works
- [ ] Data accuracy verified
- [ ] Mode integration functional
- [ ] Network streaming operational
- [ ] Recording to MCAP works

### UI/UX
- [ ] Sensor Test view complete
- [ ] Settings view informative
- [ ] Connection status clear
- [ ] Error messages helpful
- [ ] Layout responsive

### Performance
- [ ] Battery impact acceptable
- [ ] Latency reasonable
- [ ] Throughput sufficient
- [ ] No memory leaks
- [ ] Stable over time

### Reliability
- [ ] Handles disconnections
- [ ] Recovers from errors
- [ ] No crashes observed
- [ ] Data integrity maintained
- [ ] Edge cases handled

### Documentation
- [ ] WATCH_INTEGRATION.md complete
- [ ] Code comments adequate
- [ ] API documented
- [ ] Examples provided
- [ ] Troubleshooting guide helpful

## Sign-Off

**Tester:** ___________________  
**Date:** ___________________  
**Build:** ___________________  
**Devices:** ___________________  

**Overall Status:** [ ] Pass [ ] Fail [ ] Needs Work

**Notes:**
_______________________________________________
_______________________________________________
_______________________________________________

