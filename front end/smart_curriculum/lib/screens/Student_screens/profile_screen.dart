import 'package:flutter/material.dart';
import 'package:smart_curriculum/utils/constants.dart';
import 'package:smart_curriculum/services/Student_service/student_api_service.dart';

/// ✅ GLOBAL KEY (required by StudentHomeScreen)
final GlobalKey<_ProfileScreenState> profileScreenKey =
    GlobalKey<_ProfileScreenState>();

class ProfileScreen extends StatefulWidget {
  final String studentName;

  const ProfileScreen({
    super.key,
    required this.studentName,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController dobController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController strengthController = TextEditingController();
  final TextEditingController weaknessController = TextEditingController();
  final TextEditingController interestController = TextEditingController();
  final TextEditingController yearController = TextEditingController();
  final TextEditingController courseController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  /// ✅ CALLED FROM StudentHomeScreen FAB
  void toggleEdit() {
    if (_isEditing) {
      _saveProfile();
    } else {
      setState(() => _isEditing = true);
    }
  }

  Future<void> _loadProfile() async {
    final data = await ApiService.fetchFullProfile(widget.studentName);
    if (data != null) {
      setState(() {
        dobController.text = data["dateOfBirth"] ?? "";
        phoneController.text = data["phoneNumber"] ?? "";
        strengthController.text = data["strength"] ?? "";
        weaknessController.text = data["weakness"] ?? "";
        interestController.text = data["interest"] ?? "";
        yearController.text = data["yearOfStudying"] ?? "";
        courseController.text = data["course"] ?? "";
      });
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);

    final updatedData = {
      "studentName": widget.studentName,
      "dateOfBirth": dobController.text,
      "phoneNumber": phoneController.text,
      "strength": strengthController.text,
      "weakness": weaknessController.text,
      "interest": interestController.text,
      "yearOfStudying": yearController.text,
      "course": courseController.text,
    };

    final success =
        await ApiService.updateFullProfile(widget.studentName, updatedData);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? "Profile updated successfully!"
              : "Failed to update profile."),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }

    setState(() {
      _isSaving = false;
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
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          CircleAvatar(
            radius: 55,
            backgroundColor: AppColors.primaryColor.withOpacity(0.15),
            child: const Icon(Icons.person,
                size: 70, color: AppColors.primaryColor),
          ),
          const SizedBox(height: 16),
          Text(
            widget.studentName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: AppColors.textColor,
            ),
          ),
          const SizedBox(height: 20),
          _sectionTitle("Personal Info"),
          _readonlyField("Name", widget.studentName),
          _editableField("Date of Birth", dobController,
              hint: "DD-MM-YYYY"),
          _editableField("Phone Number", phoneController,
              keyboard: TextInputType.phone),
          const SizedBox(height: 20),
          _sectionTitle("Academic Info"),
          _editableField("Year of Studying", yearController),
          _editableField("Course", courseController),
          const SizedBox(height: 20),
          _sectionTitle("Skills & Interests"),
          _editableField("Strengths", strengthController),
          _editableField("Weaknesses", weaknessController),
          _editableField("Interests", interestController),
          if (_isSaving) ...[
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textColor,
            ),
          ),
        ),
      );

  Widget _readonlyField(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Text("$label: ",
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textColor)),
            Expanded(
              child: Text(value,
                  style:
                      const TextStyle(color: AppColors.subtitleColor)),
            ),
          ],
        ),
      );

  Widget _editableField(
    String label,
    TextEditingController controller, {
    String? hint,
    TextInputType? keyboard,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        enabled: _isEditing,
        keyboardType: keyboard ?? TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          filled: !_isEditing,
          fillColor:
              _isEditing ? Colors.white : Colors.grey.shade200,
        ),
      ),
    );
  }
}
