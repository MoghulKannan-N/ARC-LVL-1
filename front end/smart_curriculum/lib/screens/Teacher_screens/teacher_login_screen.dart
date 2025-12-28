import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_curriculum/utils/constants.dart';
import 'package:smart_curriculum/utils/animations.dart';
import 'package:smart_curriculum/screens/Teacher_screens/teacher_home_screen.dart';
import 'package:smart_curriculum/services/Teacher_service/teacher_api_service.dart'
    as teacher_api;
import 'package:smart_curriculum/services/Student_service/student_api_service.dart'
    as student_api;

class TeacherLoginScreen extends StatefulWidget {
  const TeacherLoginScreen({super.key});

  @override
  State<TeacherLoginScreen> createState() => _TeacherLoginScreenState();
}

class _TeacherLoginScreenState extends State<TeacherLoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
    ));
    _animationController.forward();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    // ===================================================
    // 🔓 LOCAL LOGIN BYPASS (NO BACKEND CALL)
    // ===================================================
    if (username == 'arc' && password == 'arc') {
      await student_api.ApiService.clearLoginState();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currentRole', 'teacher');

      setState(() => _isLoading = false);

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          SlidePageRoute(child: const TeacherHomeScreen()),
          (route) => false,
        );
      }
      return;
    }

    // ===================================================
    // 🔐 NORMAL BACKEND LOGIN
    // ===================================================
    await student_api.ApiService.clearLoginState();

    final success =
        await teacher_api.ApiService.teacherLogin(username, password);

    setState(() => _isLoading = false);

    if (success) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currentRole', 'teacher');

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const TeacherHomeScreen()),
          (route) => false,
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid credentials')),
        );
      }
    }
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
              AppColors.teacherGradientLight,
              AppColors.teacherSurface,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: isSmallScreen ? 20 : 60),

                    // Logo and Title Section
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                      decoration: BoxDecoration(
                        color: AppColors.teacherSurface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.teacherPrimary
                                .withValues(alpha: 0.15),
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
                                  AppColors.teacherGradientStart,
                                  AppColors.teacherGradientEnd
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
                              color: AppColors.textColor,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: isSmallScreen ? 4 : 8),
                          Text(
                            'Teacher Portal',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              fontWeight: FontWeight.w500,
                              color: AppColors.teacherPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: isSmallScreen ? 20 : 32),

                    // Login Form
                    TeacherCustomSurfaces.primaryCard(
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
                              'Sign in to your teacher account',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 12 : 14,
                                color: AppColors.teacherPrimary,
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 16 : 24),
                            TextFormField(
                              controller: _usernameController,
                              decoration: InputDecoration(
                                labelText: 'Username',
                                prefixIcon: Icon(Icons.person_rounded,
                                    color: AppColors.teacherPrimary),
                                filled: true,
                                fillColor: AppColors.teacherGradientLight,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: AppColors.teacherPrimary,
                                    width: 2,
                                  ),
                                ),
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
                                    color: AppColors.teacherPrimary),
                                filled: true,
                                fillColor: AppColors.teacherGradientLight,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: AppColors.teacherPrimary,
                                    width: 2,
                                  ),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: isSmallScreen ? 12 : 16),
                              ),
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Enter password'
                                  : null,
                            ),
                            SizedBox(height: isSmallScreen ? 16 : 24),
                            TeacherCustomButtons.primaryAction(
                              text: 'LOGIN',
                              onPressed: _login,
                              icon: Icons.login_rounded,
                              isLoading: _isLoading,
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
                        color: AppColors.teacherGradientLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              AppColors.teacherPrimary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.admin_panel_settings_rounded,
                            color: AppColors.teacherPrimary,
                            size: isSmallScreen ? 18 : 20,
                          ),
                          SizedBox(width: isSmallScreen ? 8 : 12),
                          Expanded(
                            child: Text(
                              'Access teacher dashboard to manage attendance and track student progress',
                              style: TextStyle(
                                color: AppColors.teacherPrimary,
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
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
