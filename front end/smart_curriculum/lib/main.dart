import 'package:flutter/material.dart';
import 'package:smart_curriculum/screens/auth/role_selection_screen.dart';
import 'package:smart_curriculum/screens/Student_screens/student_home_screen.dart';
import 'package:smart_curriculum/screens/Teacher_screens/teacher_home_screen.dart';
import 'package:smart_curriculum/utils/constants.dart';
import 'package:smart_curriculum/services/Student_service/student_api_service.dart'
    as student_api;
import 'package:smart_curriculum/services/Teacher_service/teacher_api_service.dart'
    as teacher_api;
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load saved login state for both student and teacher
  await student_api.ApiService.loadLoginState();
  await teacher_api.ApiService.loadLoginState();

  // 🧹 Enforce single-role login: if both logged in, clear both
  if (student_api.ApiService.loggedInUsername != null &&
      teacher_api.ApiService.loggedInTeacherUsername != null) {
    await student_api.ApiService.clearLoginState();
    await teacher_api.ApiService.clearLoginState();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('currentRole');
  }

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

      /// 🧠 Choose startup screen
      home: Builder(builder: (context) {
        // Prefer student if logged in
        if (student_api.ApiService.loggedInUsername != null) {
          final name = student_api.ApiService.loggedInStudentName ??
              student_api.ApiService.loggedInUsername!;
          return StudentHomeScreen(studentName: name);
        }

        // Else if teacher logged in
        if (teacher_api.ApiService.loggedInTeacherUsername != null) {
          return const TeacherHomeScreen();
        }

        // Default → Role Selection
        return const RoleSelectionScreen();
      }),
    );
  }
}
