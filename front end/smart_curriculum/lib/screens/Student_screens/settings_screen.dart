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
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.settings),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView( // ✅ Prevents bottom overflow
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
                    builder: (_) =>
                        StudentFaceRegistrationScreen(studentName: studentName),
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
                    content: Text("Device Binding configuration coming soon!"),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
          ],
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
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primaryColor, size: 28),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textColor,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
