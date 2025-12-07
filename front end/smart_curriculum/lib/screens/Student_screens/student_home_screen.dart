import 'package:flutter/material.dart';
import 'package:smart_curriculum/screens/Student_screens/profile_screen.dart';
import 'package:smart_curriculum/screens/Student_screens/bluetooth_screen.dart';
import 'package:smart_curriculum/screens/Student_screens/ai_assistant_screen.dart';
import 'package:smart_curriculum/utils/constants.dart';
import 'package:smart_curriculum/services/Student_service/student_api_service.dart'
    as student_api;
import 'package:smart_curriculum/services/Teacher_service/teacher_api_service.dart'
    as teacher_api;
import 'package:smart_curriculum/screens/auth/role_selection_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      const AiAssistantScreen(),
    ];

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Student Dashboard"),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                barrierDismissible: true,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  title: const Text('Logout',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  content: const Text('Are you sure you want to log out?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancel')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                      ),
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await student_api.ApiService.clearLoginState();
                await teacher_api.ApiService.clearLoginState();

                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('currentRole');

                if (!mounted) return;

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RoleSelectionScreen(),
                  ),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),

      // ✅ Safe + Orientation + AI Screen Compatible Body
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _buildAdaptiveBody(screens[index]),
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) => setState(() => index = i),
        selectedItemColor: AppColors.primaryColor,
        unselectedItemColor: AppColors.subtitleColor,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assistant),
            label: "AI Assistant",
          ),
        ],
      ),
    );
  }

  /// 🧩 Smart Wrapper: prevents overflow on rotation but skips double scroll
  Widget _buildAdaptiveBody(Widget screen) {
    // These screens usually already handle scroll internally (avoid wrapping)
    final scrollSafeScreens = [
      const BluetoothScreen().runtimeType,
      const AiAssistantScreen().runtimeType,
    ];

    if (scrollSafeScreens.contains(screen.runtimeType)) {
      return screen; // render as-is
    }

    // Wrap only non-scrollable layouts
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(child: screen),
          ),
        );
      },
    );
  }
}