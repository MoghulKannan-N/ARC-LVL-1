import 'package:flutter/material.dart';
import 'package:smart_curriculum/utils/constants.dart';
import 'package:smart_curriculum/screens/Teacher_screens/teacher_face_registration_screen.dart';

class ConfigureSettingsScreen extends StatelessWidget {
  final String studentName;

  const ConfigureSettingsScreen({
    super.key,
    required this.studentName, // <-- REQUIRED, no default value
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Configure Settings"),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Settings for: $studentName",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 20),

            // Face Config
            _buildOption(
              icon: Icons.face,
              title: "Configure Face",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        FaceRegistrationScreen(studentName: studentName),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Bluetooth Config
            _buildOption(
              icon: Icons.settings_bluetooth,
              title: "Configure Bluetooth",
              onTap: () {},
            ),
            const SizedBox(height: 16),

            // Device Binding
            _buildOption(
              icon: Icons.phonelink_setup,
              title: "Configure Device Binding",
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(icon, size: 32, color: AppColors.primaryColor),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textColor,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
        onTap: onTap,
      ),
    );
  }
}
