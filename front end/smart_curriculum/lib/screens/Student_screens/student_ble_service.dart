import 'dart:async';
import 'package:flutter/services.dart';

class StudentBleService {
  static const MethodChannel _channel = MethodChannel('student_ble');

  static final StreamController<Map<String, dynamic>> _candidatesController =
      StreamController<Map<String, dynamic>>.broadcast();

  static bool _initialized = false;

  /// Stream of BLE candidates emitted by native Kotlin code
  static Stream<Map<String, dynamic>> get candidatesStream =>
      _candidatesController.stream;

  /// Must be called ONCE (e.g., in main())
  static void init() {
    if (_initialized) return;
    _initialized = true;

    _channel.setMethodCallHandler(_handleNativeCallback);
  }

  /// Start BLE scan
  static Future<void> startScan() async {
    await _channel.invokeMethod('startScan');
  }

  /// Stop BLE scan
  static Future<void> stopScan() async {
    await _channel.invokeMethod('stopScan');
  }

  /// Start relay AFTER backend success
  static Future<void> startRelayForSession(String sessionId) async {
    await _channel.invokeMethod('startRelay', {
      'sessionId': sessionId,
    });
  }

  /// Native → Flutter callbacks
  static Future<void> _handleNativeCallback(MethodCall call) async {
    switch (call.method) {
      case 'bleCandidateDetected':
        final Map<String, dynamic> payload =
            Map<String, dynamic>.from(call.arguments);
        _candidatesController.add(payload);
        break;

      case 'relayStarted':
        // Optional: debug hook
        break;

      default:
        break;
    }
  }

  static void dispose() {
    _candidatesController.close();
  }
}
