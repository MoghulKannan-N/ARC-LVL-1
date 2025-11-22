import 'package:flutter/material.dart';
import 'package:smart_curriculum/utils/constants.dart';
import 'package:flutter/services.dart';
import 'face_recognition_screen.dart';  // keep your original

class BluetoothScreen extends StatelessWidget {
  const BluetoothScreen({super.key});

  static const MethodChannel _channel = MethodChannel("student_ble");

  Future<bool> _scanForTeacher() async {
    try {
      final result = await _channel.invokeMethod("scanForTeacher");
      return result == "FOUND";
    } catch (e) {
      return false;
    }
  }

  Future<void> _handleBluetoothTap(BuildContext context) async {
    // Start scanning using Kotlin
    bool found = await _scanForTeacher();

    if (!found) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Teacher beacon not detected!")),
      );
      return;
    }

    // On success → navigate to face recognition
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FaceRecognitionScreen()),
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
        ],
      ),
    );
  }
}