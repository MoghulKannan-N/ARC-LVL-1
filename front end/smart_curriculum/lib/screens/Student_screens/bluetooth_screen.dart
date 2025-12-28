import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_curriculum/utils/constants.dart';
import 'package:smart_curriculum/screens/Student_screens/face_recognition_screen.dart';

/// Screen where students enable Bluetooth and detect teacher beacon.
class BluetoothScreen extends StatefulWidget {
  const BluetoothScreen({super.key});

  @override
  State<BluetoothScreen> createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
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
  Future<void> _handleBluetoothTap() async {
    if (!mounted) return;

    // ---------------- DEBUG MODE ----------------
    if (debugMode) {
      await _prepareAttendanceSession();

      if (mounted) {
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
      }
      return;
    }

    // ---------------- NORMAL FLOW ----------------
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("🔍 Scanning for teacher beacon...")),
      );
    }

    final bool found = await _scanForTeacher();

    if (!mounted) return;

    if (!found) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Teacher beacon not detected!")),
      );
      return;
    }

    // ✅ Teacher beacon detected → prepare session metadata
    await _prepareAttendanceSession();

    if (mounted) {
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
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.gradientStart,
            AppColors.gradientEnd,
          ],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              // Bluetooth icon button with gradient
              Center(
                child: GestureDetector(
                  onTap: _handleBluetoothTap,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.gradientMid,
                          AppColors.gradientAccent
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 20,
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

              // Status Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: const Column(
                  children: [
                    Text(
                      AppStrings.attendance,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
                    CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                    ),
                    SizedBox(height: 20),
                    Text(
                      AppStrings.waitingBluetooth,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.subtitleColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              if (debugMode) ...[
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red),
                  ),
                  child: const Text(
                    "⚠️ DEBUG MODE ENABLED — Bluetooth check skipped",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
