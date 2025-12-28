import 'package:flutter/material.dart';
import 'package:smart_curriculum/utils/constants.dart';
import 'package:smart_curriculum/screens/Student_screens/student_face_registration_screen.dart';
import 'package:smart_curriculum/screens/Student_screens/bluetooth_screen.dart';

/// Settings screen for student to configure face, Bluetooth, and device binding.
class SettingsScreen extends StatelessWidget {
  final String studentName;

  const SettingsScreen({super.key, required this.studentName});

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
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(AppStrings.settings),
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.primaryColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          // ✅ Prevents bottom overflow
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              _buildSettingsOption(
                context: context,
                title: AppStrings.configureFaceRecognition,
                icon: Icons.face,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StudentFaceRegistrationScreen(
                          studentName: studentName),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildSettingsOption(
                context: context,
                title: AppStrings.configureBluetooth,
                icon: Icons.bluetooth,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const BluetoothScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildSettingsOption(
                context: context,
                title: AppStrings.configureDeviceBinding,
                icon: Icons.devices,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text("Device Binding configuration coming soon!"),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Reusable settings option card
  Widget _buildSettingsOption({
    required BuildContext context,
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.primaryColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textColor,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios,
                    size: 16, color: AppColors.subtitleColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
