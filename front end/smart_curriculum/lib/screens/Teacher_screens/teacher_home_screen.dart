import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_curriculum/utils/constants.dart';
import 'package:smart_curriculum/screens/Teacher_screens/attendance_screen.dart';
import 'package:smart_curriculum/screens/Teacher_screens/configure_settings_screen.dart';
import 'package:smart_curriculum/services/Teacher_service/teacher_api_service.dart'
    as teacher_api;
import 'package:smart_curriculum/services/Student_service/student_api_service.dart'
    as student_api;
import 'package:smart_curriculum/screens/Teacher_screens/arc_stats_screen.dart';
import 'package:smart_curriculum/screens/auth/role_selection_screen.dart';

class TeacherHomeScreen extends StatefulWidget {
  const TeacherHomeScreen({super.key});

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  int _currentIndex = 1;

  final List<Widget> _screens = const [
    AttendanceScreen(),
    TeacherHomeContent(),
    ArcStatsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          _currentIndex == 0
              ? "Attendance Management"
              : _currentIndex == 2
                  ? "ARC's Stats"
                  : AppStrings.appName,
        ),
        backgroundColor: AppColors.teacherPrimary,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.teacherGradientStart,
                AppColors.teacherGradientEnd
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to log out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await teacher_api.ApiService.clearLoginState();
                await student_api.ApiService.clearLoginState();
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('currentRole');

                if (!mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const RoleSelectionScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: AppColors.teacherPrimary,
        unselectedItemColor: AppColors.subtitleColor,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_turned_in_outlined),
            label: 'Attendance',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            label: "ARC's Stats",
          ),
        ],
      ),
    );
  }
}

/// =====================================================================
/// HOME SCREEN CONTENT (RESTORED OLD UI)
/// =====================================================================

class TeacherHomeContent extends StatelessWidget {
  const TeacherHomeContent({super.key});

  static const MethodChannel _channel = MethodChannel("student_ble");

  Future<void> _startTeacherBeacon() async {
    await _channel.invokeMethod("startTeacherBeacon");
  }

  void _showSessionSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Select Session Type"),
        content: const Text("Attendance session duration: 1 hour"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (_) =>
                    const BluetoothTimerDialog(sessionType: "Free Session"),
              );
            },
            child: const Text("Free Session"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _startTeacherBeacon();
              showDialog(
                context: context,
                builder: (_) =>
                    const BluetoothTimerDialog(sessionType: "Normal Session"),
              );
            },
            child: const Text("Normal Session"),
          ),
        ],
      ),
    );
  }

  void _showStudentNameDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Enter Student Name"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: "Student Name",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(context);

              final exists =
                  await teacher_api.ApiService.checkStudentExists(name);
              if (!exists) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Student not found")),
                );
                return;
              }

              if (!context.mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ConfigureSettingsScreen(studentName: name),
                ),
              );
            },
            child: const Text("Continue"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.teacherGradientLight,
            AppColors.teacherSurface,
          ],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Center(
                child: GestureDetector(
                  onTap: () => _showSessionSelectionDialog(context),
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.teacherGradientStart,
                          AppColors.teacherGradientEnd
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color:
                              AppColors.teacherPrimary.withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.bluetooth,
                        size: 60, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Start Attendance Session",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textColor,
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  TeacherStatCard(title: "Total Students", value: "0"),
                  TeacherStatCard(title: "Present Today", value: "0"),
                ],
              ),
              const SizedBox(height: 40),
              TeacherCustomButtons.primaryAction(
                text: "Configure Settings",
                onPressed: () => _showStudentNameDialog(context),
                icon: Icons.settings,
                width: double.infinity,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// =====================================================================
/// TEACHER STATS CARD WITH ORANGE THEME
/// =====================================================================

class TeacherStatCard extends StatelessWidget {
  final String title;
  final String value;
  const TeacherStatCard({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.teacherSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.teacherPrimary.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.teacherPrimary.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.teacherPrimary)),
          const SizedBox(height: 4),
          Text(title,
              style: const TextStyle(
                  fontSize: 14, color: AppColors.subtitleColor)),
        ],
      ),
    );
  }
}

/// =====================================================================
/// STATS CARD (ORIGINAL FOR STUDENT SIDE)
/// =====================================================================

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  const StatCard({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor)),
            const SizedBox(height: 4),
            Text(title,
                style: const TextStyle(
                    fontSize: 14, color: AppColors.subtitleColor)),
          ],
        ),
      ),
    );
  }
}

/// =====================================================================
/// BLUETOOTH TIMER DIALOG (1 HOUR)
/// =====================================================================

class BluetoothTimerDialog extends StatefulWidget {
  final String sessionType;
  const BluetoothTimerDialog({super.key, required this.sessionType});

  @override
  State<BluetoothTimerDialog> createState() => _BluetoothTimerDialogState();
}

class _BluetoothTimerDialogState extends State<BluetoothTimerDialog> {
  static const int _sessionSeconds = 3600;
  late int _secondsRemaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = _sessionSeconds;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _timer?.cancel();
          Navigator.pop(context);
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final min = _secondsRemaining ~/ 60;
    final sec = _secondsRemaining % 60;

    return AlertDialog(
      backgroundColor: AppColors.teacherSurface,
      title: Text("${widget.sessionType} Active"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Attendance session duration: 1 hour"),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.teacherGradientLight,
                  AppColors.teacherGradientLight.withValues(alpha: 0.5),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}",
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.teacherPrimary,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            _timer?.cancel();
            Navigator.pop(context);
          },
          style: TextButton.styleFrom(
            foregroundColor: AppColors.teacherPrimary,
          ),
          child: const Text("End Session"),
        ),
      ],
    );
  }
}
