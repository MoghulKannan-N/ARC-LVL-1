import 'package:flutter/material.dart';

class AppColors {
  // Updated color palette as specified
  static const primaryColor = Color(0xFF0F4C81); // Deep Royal Blue
  static const secondaryColor = Color(0xFF00B4D8); // Sky Blue
  static const accentColor = Color(0xFFF9C74F); // Soft Gold
  static const backgroundColor = Color(0xFFF8FAFC); // Light Clean Background
  static const cardColor = Color(0xFFFFFFFF); // Pure White
  static const textColor = Color(0xFF0F172A); // Dark Navy Text
  static const subtitleColor = Color(0xFF64748B); // Slate Gray for subtitles
  static const successColor = Color(0xFF10B981); // Emerald Green
  static const warningColor = Color(0xFFF59E0B); // Amber
  static const errorColor = Color(0xFFEF4444); // Red

  // Enhanced surface colors for visual hierarchy
  static const surfacePrimary = Color(0xFFFFFFFF); // Pure White
  static const surfaceSecondary = Color(0xFFF1F5F9); // Very Light Blue Gray
  static const surfaceTertiary = Color(0xFFE2E8F0); // Light Blue Gray
  static const surfaceAccent = Color(0xFFDEF7FF); // Very Light Sky Blue

  // Gradient colors using proper blue theme - backgrounds only
  static const gradientStart =
      Color(0xFFE3F2FD); // Very Light Blue (background only)
  static const gradientEnd = Color(0xFFBBDEFB); // Light Blue (background only)
  static const gradientMid =
      Color(0xFF2196F3); // Proper Blue (for buttons/cards)
  static const gradientAccent = Color(0xFF1976D2); // Strong Blue (for accents)

  // Teacher-specific orange gradient colors
  static const teacherPrimary = Color(0xFFFF6B35); // Vibrant Orange
  static const teacherSecondary = Color(0xFFFF8C42); // Light Orange
  static const teacherAccent = Color(0xFFFFA726); // Soft Orange
  static const teacherGradientStart = Color(0xFFFF6B35); // Vibrant Orange
  static const teacherGradientEnd = Color(0xFFFF8C42); // Light Orange
  static const teacherGradientLight = Color(0xFFFFF3E0); // Very Light Orange
  static const teacherSurface = Color(0xFFFFF8F5); // Cream Orange Background

  // Status colors with variants
  static const successLight = Color(0xFFD1FAE5); // Light Green
  static const warningLight = Color(0xFFFEF3C7); // Light Amber
  static const errorLight = Color(0xFFFEE2E2); // Light Red
  static const infoLight = Color(0xFFDEF7FF); // Light Sky Blue
}

