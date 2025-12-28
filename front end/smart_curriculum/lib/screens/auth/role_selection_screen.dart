import 'package:flutter/material.dart';
import 'package:smart_curriculum/utils/constants.dart';
import 'package:smart_curriculum/screens/Student_screens/student_login_screen.dart';
import 'package:smart_curriculum/screens/Teacher_screens/teacher_login_screen.dart';

/// First page – lets user choose their role.
/// Navigates to the respective login screens.
class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

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
              AppColors.backgroundColor,
              AppColors.surfaceSecondary,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    SizedBox(height: isSmallScreen ? 40 : 60),

                    // Logo Section
                    _buildLogoSection(context, isSmallScreen),

                    SizedBox(height: isSmallScreen ? 30 : 50),

                    // Role Selection Cards
                    _buildRoleSelectionCards(context),

                    SizedBox(height: isSmallScreen ? 40 : 60),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection(BuildContext context, bool isSmallScreen) {
    final logoSize = isSmallScreen ? 80.0 : 100.0;
    final titleSize = isSmallScreen ? 20.0 : 24.0;

    return Column(
      children: [
        // Logo Container
        Container(
          height: logoSize,
          width: logoSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surfacePrimary,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryColor.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: ClipOval(
              child: Image.asset(
                'assets/logo.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.school,
                    size: logoSize * 0.6,
                    color: AppColors.primaryColor,
                  );
                },
              ),
            ),
          ),
        ),

        SizedBox(height: isSmallScreen ? 16 : 24),

        // App Title
        Text(
          AppStrings.appName,
          style: TextStyle(
            fontSize: titleSize,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryColor,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildRoleSelectionCards(BuildContext context) {
    return Column(
      children: [
        const Text(
          "Choose Your Role",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textColor,
          ),
        ),

        const SizedBox(height: 24),

        // Student Role Card
        _buildRoleCard(
          context: context,
          title: "I'm a Student",
          icon: Icons.school_rounded,
          gradientColors: const [
            AppColors.gradientMid,
            AppColors.gradientAccent
          ],
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const StudentLoginScreen(),
              ),
            );
          },
        ),

        const SizedBox(height: 16),

        // Teacher Role Card
        _buildRoleCard(
          context: context,
          title: "I'm a Teacher",
          icon: Icons.person_4_rounded,
          gradientColors: const [
            AppColors.teacherGradientStart,
            AppColors.teacherGradientEnd
          ],
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const TeacherLoginScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRoleCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      constraints: const BoxConstraints(
        minHeight: 70,
        maxHeight: 80,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.white.withValues(alpha: 0.2),
          highlightColor: Colors.white.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
