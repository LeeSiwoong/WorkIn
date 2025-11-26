# Platform Settings Migration Guide

## Overview

The plugin has been refactored to properly separate cross-platform advertising data from platform-specific settings. This provides better type safety, clearer API boundaries, and access to platform-specific features.

## What Changed

### Old Structure (Deprecated)

Previously, `AdvertiseData` mixed Android-specific fields with cross-platform fields:

```dart
final advertiseData = AdvertiseData(
  serviceUuid: "180A",
  localName: "MyDevice",           // iOS/Windows
  manufacturerId: 0x004C,           // Android only
  manufacturerData: data,           // Android only
  includeDeviceName: true,          // Android only
  includePowerLevel: true,          // Android only
  serviceSolicitationUuid: "180F",  // Android only
);
```

### New Structure

Now we have:

1. **`AdvertiseDataCore`** - Core cross-platform fields
2. **`AndroidAdvertiseData`** - Android-specific fields (extends core)
3. **`DarwinAdvertiseSettings`** - iOS/macOS-specific settings
4. **`WindowsAdvertiseSettings`** - Windows-specific settings

## Platform-Specific Features

### Cross-Platform (`AdvertiseDataCore`)

Fields supported on all platforms:

```dart
final coreData = AdvertiseDataCore(
  serviceUuid: "180A",      // Primary service UUID
  serviceUuids: ["180A", "180F"],  // Multiple UUIDs (iOS full support)
  localName: "MyDevice",    // Broadcast name
);
```

### Android (`AndroidAdvertiseData`)

Extends `AdvertiseDataCore` with Android-specific features:

```dart
final androidData = AndroidAdvertiseData(
  // Core fields
  serviceUuid: "180A",
  localName: "MyDevice",

  // Android-specific
  manufacturerId: 0x004C,
  manufacturerData: Uint8List.fromList([0x01, 0x02, 0x03]),
  serviceDataUuid: "180F",
  serviceData: [0x64],  // Battery level 100%
  includeDeviceName: true,
  includePowerLevel: true,
  serviceSolicitationUuid: "180F",  // Android 12+
);

// Use with AdvertiseSettings for power/mode control
final settings = AdvertiseSettings(
  advertiseMode: AdvertiseMode.advertiseModeBalanced,
  txPowerLevel: AdvertiseTxPower.advertiseTxPowerMedium,
  connectable: true,
  timeout: 0,
);
```

### iOS/macOS (`DarwinAdvertiseSettings`)

Apple-specific advertising options:

```dart
final darwinSettings = DarwinAdvertiseSettings(
  // Manufacturer data (company ID embedded in data)
  manufacturerData: Uint8List.fromList([
    0x4C, 0x00,  // Apple Inc. manufacturer ID (little-endian)
    0x01, 0x02, 0x03,  // Custom data
  ]),

  // Service data dictionary
  serviceData: {
    "180F": Uint8List.fromList([0x64]),  // Battery: 100%
    "180A": Uint8List.fromList([0x01, 0x02]),
  },

  // Overflow UUIDs (for scan response)
  overflowServiceUuids: ["1234", "5678"],

  // Solicited services (faster discovery)
  solicitedServiceUuids: ["180F"],

  // Connectable mode
  isConnectable: true,  // false = beacon mode

  // Show alert if Bluetooth is off
  showPowerAlert: true,

  // Background state restoration
  restoreIdentifier: "com.yourapp.peripheral",
);
```

**Key iOS Features:**

- **`manufacturerData`**: Company ID in first 2 bytes (little-endian), then data
- **`serviceData`**: Dictionary mapping service UUIDs to data
- **`overflowServiceUuids`**: UUIDs that don't fit in main packet
- **`solicitedServiceUuids`**: Services you want to connect to
- **`isConnectable`**: Set to `false` for beacon-only mode
- **`restoreIdentifier`**: Required for background advertising

### Windows (`WindowsAdvertiseSettings`)

Windows-specific advertising options:

