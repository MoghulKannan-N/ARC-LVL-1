import 'package:flutter/material.dart';
import 'package:smart_curriculum/utils/constants.dart';
import 'package:smart_curriculum/screens/Teacher_screens/teacher_face_registration_screen.dart';

class ConfigureSettingsScreen extends StatelessWidget {
  final String studentName;

  const ConfigureSettingsScreen({
    super.key,
    required this.studentName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // ✅ Prevents overflow when keyboard opens
      appBar: AppBar(
        title: const Text("Configure Settings"),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView( // ✅ Handles smaller screens safely
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

              // 🧠 Face Configuration Option
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

              // 🔵 Bluetooth Configuration Option
              _buildOption(
                icon: Icons.settings_bluetooth,
                title: "Configure Bluetooth",
                onTap: () {
                  _showBluetoothDialog(context);
                },
              ),
              const SizedBox(height: 16),

              // 📱 Device Binding Option
              _buildOption(
                icon: Icons.phonelink_setup,
                title: "Configure Device Binding",
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Device Binding feature coming soon!"),
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

  /// 🔧 Reusable settings option card
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

  /// ✅ Overflow-proof, lifted Bluetooth dialog
  void _showBluetoothDialog(BuildContext context) {
    final TextEditingController _controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // ✅ supports keyboard safely
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 40, // ✅ lift above bottom
            left: 24,
            right: 24,
            top: 24,
          ),
          child: SingleChildScrollView( // ✅ avoids content overflow
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🩵 Top grab bar for visual appeal
                Center(
                  child: Container(
                    height: 4,
                    width: 50,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const Text(
                  "Enter Bluetooth Device Name",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.primaryColor,
                  ),
                ),
                const SizedBox(height: 16),

                // 🔠 Input Field
                TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    labelText: "Device Name",
                    labelStyle: const TextStyle(color: AppColors.primaryColor),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                          color: AppColors.primaryColor, width: 2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide:
                          const BorderSide(color: AppColors.primaryColor),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 🧭 Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        final name = _controller.text.trim();
                        if (name.isNotEmpty) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Bluetooth set to: $name"),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      child: const Text("Save"),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }
}