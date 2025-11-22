// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'profile_screen.dart';
import 'bluetooth_screen.dart';
import 'ai_assistant_screen.dart';
import '../utils/constants.dart';

class HomeScreen extends StatefulWidget {
  final String studentName;

  const HomeScreen({super.key, required this.studentName});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int index = 1;

  @override
  Widget build(BuildContext context) {
    final screens = [
      ProfileScreen(studentName: widget.studentName),
      const BluetoothScreen(),
      const AIAssistantScreen()
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
          BottomNavigationBarItem(
              icon: Icon(Icons.assistant), label: "AI Assistant"),
        ],
      ),
    );
  }
}
