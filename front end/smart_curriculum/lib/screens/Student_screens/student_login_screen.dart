// FILE: lib/screens/Student_screens/student_login_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_curriculum/utils/constants.dart';
import 'package:smart_curriculum/screens/Student_screens/student_home_screen.dart';
import 'package:smart_curriculum/services/Student_service/student_api_service.dart'
    as student_api;
import 'package:smart_curriculum/services/Teacher_service/teacher_api_service.dart'
    as teacher_api;

class StudentLoginScreen extends StatefulWidget {
  const StudentLoginScreen({super.key});

  @override
  State<StudentLoginScreen> createState() => _StudentLoginScreenState();
}

class _StudentLoginScreenState extends State<StudentLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    // ===================================================
    // 🔓 LOCAL LOGIN BYPASS (NO BACKEND)
    // ===================================================
    if (username == 'arc' && password == 'arc') {
      // Clear teacher session to avoid role conflict
      await teacher_api.ApiService.clearLoginState();

      // Save role as student
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currentRole', 'student');

      setState(() => _isLoading = false);

      // Navigate directly to Student Home
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => StudentHomeScreen(studentName: username),
        ),
        (route) => false,
      );
      return;
    }

    // ===================================================
    // 🔐 NORMAL BACKEND LOGIN
    // ===================================================
    await teacher_api.ApiService.clearLoginState();

    final success = await student_api.ApiService.studentLogin(
      username,
      password,
    );

    setState(() => _isLoading = false);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid credentials')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currentRole', 'student');

    final studentName = student_api.ApiService.loggedInStudentName ?? username;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => StudentHomeScreen(studentName: studentName),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.gradientStart,
              AppColors.gradientEnd,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom -
                    32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: isSmallScreen ? 20 : 60),

                  // Logo and Title Section
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                    decoration: BoxDecoration(
                      color: AppColors.surfacePrimary,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryColor.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.gradientMid,
                                AppColors.gradientAccent
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.school_rounded,
                            size: isSmallScreen ? 40 : 60,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 12 : 16),
                        Text(
                          'ARC Smart Curriculum',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 18 : 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryColor,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: isSmallScreen ? 4 : 8),
                        Text(
                          'Student Portal',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.subtitleColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: isSmallScreen ? 20 : 32),

                  // Login Form
                  CustomSurfaces.primaryCard(
                    padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          Text(
                            'Welcome Back',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 18 : 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textColor,
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 4 : 8),
                          Text(
                            'Sign in to your student account',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 14,
                              color: AppColors.subtitleColor,
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 16 : 24),
                          TextFormField(
                            controller: _usernameController,
                            decoration: InputDecoration(
                              labelText: 'Username',
                              prefixIcon: Icon(Icons.person_rounded,
                                  color: AppColors.primaryColor),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: isSmallScreen ? 12 : 16),
                            ),
                            validator: (v) => v == null || v.isEmpty
                                ? 'Enter username'
                                : null,
                          ),
                          SizedBox(height: isSmallScreen ? 12 : 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(Icons.lock_rounded,
                                  color: AppColors.primaryColor),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: isSmallScreen ? 12 : 16),
                            ),
                            validator: (v) => v == null || v.isEmpty
                                ? 'Enter password'
                                : null,
                          ),
                          SizedBox(height: isSmallScreen ? 16 : 24),
                          CustomButtons.primaryAction(
                            text: 'LOGIN',
                            onPressed: _login,
                            isLoading: _isLoading,
                            icon: Icons.login_rounded,
                            width: double.infinity,
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: isSmallScreen ? 16 : 24),

                  // Info Card
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                    decoration: BoxDecoration(
                      color: AppColors.infoLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.secondaryColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: AppColors.secondaryColor,
                          size: isSmallScreen ? 18 : 20,
                        ),
                        SizedBox(width: isSmallScreen ? 8 : 12),
                        Expanded(
                          child: Text(
                            'Use your student credentials to access learning materials and track attendance',
                            style: TextStyle(
                              color: AppColors.secondaryColor,
                              fontSize: isSmallScreen ? 11 : 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: isSmallScreen ? 16 : 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