// Custom surface widgets for visual hierarchy
class CustomSurfaces {
  static Widget primaryCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(20),
            child: child,
          ),
        ),
      ),
    );
  }

  static Widget elevatedCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(24),
            child: child,
          ),
        ),
      ),
    );
  }

  static Widget accentCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceAccent,
            AppColors.surfaceAccent.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.secondaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(20),
            child: child,
          ),
        ),
      ),
    );
  }

  static Widget statusCard({
    required Widget child,
    required Color statusColor,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.1),
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
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  statusColor.withValues(alpha: 0.05),
                  statusColor.withValues(alpha: 0.02),
                ],
              ),
            ),
            child: Padding(
              padding: padding ?? const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

// Custom button styles for primary actions
class CustomButtons {
  static Widget primaryAction({
    required String text,
    required VoidCallback onPressed,
    IconData? icon,
    bool isLoading = false,
    double? width,
  }) {
    return Container(
      width: width,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.gradientMid, AppColors.gradientAccent],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else ...[
                  if (icon != null) ...[
                    Icon(icon, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget secondaryAction({
    required String text,
    required VoidCallback onPressed,
    IconData? icon,
    double? width,
  }) {
    return Container(
      width: width,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.secondaryColor,
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: AppColors.secondaryColor, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  text,
                  style: const TextStyle(
                    color: AppColors.secondaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget circularAction({
    required IconData icon,
    required VoidCallback onPressed,
    Color? backgroundColor,
    Color? iconColor,
    double size = 64,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: backgroundColor != null
              ? [backgroundColor, backgroundColor.withValues(alpha: 0.8)]
              : [AppColors.gradientMid, AppColors.gradientAccent],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (backgroundColor ?? AppColors.primaryColor)
                .withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(size / 2),
          child: Icon(
            icon,
            color: iconColor ?? Colors.white,
            size: size * 0.4,
          ),
        ),
      ),
    );
  }
}

class AppStrings {
  // ✅ Shared constants
  static const appName = 'ARC Smart Curriculum';
  static const settings = 'Settings';
  static const emailHint = 'Enter your email';
  static const passwordHint = 'Enter your password';
  static const forgotPassword = 'Forgot Password?';

  // ✅ Student-specific
  static const login = 'Student Login';
  static const loginButton = 'LOGIN';
  static const enableBluetooth = 'Enable Bluetooth';
  static const attendance = 'Attendance';
  static const waitingBluetooth = 'Waiting to enable Bluetooth...';
  static const aiAssistant = 'AI Learning Assistant';
  static const freePeriodDetected = 'FREE PERIOD DETECTED - WORK ASSIGNED';
  static const welcome = 'Welcome';
  static const recommendedResources = 'Recommended Resources';
  static const studentProfile = 'Student Profile';
  static const personalInfo = 'Personal Information';
  static const skillsInterests = 'Skills & Interests';
  static const configureSettings = 'Configure Settings';
  static const facialRecognition = 'Facial Recognition Attendance';
  static const positionFace = '1. Position your face within the circle';
  static const ensureLighting = '2. Ensure proper lighting';
  static const stayStill = '3. Stay still until recognition completes';
  static const alignFace = 'Align your face with the circle';
  static const waitingDetection = 'Waiting for face detection...';
  static const startRecognition = 'Start Recognition';

  // Settings screen constants
  static const configureFaceRecognition = 'Configure Face Recognition';
  static const configureBluetooth = 'Configure Bluetooth';
  static const configureDeviceBinding = 'Configure Device Binding';

  // Teacher-specific constants
  static const teacherLogin = 'Teacher Login';
  static const teacherDashboard = 'Teacher Dashboard';
}

// Teacher-specific custom surface widgets with orange gradient theme
class TeacherCustomSurfaces {
  static Widget primaryCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.teacherSurface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.teacherPrimary.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: AppColors.teacherPrimary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(20),
            child: child,
          ),
        ),
      ),
    );
  }

  static Widget elevatedCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.teacherSurface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.teacherPrimary.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppColors.teacherPrimary.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(24),
            child: child,
          ),
        ),
      ),
    );
  }

  static Widget gradientCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.teacherGradientLight,
            AppColors.teacherGradientLight.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.teacherSecondary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(20),
            child: child,
          ),
        ),
      ),
    );
  }
}

// Teacher-specific custom button styles with orange gradient theme
class TeacherCustomButtons {
  static Widget primaryAction({
    required String text,
    required VoidCallback onPressed,
    IconData? icon,
    bool isLoading = false,
    double? width,
  }) {
    return Container(
      width: width,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.teacherGradientStart,
            AppColors.teacherGradientEnd
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.teacherPrimary.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else ...[
                  if (icon != null) ...[
                    Icon(icon, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget secondaryAction({
    required String text,
    required VoidCallback onPressed,
    IconData? icon,
    double? width,
  }) {
    return Container(
      width: width,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.teacherSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.teacherSecondary,
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: AppColors.teacherSecondary, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  text,
                  style: const TextStyle(
                    color: AppColors.teacherSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget circularAction({
    required IconData icon,
    required VoidCallback onPressed,
    Color? backgroundColor,
    Color? iconColor,
    double size = 64,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: backgroundColor != null
              ? [backgroundColor, backgroundColor.withValues(alpha: 0.8)]
              : [AppColors.teacherGradientStart, AppColors.teacherGradientEnd],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (backgroundColor ?? AppColors.teacherPrimary)
                .withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(size / 2),
          child: Icon(
            icon,
            color: iconColor ?? Colors.white,
            size: size * 0.4,
          ),
        ),
      ),
    );
  }
}