```dart
final windowsSettings = WindowsAdvertiseSettings(
  // Manufacturer data
  manufacturerId: 0x004C,  // Company ID
  manufacturerData: Uint8List.fromList([0x01, 0x02, 0x03]),

  // Advertisement flags
  flags: 0x06,  // LE General Discoverable + BR/EDR Not Supported

  // Extended advertisement format
  useExtendedAdvertisement: true,

  // Transmission power
  preferredTransmitPowerLevel: 0,  // 0 dBm
  includeTxPower: true,
);
```

**Key Windows Features:**

- **`flags`**: Control discoverability mode (0x02 = general discoverable)
- **`useExtendedAdvertisement`**: Enable extended format (Windows 10 1809+)
- **`preferredTransmitPowerLevel`**: Hint for TX power in dBm
- **`includeTxPower`**: Include power level in advertisement

## Migration Examples

### Example 1: Simple Cross-Platform Advertising

**Old:**
```dart
await FlutterBlePeripheral().start(
  advertiseData: AdvertiseData(
    serviceUuid: "180A",
    localName: "MyDevice",
  ),
);
```

**New:**
```dart
await FlutterBlePeripheral().start(
  advertiseData: AdvertiseDataCore(
    serviceUuid: "180A",
    localName: "MyDevice",
  ),
);
```

### Example 2: Android with Manufacturer Data

**Old:**
```dart
await FlutterBlePeripheral().start(
  advertiseData: AdvertiseData(
    serviceUuid: "180A",
    manufacturerId: 0x004C,
    manufacturerData: Uint8List.fromList([0x01, 0x02]),
    includeDeviceName: true,
  ),
  advertiseSettings: AdvertiseSettings(
    advertiseMode: AdvertiseMode.advertiseModeBalanced,
  ),
);
```

**New:**
```dart
await FlutterBlePeripheral().start(
  advertiseData: AndroidAdvertiseData(
    serviceUuid: "180A",
    manufacturerId: 0x004C,
    manufacturerData: Uint8List.fromList([0x01, 0x02]),
    includeDeviceName: true,
  ),
  advertiseSettings: AdvertiseSettings(
    advertiseMode: AdvertiseMode.advertiseModeBalanced,
  ),
);
```

### Example 3: Platform-Specific Code

Use conditional imports or platform checks:

```dart
import 'dart:io' show Platform;
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';

Future<void> startAdvertising() async {
  if (Platform.isAndroid) {
    await FlutterBlePeripheral().start(
      advertiseData: AndroidAdvertiseData(
        serviceUuid: "180A",
        manufacturerId: 0x004C,
        manufacturerData: Uint8List.fromList([0x01, 0x02]),
        includeDeviceName: true,
      ),
      advertiseSettings: AdvertiseSettings(
        advertiseMode: AdvertiseMode.advertiseModeBalanced,
        connectable: true,
      ),
    );
  } else if (Platform.isIOS || Platform.isMacOS) {
    await FlutterBlePeripheral().start(
      advertiseData: AdvertiseDataCore(
        serviceUuid: "180A",
        serviceUuids: ["180A", "180F"],
        localName: "MyDevice",
      ),
      darwinSettings: DarwinAdvertiseSettings(
        manufacturerData: Uint8List.fromList([
          0x4C, 0x00,  // Apple manufacturer ID
          0x01, 0x02,
        ]),
        serviceData: {
          "180F": Uint8List.fromList([0x64]),  // Battery
        },
        isConnectable: true,
        showPowerAlert: true,
      ),
    );
  } else if (Platform.isWindows) {
    await FlutterBlePeripheral().start(
      advertiseData: AdvertiseDataCore(
        serviceUuid: "180A",
        localName: "MyDevice",
      ),
      windowsSettings: WindowsAdvertiseSettings(
        manufacturerId: 0x004C,
        manufacturerData: Uint8List.fromList([0x01, 0x02]),
        flags: 0x06,
      ),
    );
  }
}
```

## API Updates Needed

