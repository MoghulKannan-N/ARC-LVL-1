import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_curriculum/utils/constants.dart';
import 'package:smart_curriculum/screens/Student_screens/face_recognition_screen.dart';

/// Screen where students enable Bluetooth and detect teacher beacon.
class BluetoothScreen extends StatelessWidget {
  const BluetoothScreen({super.key});

  // 🔧 Debug mode flag (set to false for production)
  static const bool debugMode = false;

  // Channel name must match the one in MainActivity.kt
  static const MethodChannel _channel = MethodChannel("student_ble");

  /// Calls the native BLE scan (Kotlin side)
  Future<bool> _scanForTeacher() async {
    try {
      final result = await _channel.invokeMethod("scanForTeacher");

      if (result == "FOUND_AND_RELAYING") {
        return true;
      } else {
        debugPrint("BLE Scan result: $result");
        return false;
      }
    } on PlatformException catch (e) {
      debugPrint("⚠️ PlatformException: ${e.message}");
      return false;
    } catch (e) {
      debugPrint("⚠️ BLE scan failed: $e");
      return false;
    }
  }

  /// Prepares frontend-only attendance session metadata (1 hour)
  /// NOTE: Monitoring is NOT started here
  Future<void> _prepareAttendanceSession() async {
    final prefs = await SharedPreferences.getInstance();

    final DateTime startTime = DateTime.now();
    final DateTime endTime = startTime.add(const Duration(hours: 1));

    await prefs.setBool('session_active', true);
    await prefs.setString('session_start_time', startTime.toIso8601String());
    await prefs.setString('session_end_time', endTime.toIso8601String());

    debugPrint("🕒 Attendance session prepared");
    debugPrint("Start: $startTime");
    debugPrint("End  : $endTime");
  }

  /// Handles Bluetooth button tap
  Future<void> _handleBluetoothTap(BuildContext context) async {
    // ---------------- DEBUG MODE ----------------
    if (debugMode) {
      await _prepareAttendanceSession();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚙️ Debug mode: Skipping Bluetooth check"),
        ),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const FaceRecognitionScreen(),
        ),
      );
      return;
    }

    // ---------------- NORMAL FLOW ----------------
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("🔍 Scanning for teacher beacon...")),
    );

    final bool found = await _scanForTeacher();

    if (!found) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Teacher beacon not detected!")),
      );
      return;
    }

    // ✅ Teacher beacon detected → prepare session metadata
    await _prepareAttendanceSession();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("✅ Teacher beacon found! Starting face recognition..."),
      ),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const FaceRecognitionScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 40),

          // Bluetooth icon button
          GestureDetector(
            onTap: () => _handleBluetoothTap(context),
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryColor.withOpacity(0.4),
                    blurRadius: 10,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.bluetooth,
                size: 60,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 30),
          const Text(
            AppStrings.enableBluetooth,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          const Text(
            'Tap the Bluetooth icon to start attendance',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.subtitleColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),

          const Text(
            AppStrings.attendance,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          const Text(
            AppStrings.waitingBluetooth,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.subtitleColor,
            ),
            textAlign: TextAlign.center,
          ),

          if (debugMode) ...[
            const SizedBox(height: 30),
            const Text(
              "⚠️ DEBUG MODE ENABLED — Bluetooth check skipped",
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
