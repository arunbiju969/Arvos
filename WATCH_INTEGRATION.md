# Apple Watch Integration

## Overview

arvos now supports optional Apple Watch integration, allowing you to stream IMU sensor data from your Apple Watch alongside iPhone sensors. This enables dual-device motion tracking, wearable sensor research, and extended sensor coverage.

## Features

### Current Implementation
- **IMU Streaming**: Real-time accelerometer and gyroscope data from Apple Watch
- **WatchConnectivity**: Bidirectional communication using `WCSession`
- **Live Messaging**: Low-latency sensor packet delivery when watch is reachable
- **Background Buffering**: Automatic fallback to background transfer when live messaging unavailable
- **Time Synchronization**: Timestamp alignment between watch and phone (basic implementation)
- **Mode Integration**: Watch sensors automatically enabled in `IMU Only` and `Full Sensor` modes
- **UI Integration**: Watch status and data visualization in Sensor Test View and Settings
- **Power Management**: Configurable sample rates (default 50Hz for battery efficiency)

### Future Extensions
- Heart rate monitoring via HealthKit
- Workout session metrics (calories, distance, steps)
- GPS from watch (for phone-free tracking)
- Altitude/barometer data
- Enhanced time synchronization with NTP-style round-trip measurement

## Architecture

### Components

#### Shared Layer (`Shared/`)
- **WatchSensorPacket.swift**: Data packet format for sensor transmission
- **WatchConnectivityService.swift**: WatchConnectivity session management (iOS + watchOS)

#### Watch App (`arvosWatchApp/`)
- **arvosWatchApp.swift**: Watch app entry point
- **WatchContentView.swift**: Watch UI for streaming control
- **WatchSensorService.swift**: CoreMotion sensor capture on watch

#### iPhone Integration (`arvos/Managers/`)
- **WatchSensorManager.swift**: Watch sensor data integration on iPhone
- **SensorManager.swift**: Updated to include watch sensor pipeline

### Data Flow

```
Watch: CoreMotion → WatchSensorService → WatchSensorPacket
                                              ↓
                                    WatchConnectivityService
                                              ↓
iPhone: WatchConnectivityService → WatchSensorManager → SensorManager
                                                              ↓
                                                    NetworkManager/RecordingManager
```

## Usage

### Prerequisites
1. Paired Apple Watch with watchOS 9.0+
2. arvos Watch app installed on watch
3. Both devices on same iCloud account

### Enabling Watch Sensors

#### Via Stream Modes
Watch sensors are automatically enabled in:
- **IMU Only Mode**: Phone IMU + Watch IMU (dual-device tracking)
- **Full Sensor Mode**: All sensors including watch

#### Via Sensor Test View
1. Open **Sensor Test** from main menu
2. Enable **Apple Watch** toggle in Sensor Modules
3. Start testing
4. View real-time watch IMU data in dedicated section

#### Programmatic Control
```swift
// Check watch connectivity
let isConnected = SensorManager.shared.watchSensorManager.isWatchConnected

// Start watch streaming
SensorManager.shared.watchSensorManager.startWatchStreaming(hz: 50)

// Stop watch streaming
SensorManager.shared.watchSensorManager.stopWatchStreaming()
```

### Configuration

#### Sample Rates
- **Default**: 50 Hz (battery-friendly)
- **Maximum**: 100 Hz (watch hardware limit)
- **Recommended**: 50-100 Hz for motion tracking

#### Mode Configurations
Edit `StreamMode.swift` to customize watch sensor settings per mode:
```swift
case .imuOnly:
    return ModeConfiguration(
        // ... other sensors ...
        watchEnabled: true,
        watchHz: 50,
        // ...
    )
```

## Technical Details

### WatchConnectivity Transport

#### Live Messaging
- Used when watch is reachable (foreground apps on both devices)
- Low latency (~10-50ms)
- Ideal for real-time streaming
- Automatic retry on failure

#### Background Transfer
- Used when watch not reachable (background/inactive apps)
- Higher latency (seconds to minutes)
- Reliable delivery via `transferUserInfo`
- Automatic batching of buffered packets

#### Message Queue
- Buffer size: 1000 packets
- Overflow handling: Drop oldest 500 packets
- Flush interval: 1 second when reachable

### Time Synchronization

Current implementation uses watch monotonic timestamps directly. For production use, consider implementing:
- Round-trip time measurement
- Clock offset calculation
- Periodic re-synchronization
- NTP-style time alignment

### Data Format

