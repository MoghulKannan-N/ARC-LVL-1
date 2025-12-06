import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_curriculum/utils/constants.dart';
import 'package:smart_curriculum/screens/Teacher_screens/attendance_screen.dart';
import 'package:smart_curriculum/screens/Teacher_screens/quiz_screen.dart';
import 'package:smart_curriculum/screens/Teacher_screens/add_student_screen.dart';
import 'package:smart_curriculum/screens/Teacher_screens/configure_settings_screen.dart';
import 'package:smart_curriculum/services/Teacher_service/teacher_api_service.dart' as teacher_api;
import 'package:smart_curriculum/services/Student_service/student_api_service.dart' as student_api;
import 'package:smart_curriculum/screens/auth/role_selection_screen.dart';

/// 🧑‍🏫 Teacher Dashboard — main screen after successful login.
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
    QuizScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(AppStrings.appName),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
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
                  MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: _screens[_currentIndex],
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryColor,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddStudentScreen()),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: AppColors.primaryColor,
        unselectedItemColor: AppColors.subtitleColor,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_turned_in_outlined),
            label: 'Attendance',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.quiz_outlined),
            label: 'Quiz',
          ),
        ],
      ),
    );
  }
}

/// =====================================================================
/// 🏠 TEACHER HOME CONTENT
/// =====================================================================
class TeacherHomeContent extends StatelessWidget {
  const TeacherHomeContent({super.key});

  // 🔌 MethodChannel (matches Kotlin side)
  static const MethodChannel _channel = MethodChannel("student_ble");

  Future<String> _startTeacherBeacon() async {
    try {
      final res = await _channel.invokeMethod("startTeacherBeacon");
      return "✅ Beacon started successfully: $res";
    } on PlatformException catch (e) {
      return "⚠️ BLE Error: ${e.message}";
    } catch (e) {
      return "⚠️ Unknown Error: $e";
    }
  }

  void _showStudentNameDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Enter Student Name"),
        content: TextField(
          controller: nameController,
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
              final name = nameController.text.trim();

              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Enter a valid name")),
                );
                return;
              }

              Navigator.pop(context);
              bool exists = await teacher_api.ApiService.checkStudentExists(name);
              if (!exists) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Student not found")),
                );
                return;
              }

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ConfigureSettingsScreen(studentName: name),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor),
            child: const Text("Continue"),
          ),
        ],
      ),
    );
  }

  void _showSessionSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Session Type'),
        content: const Text('Choose the type of session for attendance:'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startBluetoothBeacon(context, 'Free Session');
            },
            child: const Text('Free Session'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              String result = await _startTeacherBeacon();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(result)),
              );
            },
            child: const Text('Normal Session'),
          ),
        ],
      ),
    );
  }

  void _startBluetoothBeacon(BuildContext context, String sessionType) {
    showDialog(
      context: context,
      builder: (context) => BluetoothTimerDialog(sessionType: sessionType),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 40),
          const Text(
            AppStrings.appName,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor,
            ),
          ),
          const Divider(height: 40),
          Center(
            child: GestureDetector(
              onTap: () => _showSessionSelectionDialog(context),
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryColor.withOpacity(0.4),
                      blurRadius: 10,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(Icons.bluetooth, size: 60, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Enable Bluetooth',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textColor,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Tap the Bluetooth icon to start attendance',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.subtitleColor,
            ),
          ),
          const SizedBox(height: 40),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              StatCard(title: 'Total Students', value: '0'),
              StatCard(title: 'Present Today', value: '0'),
            ],
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: () => _showStudentNameDialog(context),
            icon: const Icon(Icons.settings, color: Colors.white),
            label: const Text(
              "Configure Settings",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// =====================================================================
/// SMALL STATS CARD
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
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: AppColors.subtitleColor),
            ),
          ],
        ),
      ),
    );
  }
}

/// =====================================================================
/// BLUETOOTH TIMER DIALOG
/// =====================================================================
class BluetoothTimerDialog extends StatefulWidget {
  final String sessionType;
  const BluetoothTimerDialog({super.key, required this.sessionType});

  @override
  State<BluetoothTimerDialog> createState() => _BluetoothTimerDialogState();
}

class _BluetoothTimerDialogState extends State<BluetoothTimerDialog> {
  int _secondsRemaining = 120;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
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
    int minutes = _secondsRemaining ~/ 60;
    int seconds = _secondsRemaining % 60;

    return AlertDialog(
      title: Text('${widget.sessionType} - Bluetooth Beacon'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${widget.sessionType} beacon will run for 2 minutes'),
          const SizedBox(height: 20),
          Text(
            '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor,
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
          child: const Text('Stop Beacon'),
        ),
      ],
    );
  }
}
