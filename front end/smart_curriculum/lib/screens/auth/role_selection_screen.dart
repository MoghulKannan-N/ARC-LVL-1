import 'package:flutter/material.dart';
import 'package:smart_curriculum/utils/constants.dart';
import 'package:smart_curriculum/screens/Student_screens/student_login_screen.dart';
import 'package:smart_curriculum/screens/Teacher_screens/teacher_login_screen.dart';

/// First page – lets user choose their role.
/// Navigates to the respective login screens.
class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Title
              Text(
                AppStrings.appName,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Please select your role to continue",
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.subtitleColor,
                ),
              ),
              const SizedBox(height: 40),

              // Student Button
              _buildRoleButton(
                context,
                icon: Icons.school,
                label: "I'm a Student",
                color: AppColors.primaryColor,
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const StudentLoginScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // Teacher Button
              _buildRoleButton(
                context,
                icon: Icons.person_outline,
                label: "I'm a Teacher",
                color: Colors.deepOrange,
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TeacherLoginScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 40),

              Text(
                "Smart Attendance and Learning Platform",
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.subtitleColor.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Reusable role button widget
  Widget _buildRoleButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, color: Colors.white, size: 26),
      label: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        minimumSize: const Size(double.infinity, 55),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
      ),
      onPressed: onPressed,
    );
  }
}
