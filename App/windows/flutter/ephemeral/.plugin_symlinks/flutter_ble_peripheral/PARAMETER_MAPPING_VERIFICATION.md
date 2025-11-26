# Parameter Mapping Verification: Dart ↔ Android

## ✅ AdvertiseSettings (Legacy API) - ALL MATCH

| Dart Field | JSON Key | Android Reads | Android Method | Status |
|------------|----------|---------------|----------------|--------|
| `advertiseMode` | `advertiseMode` | `arguments["advertiseMode"]` | `setAdvertiseMode(int)` | ✅ MATCH |
| `connectable` | `connectable` | `arguments["connectable"]` | `setConnectable(boolean)` | ✅ MATCH |
| `timeout` | `timeout` | `arguments["timeout"]` | `setTimeout(int)` | ✅ MATCH |
| `txPowerLevel` | `txPowerLevel` | `arguments["txPowerLevel"]` | `setTxPowerLevel(int)` | ✅ MATCH |
| `advertiseSet` | `advertiseSet` | `arguments["advertiseSet"]` | (Flag for API selection) | ✅ MATCH |

**Location in code:**
- Dart: `lib/src/platform/android/models/advertise_settings.dart`
- Android: `android/src/main/kotlin/.../FlutterBlePeripheralPlugin.kt:276-279`

---

## ⚠️ AdvertiseSetParameters (Android 8+) - ONE MISMATCH

### Dart sends with "set" prefix (line 115 in flutter_ble_peripheral.dart):
```dart
parameters['set$key'] = json[key];
```

| Dart Field | JSON Key | Dart Sends | Android Reads | Android Method | Status |
|------------|----------|------------|---------------|----------------|--------|
| `anonymous` | `anonymous` | `setanonymous` | `arguments["setanonymous"]` | `setAnonymous(boolean)` | ✅ MATCH |
| `connectable` | `connectable` | `setconnectable` | `arguments["setconnectable"]` | `setConnectable(boolean)` | ✅ MATCH |
| `includeTxPowerLevel` | `includeTxPowerLevel` | `setincludeTxPowerLevel` | `arguments["setsetIncludeTxPower"]` ❌ | `setIncludeTxPower(boolean)` | ❌ **MISMATCH** |
| `interval` | `interval` | `setinterval` | `arguments["setinterval"]` | `setInterval(int)` | ✅ MATCH |
| `legacyMode` | `legacyMode` | `setlegacyMode` | `arguments["setlegacyMode"]` | `setLegacyMode(boolean)` | ✅ MATCH |
| `primaryPhy` | `primaryPhy` | `setprimaryPhy` | `arguments["setprimaryPhy"]` | `setPrimaryPhy(int)` | ✅ MATCH |
| `scannable` | `scannable` | `setscannable` | `arguments["setscannable"]` | `setScannable(boolean)` | ✅ MATCH |
| `secondaryPhy` | `secondaryPhy` | `setsecondaryPhy` | `arguments["setsecondaryPhy"]` | `setSecondaryPhy(int)` | ✅ MATCH |
| `txPowerLevel` | `txPowerLevel` | `settxPowerLevel` | `arguments["settxPowerLevel"]` | `setTxPowerLevel(int)` | ✅ MATCH |
| `duration` | `duration` | `setduration` | `arguments["setduration"]` | (Used in startSet call) | ✅ MATCH |
| `maxExtendedAdvertisingEvents` | `maxExtendedAdvertisingEvents` | `setmaxExtendedAdvertisingEvents` | `arguments["setmaxExtendedAdvertisingEvents"]` | (Used in startSet call) | ✅ MATCH |

**Location in code:**
- Dart: `lib/src/platform/android/models/advertise_set_parameters.dart`
- Android: `android/src/main/kotlin/.../FlutterBlePeripheralPlugin.kt:197-206, 260-261`

---

## ❌ THE ISSUE

**File:** `android/src/main/kotlin/dev/steenbakker/flutter_ble_peripheral/FlutterBlePeripheralPlugin.kt:200`

```kotlin
// WRONG - expects "setsetIncludeTxPower" (double "set")
(arguments["setsetIncludeTxPower"] as Boolean?)?.let { advertiseSettingsSet.setIncludeTxPower(it) }
```

**Dart sends:** `setincludeTxPowerLevel`

**Android expects:** `setsetIncludeTxPower`

### Two Problems:
1. **Double "set" prefix** - Android has `setsetIncludeTxPower` instead of `setincludeTxPowerLevel`
2. **Different field name** - Dart uses `includeTxPowerLevel`, Android expects `IncludeTxPower`

---

## 🔧 RECOMMENDED FIX

### Option 1: Fix Android to match Dart (Recommended)

**Change line 200 in FlutterBlePeripheralPlugin.kt:**
```kotlin
// FROM:
(arguments["setsetIncludeTxPower"] as Boolean?)?.let { advertiseSettingsSet.setIncludeTxPower(it) }

// TO:
(arguments["setincludeTxPowerLevel"] as Boolean?)?.let { advertiseSettingsSet.setIncludeTxPower(it) }
```

### Option 2: Fix Dart to match Android (Breaking change)

Would require changing the Dart field name from `includeTxPowerLevel` to `setIncludeTxPower`, which is awkward and breaks existing code.

---

## ✅ AdvertiseData Fields - ALL MATCH

| Dart Field | JSON Key | Android Reads | Android Method | Status |
|------------|----------|---------------|----------------|--------|
| `serviceUuid` | `serviceUuid` | `arguments["serviceUuid"]` | `addServiceUuid(ParcelUuid)` | ✅ MATCH |
| `manufacturerId` | `manufacturerId` | `arguments["manufacturerId"]` | (Used with manufacturerData) | ✅ MATCH |
| `manufacturerData` | `manufacturerData` | `arguments["manufacturerData"]` | `addManufacturerData(int, byte[])` | ✅ MATCH |
| `serviceDataUuid` | `serviceDataUuid` | `arguments["serviceDataUuid"]` | (Used with serviceData) | ✅ MATCH |
| `serviceData` | `serviceData` | `arguments["serviceData"]` | `addServiceData(ParcelUuid, byte[])` | ✅ MATCH |
| `includeDeviceName` | `includeDeviceName` | `arguments["includeDeviceName"]` | `setIncludeDeviceName(boolean)` | ✅ MATCH |
| `transmissionPowerIncluded` | `transmissionPowerIncluded` | `arguments["transmissionPowerIncluded"]` | `setIncludeTxPowerLevel(boolean)` | ✅ MATCH |
| `serviceSolicitationUuid` | `serviceSolicitationUuid` | `arguments["serviceSolicitationUuid"]` | `addServiceSolicitationUuid(ParcelUuid)` | ✅ MATCH |

**Location in code:**
- Dart: `lib/src/core/models/advertise_data.dart` (deprecated)
- Dart: `lib/src/platform/android/models/android_advertise_data.dart` (new)
- Android: `android/src/main/kotlin/.../FlutterBlePeripheralPlugin.kt:160-173`

---

## Summary

- ✅ **AdvertiseSettings**: All 5 parameters match perfectly
- ❌ **AdvertiseSetParameters**: 10/11 parameters match, 1 mismatch (`includeTxPowerLevel`)
- ✅ **AdvertiseData**: All 8 parameters match perfectly

**Action Required:** Fix line 200 in `FlutterBlePeripheralPlugin.kt` to read `setincludeTxPowerLevel` instead of `setsetIncludeTxPower`.
