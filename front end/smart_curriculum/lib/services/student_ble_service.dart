import 'package:flutter/services.dart';

class StudentBleService {
  static const _channel = MethodChannel("student_ble");

  static Future<bool> scanForTeacher() async {
    try {
      final result = await _channel.invokeMethod("scanForTeacher");
      return result == "FOUND";
    } catch (e) {
      return false;
    }
  }
}