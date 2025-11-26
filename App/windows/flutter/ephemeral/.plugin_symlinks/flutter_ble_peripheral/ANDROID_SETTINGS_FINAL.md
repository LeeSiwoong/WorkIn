# AndroidAdvertiseSettings - Final Structure

## ✅ Structure Now Matches Android Native API

The `AndroidAdvertiseSettings` class now **directly mirrors** the Android native `BluetoothLeAdvertiser` API, providing a clean 1:1 mapping.

## 📦 Class Structure

```dart
class AndroidAdvertiseSettings {
  // Legacy advertising settings
  final AdvertiseSettings? advertiseSettings;

  // Extended advertising parameters (Android 8+)
  final AdvertiseSetParameters? advertiseSetParameters;

  // Scan response data
  final AdvertiseDataCore? advertiseResponseData;

  // Periodic advertising data (Android 8+)
  final AdvertiseDataCore? periodicAdvertiseData;

  // Periodic advertising settings
  final PeriodicAdvertiseSettings? periodicAdvertiseSettings;
}
```

## 🔄 Mapping to Android Native API

### Native Method Call Flow

```kotlin
// Android: FlutterBlePeripheralPlugin.kt

// 1. Build advertiseData (from AdvertiseDataCore in Dart)
val advertiseData: AdvertiseData.Builder = AdvertiseData.Builder()
advertiseData.addServiceUuid(...)
advertiseData.addManufacturerData(...)

// 2. Build advertiseResponseData (optional)
val advertiseResponseData: AdvertiseData.Builder? = ...

// 3. Check if using extended advertising
if (advertiseSet == true && SDK >= O) {
    // Extended advertising path

    // 4. Build advertiseSettingsSet
    val advertiseSettingsSet: AdvertisingSetParameters.Builder = ...
    advertiseSettingsSet.setConnectable(...)
    advertiseSettingsSet.setInterval(...)

    // 5. Build periodic data (optional)
    val periodicAdvertiseData: AdvertiseData.Builder? = ...
    val periodicAdvertiseSettings: PeriodicAdvertisingParameters.Builder? = ...

    // 6. Start extended advertising
    flutterBlePeripheralManager.startSet(
        advertiseData.build(),
        advertiseSettingsSet.build(),
        advertiseResponseData?.build(),
        periodicAdvertiseData?.build(),
        periodicAdvertiseSettings?.build(),
        ...
    )
} else {
    // Legacy advertising path

    // 4. Build advertiseSettings
    val advertiseSettings: AdvertiseSettings.Builder = ...
    advertiseSettings.setAdvertiseMode(...)
    advertiseSettings.setConnectable(...)

    // 5. Start legacy advertising
    flutterBlePeripheralManager.start(
        advertiseData.build(),
        advertiseSettings.build(),
        advertiseResponseData?.build(),
        ...
    )
}
```

### Dart → Kotlin Parameter Flow

| Dart Field | Sent As | Kotlin Reads | Native API |
|------------|---------|--------------|------------|
| `advertiseSettings` | Direct JSON | `arguments["advertiseMode"]`, etc. | `AdvertiseSettings.Builder` |
| `advertiseSetParameters` | Prefixed `set*` | `arguments["setconnectable"]`, etc. | `AdvertisingSetParameters.Builder` |
| `advertiseResponseData` | Prefixed `response*` | `arguments["responseserviceUuid"]`, etc. | `AdvertiseData.Builder` |
| `periodicAdvertiseData` | Prefixed `periodicData*` | `arguments["periodicDataserviceUuid"]`, etc. | `AdvertiseData.Builder` |
| `periodicAdvertiseSettings` | Prefixed `periodic*` | `arguments["periodicinterval"]`, etc. | `PeriodicAdvertisingParameters.Builder` |

## 📝 Usage Examples

### Example 1: Legacy Advertising (Pre-Android 8)

```dart
await FlutterBlePeripheral().start(
  advertiseData: AdvertiseDataCore(
    serviceUuid: "180A",
    localName: "MyDevice",
  ),
  androidSettings: AndroidAdvertiseSettings(
    advertiseSettings: AdvertiseSettings(
      advertiseMode: AdvertiseMode.advertiseModeBalanced,
      connectable: true,
      timeout: 0,
      txPowerLevel: AdvertiseTxPower.advertiseTxPowerMedium,
    ),
  ),
);
```

**Maps to Android:**
```kotlin
val advertiseData = AdvertiseData.Builder()
    .addServiceUuid(ParcelUuid(UUID.fromString("180A")))
    .build()

val advertiseSettings = AdvertiseSettings.Builder()
    .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_BALANCED)
    .setConnectable(true)
    .setTimeout(0)
    .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_MEDIUM)
    .build()

bluetoothLeAdvertiser.startAdvertising(advertiseData, advertiseSettings, callback)
```

---

### Example 2: Extended Advertising with Scan Response

```dart
await FlutterBlePeripheral().start(
  advertiseData: AndroidAdvertiseData(
    serviceUuid: "180A",
    manufacturerId: 0x004C,
    manufacturerData: Uint8List.fromList([0x01, 0x02]),
  ),
  androidSettings: AndroidAdvertiseSettings(
    advertiseSetParameters: AdvertiseSetParameters(
      connectable: true,
      interval: 160,
      primaryPhy: 1,
      txPowerLevel: txPowerHigh,
      legacyMode: false,
    ),
    advertiseResponseData: AdvertiseDataCore(
      localName: "MyDevice Response",
    ),
  ),
);
```

