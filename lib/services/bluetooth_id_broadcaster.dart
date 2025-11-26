import 'dart:async';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'dart:typed_data';

class BluetoothIdBroadcaster {
  final String userId;
  final Duration interval;
  Timer? _timer;

  BluetoothIdBroadcaster({required this.userId, this.interval = const Duration(minutes: 5)});

  final FlutterBlePeripheral _blePeripheral = FlutterBlePeripheral();
  bool _advertising = false;

  void start() {
    _timer = Timer.periodic(interval, (_) => _broadcastId());
    _broadcastId(); // Send immediately on start
  }

  void stop() {
    _timer?.cancel();
    if (_advertising) {
      _blePeripheral.stop();
      _advertising = false;
    }
  }

  Future<void> _broadcastId() async {
    if (_advertising) {
      await _blePeripheral.stop();
      _advertising = false;
    }

    final advertisementData = AdvertiseData(
      includeDeviceName: true,
      manufacturerId: 0x1234, // 예시 제조사 코드
      manufacturerData: Uint8List.fromList(userId.codeUnits),
      serviceUuid: "0000180D-0000-1000-8000-00805F9B34FB", // 예시(Heart Rate Service)
    );

    try {
      await _blePeripheral.start(advertiseData: advertisementData);
      _advertising = true;
      print('BLE advertising user ID: $userId');
    } catch (e) {
      print('BLE advertising failed: $e');
    }
  }
}
