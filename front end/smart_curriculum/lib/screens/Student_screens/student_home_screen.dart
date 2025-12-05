import 'package:flutter/material.dart';
import 'package:smart_curriculum/screens/Student_screens/profile_screen.dart';
import 'package:smart_curriculum/screens/Student_screens/bluetooth_screen.dart';
import 'package:smart_curriculum/screens/Student_screens/ai_assistant_screen.dart';
import 'package:smart_curriculum/utils/constants.dart';

/// Student dashboard with bottom navigation for profile, attendance, AI assistant.
class StudentHomeScreen extends StatefulWidget {
  final String studentName;

  const StudentHomeScreen({super.key, required this.studentName});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  int index = 1;

  @override
  Widget build(BuildContext context) {
    final screens = [
      ProfileScreen(studentName: widget.studentName),
      const BluetoothScreen(),
      const AIAssistantScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Dashboard"),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: screens[index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) => setState(() => index = i),
        selectedItemColor: AppColors.primaryColor,
        unselectedItemColor: AppColors.subtitleColor,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.assistant), label: "AI Assistant"),
        ],
      ),
    );
  }
}