**Maps to Android:**
```kotlin
val advertiseData = AdvertiseData.Builder()
    .addServiceUuid(ParcelUuid(UUID.fromString("180A")))
    .addManufacturerData(0x004C, byteArrayOf(0x01, 0x02))
    .build()

val advertiseSetParameters = AdvertisingSetParameters.Builder()
    .setConnectable(true)
    .setInterval(160)
    .setPrimaryPhy(BluetoothDevice.PHY_LE_1M)
    .setTxPowerLevel(AdvertisingSetParameters.TX_POWER_HIGH)
    .setLegacyMode(false)
    .build()

val scanResponse = AdvertiseData.Builder()
    .setIncludeDeviceName(false)
    .addServiceData(...)
    .build()

bluetoothLeAdvertiser.startAdvertisingSet(
    advertiseSetParameters,
    advertiseData,
    scanResponse,
    null, // periodic settings
    null, // periodic data
    callback
)
```

---

### Example 3: Extended with Periodic Advertising

```dart
await FlutterBlePeripheral().start(
  advertiseData: AdvertiseDataCore(
    serviceUuid: "180A",
  ),
  androidSettings: AndroidAdvertiseSettings(
    advertiseSetParameters: AdvertiseSetParameters(
      connectable: false,
      interval: 160,
      txPowerLevel: txPowerMedium,
    ),
    periodicAdvertiseData: AdvertiseDataCore(
      serviceUuid: "180F",
      localName: "Periodic Data",
    ),
    periodicAdvertiseSettings: PeriodicAdvertiseSettings(
      interval: 100,
      includeTxPowerLevel: true,
    ),
  ),
);
```

**Maps to Android:**
```kotlin
val advertiseData = AdvertiseData.Builder()
    .addServiceUuid(ParcelUuid(UUID.fromString("180A")))
    .build()

val advertiseSetParameters = AdvertisingSetParameters.Builder()
    .setConnectable(false)
    .setInterval(160)
    .setTxPowerLevel(AdvertisingSetParameters.TX_POWER_MEDIUM)
    .build()

val periodicData = AdvertiseData.Builder()
    .addServiceUuid(ParcelUuid(UUID.fromString("180F")))
    .build()

val periodicParameters = PeriodicAdvertisingParameters.Builder()
    .setInterval(100)
    .setIncludeTxPower(true)
    .build()

bluetoothLeAdvertiser.startAdvertisingSet(
    advertiseSetParameters,
    advertiseData,
    null, // scan response
    periodicParameters,
    periodicData,
    callback
)
```

---

## 🎯 Key Points

### ✅ Advantages of New Structure

1. **Direct Native API Mapping**: Each Dart field corresponds exactly to an Android native parameter
2. **No Abstraction Layer**: What you see in Dart is what gets called in Kotlin
3. **Flexible**: Can use legacy OR extended advertising, not forced into one
4. **Clear Separation**: Response data, periodic data, and settings are distinct fields
5. **Type Safe**: Each parameter has its proper type and validation

### 📋 Field Decision Logic

**When to use each field:**

- **`advertiseSettings`**: Always for legacy advertising (Android < 8 or when extended not needed)
- **`advertiseSetParameters`**: For extended advertising (Android 8+) - provides more control
- **`advertiseResponseData`**: When main advertising packet is full and you need extra data in scan response
- **`periodicAdvertiseData`**: For periodic broadcasts after connection (extended only)
- **`periodicAdvertiseSettings`**: Controls periodic advertising interval and TX power

### 🔄 Automatic API Selection

The Android native code automatically chooses the API:

```kotlin
if (arguments["advertiseSet"] == true && SDK >= O) {
    // Use startAdvertisingSet() with AdvertisingSetParameters
} else {
    // Use startAdvertising() with AdvertiseSettings
}
```

This is determined by checking if `advertiseSetParameters.advertiseSet == true`.

---

## ✅ Complete Implementation

All components are now properly implemented:

- ✅ **Dart Model**: `AndroidAdvertiseSettings` with all 5 native API fields
- ✅ **JSON Serialization**: Generated `.g.dart` file
- ✅ **Flutter Bridge**: Properly prefixes parameters and sends to native
- ✅ **Kotlin Native**: Reads all parameters and builds native API objects
- ✅ **Example App**: Demonstrates correct usage
- ✅ **Documentation**: This file + migration guides

---

## 📚 Android API Reference

- [BluetoothLeAdvertiser](https://developer.android.com/reference/android/bluetooth/le/BluetoothLeAdvertiser)
- [AdvertiseSettings.Builder](https://developer.android.com/reference/android/bluetooth/le/AdvertiseSettings.Builder)
- [AdvertisingSetParameters.Builder](https://developer.android.com/reference/android/bluetooth/le/AdvertisingSetParameters.Builder)
- [PeriodicAdvertisingParameters.Builder](https://developer.android.com/reference/android/bluetooth/le/PeriodicAdvertisingParameters.Builder)
- [AdvertiseData.Builder](https://developer.android.com/reference/android/bluetooth/le/AdvertiseData.Builder)

---

## 🎉 Result

The `AndroidAdvertiseSettings` now provides a **clean, transparent, 1:1 mapping** to the Android native BLE advertising API, giving developers full control over all advertising features while maintaining type safety and clear documentation.
