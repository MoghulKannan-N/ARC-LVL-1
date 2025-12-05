// lib/screens/student/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:smart_curriculum/utils/constants.dart';

class ProfileScreen extends StatelessWidget {
  final String studentName;

  const ProfileScreen({super.key, required this.studentName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Profile"),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // NO PHOTO – Just icon
            CircleAvatar(
              radius: 55,
              backgroundColor: AppColors.primaryColor.withOpacity(0.15),
              child: Icon(Icons.person,
                  size: 70, color: AppColors.primaryColor),
            ),

            const SizedBox(height: 16),

            Text(
              studentName,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: AppColors.textColor),
            ),

            const SizedBox(height: 20),

            _title("Personal Info"),
            _info("Name", studentName),
            _info("Student ID", "XXXXXXXXXXXX"),
            _info("Email", "student@email.com"),
            _info("Blood Group", "B+"),
            _info("Department", "Computer Science"),
            _info("Year", "3rd Year"),

            const SizedBox(height: 20),

            _title("Skills & Interests"),
            _info("Strengths", "Coding, Problem Solving"),
            _info("Weaknesses", "Time Management"),
            _info("Interests", "AI, Cybersecurity, Web Dev"),
            _info("Career Goal", "AI Researcher"),
          ],
        ),
      ),
    );
  }

  Widget _title(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textColor)),
      );

  Widget _info(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Text("$k: ",
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: AppColors.textColor)),
            Expanded(
                child: Text(v,
                    style: const TextStyle(color: AppColors.subtitleColor))),
          ],
        ),
      );
}