### `FlutterBlePeripheral.start()` Method

The `start()` method needs to be updated to accept the new platform-specific settings:

```dart
Future<FlutterBleBluetoothState> start({
  // Accept any subclass of AdvertiseDataCore
  required AdvertiseDataCore advertiseData,

  // Platform-specific settings
  AdvertiseSettings? advertiseSettings,
  AdvertiseSetParameters? advertiseSetParameters,
  DarwinAdvertiseSettings? darwinSettings,
  WindowsAdvertiseSettings? windowsSettings,

  // For advanced scenarios
  AdvertiseDataCore? advertiseResponseData,
  AdvertiseDataCore? advertisePeriodicData,
  PeriodicAdvertiseSettings? periodicAdvertiseSettings,
})
```

### Platform Implementation Updates

#### iOS/macOS (Swift)

The Darwin implementation needs to be updated to use `DarwinAdvertiseSettings`:

```swift
// In FlutterBlePeripheralPlugin.swift
private func startPeripheral(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    let map = call.arguments as? [String: Any]

    // Parse core data
    let advertiseData = FlutterBlePeripheralData(
        uuid: map?["serviceUuid"] as? String,
        localName: map?["localName"] as? String,
        uuids: map?["serviceUuids"] as? [String]
    )

    // Parse Darwin settings
    var advertisementData: [String: Any] = [:]

    // Add service UUIDs
    if let uuids = advertiseData.uuids {
        advertisementData[CBAdvertisementDataServiceUUIDsKey] = uuids.map { CBUUID(string: $0) }
    } else if let uuid = advertiseData.uuid {
        advertisementData[CBAdvertisementDataServiceUUIDsKey] = [CBUUID(string: uuid)]
    }

    // Add local name
    if let localName = advertiseData.localName {
        advertisementData[CBAdvertisementDataLocalNameKey] = localName
    }

    // Add Darwin-specific settings
    if let manufacturerData = map?["manufacturerData"] as? FlutterStandardTypedData {
        advertisementData[CBAdvertisementDataManufacturerDataKey] = manufacturerData.data
    }

    if let serviceData = map?["serviceData"] as? [String: Any] {
        var cbServiceData: [CBUUID: Data] = [:]
        for (uuid, data) in serviceData {
            if let typedData = data as? FlutterStandardTypedData {
                cbServiceData[CBUUID(string: uuid)] = typedData.data
            }
        }
        advertisementData[CBAdvertisementDataServiceDataKey] = cbServiceData
    }

    if let solicitedUuids = map?["solicitedServiceUuids"] as? [String] {
        advertisementData[CBAdvertisementDataSolicitedServiceUUIDsKey] =
            solicitedUuids.map { CBUUID(string: $0) }
    }

    if let isConnectable = map?["isConnectable"] as? Bool {
        advertisementData[CBAdvertisementDataIsConnectable] = NSNumber(value: isConnectable)
    }

    flutterBlePeripheralManager.start(advertiseData: advertisementData)
    result(nil)
}
```

#### Windows (C++)

The Windows implementation needs to be updated similarly.

## Benefits of New Structure

1. **Type Safety**: Platform-specific fields are only available on their respective platforms
2. **Better IDE Support**: Auto-completion shows only relevant fields for each platform
3. **Clear Documentation**: Each platform's features are documented separately
4. **Easier Maintenance**: Platform-specific code is isolated
5. **Feature Parity**: iOS and Windows now have proper settings classes like Android
6. **Future-Proof**: Easy to add new platform-specific features without breaking others

## Backward Compatibility

The old `AdvertiseData` class is still available but marked as deprecated. It will continue to work for existing code, but new code should use the platform-specific classes.

## Next Steps

1. Review the new model classes
2. Update the `start()` method signature in `FlutterBlePeripheral`
3. Update platform implementations (Swift, Kotlin, C++) to handle new settings
4. Update example app to demonstrate new API
5. Update documentation and README
6. Consider adding factory constructors for common use cases
