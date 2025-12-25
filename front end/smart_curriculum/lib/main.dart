import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:smart_curriculum/screens/auth/role_selection_screen.dart';
import 'package:smart_curriculum/screens/Student_screens/student_home_screen.dart';
import 'package:smart_curriculum/screens/Teacher_screens/teacher_home_screen.dart';
import 'package:smart_curriculum/utils/constants.dart';
import 'package:smart_curriculum/services/Student_service/student_api_service.dart'
    as student_api;
import 'package:smart_curriculum/services/Teacher_service/teacher_api_service.dart'
    as teacher_api;

/// 🔔 GLOBAL NOTIFICATION PLUGIN
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ---------------- NOTIFICATION INIT ----------------
  const AndroidInitializationSettings androidInit =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initSettings =
      InitializationSettings(android: androidInit);

  await flutterLocalNotificationsPlugin.initialize(initSettings);

  // ---------------- LOAD LOGIN STATE ----------------
  await student_api.ApiService.loadLoginState();
  await teacher_api.ApiService.loadLoginState();

  // 🧹 Enforce single-role login
  if (student_api.ApiService.loggedInUsername != null &&
      teacher_api.ApiService.loggedInTeacherUsername != null) {
    await student_api.ApiService.clearLoginState();
    await teacher_api.ApiService.clearLoginState();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('currentRole');
  }

  runApp(const MyApp());
}

/// 🔔 STRONG WARNING NOTIFICATION (USED FROM STUDENT HOME)
Future<void> showAttendanceWarningNotification({
  required String title,
  required String body,
}) async {
  const AndroidNotificationDetails androidDetails =
      AndroidNotificationDetails(
    'attendance_monitor_channel',
    'Attendance Monitoring',
    channelDescription: 'Attendance supervision alerts',
    importance: Importance.max,
    priority: Priority.high,
    ticker: 'Attendance Alert',
  );

  const NotificationDetails notificationDetails =
      NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.show(
    0,
    title,
    body,
    notificationDetails,
  );
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
        if (student_api.ApiService.loggedInUsername != null) {
          final name = student_api.ApiService.loggedInStudentName ??
              student_api.ApiService.loggedInUsername!;
          return StudentHomeScreen(studentName: name);
        }

        if (teacher_api.ApiService.loggedInTeacherUsername != null) {
          return const TeacherHomeScreen();
        }

        return const RoleSelectionScreen();
      }),
    );
  }
}
