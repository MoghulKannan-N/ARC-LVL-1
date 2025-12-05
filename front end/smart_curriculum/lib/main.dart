import 'package:flutter/material.dart';
import 'package:smart_curriculum/screens/Student_screens/student_login_screen.dart';
import 'package:smart_curriculum/screens/Teacher_screens/teacher_login_screen.dart';
import 'package:smart_curriculum/screens/auth/role_selection_screen.dart';
import 'package:smart_curriculum/utils/constants.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Curriculum',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: AppColors.backgroundColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
        ),
      ),

      /// 👇 The entry point for the whole app — role selection screen
      home: const RoleSelectionScreen(),
    );
  }
}