#### WatchSensorPacket
```swift
struct WatchSensorPacket: Codable {
    let timestampNs: UInt64      // Nanosecond timestamp
    let sensorType: String        // "watch_imu", etc.
    let data: Data                // Encoded sensor data
}
```

#### WatchIMUData
```swift
struct WatchIMUData: Codable {
    let angularVelocity: SIMD3<Double>      // rad/s
    let linearAcceleration: SIMD3<Double>   // m/s²
    let gravity: SIMD3<Double>              // m/s²
}
```

### Network Integration

Watch IMU data is:
1. Received on iPhone via WatchConnectivity
2. Converted to standard `IMUData` format
3. Streamed to WebSocket backend (same as phone IMU)
4. Recorded to MCAP files (if recording enabled)
5. Tagged with `sensorType: "watch_imu"` for differentiation

## UI Components

### Sensor Test View
- **Watch Section**: Real-time watch IMU visualization
- **Connection Status**: Green/red indicator with connection state
- **Sample Rate**: Live Hz display
- **IMU Metrics**: Angular velocity and linear acceleration values
- **Disconnected State**: Helpful message with pairing instructions

### Settings View
- **Apple Watch Section**: Connection status and statistics
- **Watch Connected**: Yes/No with indicator
- **Watch Sample Rate**: Current Hz
- **Watch Samples**: Total sample count
- **Pairing Instructions**: Shown when disconnected

## Performance Considerations

### Battery Impact
- **Watch**: ~5-10% additional battery drain at 50Hz
- **iPhone**: Minimal impact (WatchConnectivity overhead)
- **Recommendation**: Use 50Hz for extended sessions

### Bandwidth
- **Per Sample**: ~100 bytes (JSON encoded)
- **50 Hz**: ~5 KB/s
- **100 Hz**: ~10 KB/s
- **Live Messaging Limit**: ~50-100 Hz effective throughput

### Latency
- **Live Messaging**: 10-50ms
- **Background Transfer**: Seconds to minutes
- **Recommendation**: Keep apps in foreground for real-time streaming

## Troubleshooting

### Watch Not Connecting
1. Verify watch is paired in iPhone Watch app
2. Ensure both devices signed into same iCloud account
3. Check Bluetooth is enabled on both devices
4. Restart both devices if connection fails

### Watch App Not Appearing
1. Open iPhone Watch app
2. Scroll to "Available Apps"
3. Find arvos and tap "Install"
4. Wait for installation to complete

### No Data Streaming
1. Verify watch app is in foreground
2. Check connection indicator is green
3. Restart streaming on both devices
4. Check console logs for errors

### High Latency
1. Bring both apps to foreground
2. Reduce sample rate to 50Hz
3. Check for background processes consuming resources
4. Verify strong Bluetooth connection

## Development Notes

### Adding New Watch Sensors

1. **Define Data Structure** (`Shared/Models/WatchSensorPacket.swift`):
```swift
struct WatchHeartRateData: Codable {
    let bpm: Double
    let confidence: Double
}
```

2. **Capture on Watch** (`arvosWatchApp/WatchSensorService.swift`):
```swift
func startHeartRateMonitoring() {
    // Implement HealthKit heart rate monitoring
}
```

3. **Handle on iPhone** (`arvos/Managers/WatchSensorManager.swift`):
```swift
case "watch_heart_rate":
    if let hr = packet.decodeHeartRate() {
        // Process heart rate data
    }
```

### Testing
- Use Xcode's paired watch simulator for basic testing
- Physical devices required for actual sensor data
- Test both foreground and background scenarios
- Verify data accuracy against known reference

## Known Limitations

1. **Time Sync**: Basic implementation, may drift over long sessions
2. **Sample Rate**: Limited to ~100Hz by WatchConnectivity throughput
3. **Background**: Reduced reliability when apps backgrounded
4. **Pairing**: Requires iCloud and Bluetooth, no manual pairing
5. **Sensor Access**: Limited to CoreMotion, no raw sensor access

## Future Roadmap

- [ ] Enhanced time synchronization (NTP-style)
- [ ] Heart rate monitoring (HealthKit)
- [ ] Workout metrics integration
- [ ] Watch GPS for phone-free tracking
- [ ] Altitude/barometer data
- [ ] Compression for bandwidth optimization
- [ ] Offline buffering with sync on reconnect
- [ ] Multi-watch support (research scenarios)

## References

- [WatchConnectivity Documentation](https://developer.apple.com/documentation/watchconnectivity)
- [CoreMotion on watchOS](https://developer.apple.com/documentation/coremotion)
- [HealthKit for Watch](https://developer.apple.com/documentation/healthkit)

