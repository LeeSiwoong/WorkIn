# Android Parameter Audit - Missing Fields & Mismatches

## 🔍 Complete Parameter Comparison

### Main AdvertiseData (No Prefix)

| Android Native Reads | Dart Model Has | Match? | Notes |
|---------------------|----------------|--------|-------|
| `manufacturerData` + `manufacturerId` | ✅ `AndroidAdvertiseData` | ✅ | |
| `serviceData` + `serviceDataUuid` | ✅ `AndroidAdvertiseData` | ✅ | |
| `serviceSolicitationUuid` | ✅ `AndroidAdvertiseData` | ✅ | Android 12+ |
| `serviceUuid` | ✅ `AdvertiseDataCore` | ✅ | |
| `includeDeviceName` | ✅ `AndroidAdvertiseData` | ✅ | |
| `transmissionPowerIncluded` | ❌ `includePowerLevel` | ⚠️ | **NAME MISMATCH** |

---

### Response Data (Prefix: `response`)

| Android Native Reads | Dart Sends | Match? | Notes |
|---------------------|------------|--------|-------|
| `responsemanufacturerData` + `responsemanufacturerId` | ❌ | ❌ | **MISSING** from AdvertiseDataCore |
| `responseserviceData` + `responseserviceDataUuid` | ❌ | ❌ | **MISSING** from AdvertiseDataCore |
| `responseserviceSolicitationUuid` | ❌ | ❌ | **MISSING** from AdvertiseDataCore |
| `responseserviceUuid` | ✅ `serviceUuid` | ✅ | From AdvertiseDataCore |
| `responseincludeDeviceName` | ❌ | ❌ | **MISSING** from AdvertiseDataCore |
| `responsetransmissionPowerIncluded` | ❌ | ❌ | **MISSING** from AdvertiseDataCore |

---

### Periodic Advertise Data (Prefix: `periodic` + `periodicData`)

| Android Native Reads | Dart Sends | Match? | Notes |
|---------------------|------------|--------|-------|
| `periodicmanufacturerData` + `periodicManufacturerId` | ❌ | ❌ | **MISSING** - User mentioned! |
| `periodicserviceData` + `periodicserviceDataUuid` | ❌ | ❌ | **MISSING** |
| `periodicserviceSolicitationUuid` | ❌ | ❌ | **MISSING** - User mentioned! |
| `periodicserviceUuid` | ✅ `serviceUuid` | ✅ | From AdvertiseDataCore |
| `periodicincludeDeviceName` | ❌ | ❌ | **MISSING** |
| `periodictransmissionPowerIncluded` | ❌ | ❌ | **MISSING** |

---

### Periodic Settings (Prefix: `periodicsettings`)

| Android Native Reads | Dart Model Has | Match? | Notes |
|---------------------|----------------|--------|-------|
| `periodicsettingstransmissionPowerIncluded` | ❌ `includeTxPowerLevel` | ⚠️ | **NAME MISMATCH** |
| `periodicsettingsinterval` | ✅ `interval` | ✅ | |

---

## 📊 Summary of Issues

### ❌ Missing Fields

**Problem**: `AdvertiseDataCore` is too minimal. It only has:
- `serviceUuid` / `serviceUuids`
- `localName`

But Android's `AdvertiseData.Builder` supports ALL these fields:
- ✅ `serviceUuid`
- ❌ `manufacturerData` + `manufacturerId`
- ❌ `serviceData` + `serviceDataUuid`
- ❌ `serviceSolicitationUuid`
- ❌ `includeDeviceName`
- ❌ `transmissionPowerIncluded`

**Impact**: When using `advertiseResponseData` or `periodicAdvertiseData` with `AdvertiseDataCore`, you can only set service UUIDs and local name. You cannot set manufacturer data, service data, etc.

---

### ⚠️ Field Name Mismatches

| Dart Name | Android Reads | Should Be |
|-----------|---------------|-----------|
| `includePowerLevel` | `transmissionPowerIncluded` | Rename to match |
| `includeTxPowerLevel` (periodic settings) | `transmissionPowerIncluded` | Rename to match |

