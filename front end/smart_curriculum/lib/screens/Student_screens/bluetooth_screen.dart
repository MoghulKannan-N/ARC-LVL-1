import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_curriculum/utils/constants.dart';
import 'package:smart_curriculum/screens/Student_screens/student_face_registration_screen.dart';

/// Screen where students enable Bluetooth and detect teacher beacon.
class BluetoothScreen extends StatelessWidget {
  const BluetoothScreen({super.key});

  // 🔧 Debug mode flag (set to false for production)
  static const bool debugMode = true;

  static const MethodChannel _channel = MethodChannel("student_ble");

  /// Native BLE scanning logic (calls Kotlin)
  Future<bool> _scanForTeacher() async {
    try {
      final result = await _channel.invokeMethod("scanForTeacher");
      return result == "FOUND";
    } catch (e) {
      return false;
    }
  }

  /// Handles Bluetooth button tap
  Future<void> _handleBluetoothTap(BuildContext context) async {
    if (debugMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚙️ Debug mode: Skipping Bluetooth check")),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StudentFaceRegistrationScreen(studentName: "Demo User"),
        ),
      );
      return;
    }

    // Normal mode → perform scan
    bool found = await _scanForTeacher();

    if (!found) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Teacher beacon not detected!")),
      );
      return;
    }

    // ✅ Success → navigate
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentFaceRegistrationScreen(studentName: "Student"),
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
              child: const Icon(Icons.bluetooth, size: 60, color: Colors.white),
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
            'Tap the Bluetooth icon to start face recognition',
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
