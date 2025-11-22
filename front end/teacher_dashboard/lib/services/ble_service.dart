import 'package:flutter/services.dart';

class BleService {
  static const MethodChannel _channel = MethodChannel('ble_control');

  static Future<String> startNormalSession() async {
    try {
      return await _channel.invokeMethod("startNormalSession");
    } catch (e) {
      return "Error: $e";
    }
  }

  static Future<String> stopBroadcast() async {
    try {
      return await _channel.invokeMethod("stopBroadcast");
    } catch (e) {
      return "Error: $e";
    }
  }
}