---

## 🔧 Recommended Fixes

### Option 1: Extend AdvertiseDataCore (Breaking Change)

Add all Android AdvertiseData fields to `AdvertiseDataCore`:

```dart
class AdvertiseDataCore {
  final String? serviceUuid;
  final List<String>? serviceUuids;
  final String? localName;

  // Add these:
  final int? manufacturerId;
  final Uint8List? manufacturerData;
  final String? serviceDataUuid;
  final List<int>? serviceData;
  final String? serviceSolicitationUuid;
  final bool includeDeviceName;
  final bool transmissionPowerIncluded; // Renamed!
}
```

**Pros**: One model for all advertise data
**Cons**: Not truly "core" anymore, Android-centric

---

### Option 2: Use AndroidAdvertiseData Everywhere (Recommended)

Change `AndroidAdvertiseSettings` to accept `AndroidAdvertiseData` instead of `AdvertiseDataCore`:

```dart
class AndroidAdvertiseSettings {
  final AdvertiseSettings? advertiseSettings;
  final AdvertiseSetParameters? advertiseSetParameters;

  // Change these from AdvertiseDataCore to AndroidAdvertiseData:
  final AndroidAdvertiseData? advertiseResponseData;
  final AndroidAdvertiseData? periodicAdvertiseData;

  final PeriodicAdvertiseSettings? periodicAdvertiseSettings;
}
```

**Pros**: All Android fields available
**Cons**: Can't use core model for response/periodic data

---

### Option 3: Create Comprehensive AdvertiseData Base Class

```dart
// Full featured base class
class AdvertiseData {
  final String? serviceUuid;
  final List<String>? serviceUuids;
  final String? localName;
  final int? manufacturerId;
  final Uint8List? manufacturerData;
  final String? serviceDataUuid;
  final List<int>? serviceData;
  final String? serviceSolicitationUuid;
  final bool includeDeviceName;
  final bool transmissionPowerIncluded;
}

// Simple core for cross-platform
class AdvertiseDataCore extends AdvertiseData {
  AdvertiseDataCore({
    String? serviceUuid,
    String? localName,
  }) : super(
    serviceUuid: serviceUuid,
    localName: localName,
    includeDeviceName: false,
    transmissionPowerIncluded: false,
  );
}

// Full Android version
class AndroidAdvertiseData extends AdvertiseData {
  // Has all fields
}
```

---

## 🎯 Immediate Actions Required

### 1. Fix Field Name Mismatches

**In AndroidAdvertiseData:**
```dart
// CHANGE:
final bool includePowerLevel;

// TO:
final bool transmissionPowerIncluded;
```

**In Android native code:**
```kotlin
// CHANGE:
(arguments["transmissionPowerIncluded"] as Boolean?)?.let {
    advertiseData.setIncludeTxPowerLevel(it)
}
```

**In PeriodicAdvertiseSettings:**
```dart
// CHANGE:
final bool? includeTxPowerLevel;

// TO:
final bool? transmissionPowerIncluded;
```

**In Android native code (already correct):**
```kotlin
(arguments["periodicsettingstransmissionPowerIncluded"] as Boolean?)?.let {
    periodicAdvertiseDataSettings.setIncludeTxPower(it)
}
```

---

### 2. Add Missing Fields to Models

Either extend `AdvertiseDataCore` OR change `AndroidAdvertiseSettings` to use `AndroidAdvertiseData` for response and periodic data.

---

## 📝 Current Dart → Android Flow

### Dart sends:
```dart
androidSettings: AndroidAdvertiseSettings(
  advertiseResponseData: AdvertiseDataCore(
    serviceUuid: "180A",
    // Can't set manufacturerData here!
  ),
)
```

### Flutter code prefixes with "response":
```dart
parameters['responseserviceUuid'] = "180A"
// Missing: responsemanufacturerData, etc.
```

### Android reads:
```kotlin
(arguments["responsemanufacturerData"] as ByteArray?)?.let { ... }
// This is NEVER set!
```

**Result**: Manufacturer data, service data, and other fields are ignored for response and periodic data.
