import 'package:flutter/material.dart';
import 'package:smart_curriculum/utils/constants.dart';
import 'package:smart_curriculum/services/Student_service/student_api_service.dart';

class ProfileScreen extends StatefulWidget {
  final String studentName;
  final int? studentId;

  const ProfileScreen({
    super.key,
    required this.studentName,
    this.studentId,
  });

  @override
  State<ProfileScreen> createState() => ProfileScreenState();
}

/// ✅ GLOBAL KEY
final GlobalKey<ProfileScreenState> profileScreenKey =
    GlobalKey<ProfileScreenState>();

class ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController dobController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController strengthController = TextEditingController();
  final TextEditingController weaknessController = TextEditingController();
  final TextEditingController interestController = TextEditingController();
  final TextEditingController yearController = TextEditingController();
  final TextEditingController courseController = TextEditingController();

  bool _isLoading = true;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void toggleEdit() {
    if (_isEditing) {
      _saveProfile();
    } else {
      setState(() => _isEditing = true);
    }
  }

  // --------------------------------------------------
  // LOAD PROFILE
  // --------------------------------------------------
  Future<void> _loadProfile() async {
    if (widget.studentId == null) {
      setState(() => _isLoading = false);
      return;
    }

    final data = await ApiService.fetchFullProfileById(widget.studentId!);
    if (data != null) {
      setState(() {
        dobController.text = data["dateOfBirth"] ?? "";
        phoneController.text = data["phoneNumber"] ?? "";

        // ✅ UPDATED FIELD NAMES
        strengthController.text = data["strengths"] ?? "";
        weaknessController.text = data["weaknesses"] ?? "";
        interestController.text = data["interests"] ?? "";

        yearController.text = data["yearOfStudying"] ?? "";
        courseController.text = data["course"] ?? "";
      });
    }
    setState(() => _isLoading = false);
  }

  // --------------------------------------------------
  // SAVE PROFILE
  // --------------------------------------------------
  Future<void> _saveProfile() async {
    final updatedData = {
      "studentName": widget.studentName,
      "dateOfBirth": dobController.text,
      "phoneNumber": phoneController.text,

      // ✅ UPDATED FIELD NAMES
      "strengths": strengthController.text,
      "weaknesses": weaknessController.text,
      "interests": interestController.text,

      "yearOfStudying": yearController.text,
      "course": courseController.text,
    };

    final success =
        await ApiService.updateFullProfile(widget.studentName, updatedData);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? "Profile updated successfully!"
                : "Failed to update profile.",
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }

    setState(() {
      _isEditing = false;
    });
  }

  @override
  void dispose() {
    dobController.dispose();
    phoneController.dispose();
    strengthController.dispose();
    weaknessController.dispose();
    interestController.dispose();
    yearController.dispose();
    courseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: MediaQuery.of(context).size.height,
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
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    return Container(
      height: MediaQuery.of(context).size.height,
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
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Avatar
              CircleAvatar(
                radius: 55,
                backgroundColor: Colors.white.withValues(alpha: 0.9),
                child: const Icon(
                  Icons.person,
                  size: 70,
                  color: AppColors.primaryColor,
                ),
              ),

              const SizedBox(height: 16),

              // Name
              Text(
                widget.studentName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: AppColors.textColor,
                ),
              ),

              const SizedBox(height: 30),

              _editableField("Date of Birth", dobController),
              _editableField("Phone Number", phoneController),

              const SizedBox(height: 20),

              _editableField("Strengths", strengthController),
              _editableField("Weaknesses", weaknessController),
              _editableField("Interests", interestController),

              const SizedBox(height: 20),

              _editableField("Year of Studying", yearController),
              _editableField("Course", courseController),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _editableField(
    String label,
    TextEditingController controller,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        enabled: _isEditing,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: _isEditing
              ? Colors.white.withValues(alpha: 0.9)
              : Colors.white.withValues(alpha: 0.3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
