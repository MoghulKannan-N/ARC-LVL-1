import 'package:flutter/material.dart';
import 'package:smart_curriculum/utils/constants.dart';
import 'package:smart_curriculum/services/Student_service/student_api_service.dart';

class ProfileScreen extends StatefulWidget {
  final String studentName;

  const ProfileScreen({super.key, required this.studentName});

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
  bool _isEditing = false; // 🔹 controls edit mode

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final data = await ApiService.fetchFullProfile(widget.studentName);

    if (data != null) {
      // Backend may use either strength or strengths (same for others).
      // We read both to be robust.
      setState(() {
        dobController.text = data["dateOfBirth"] ?? data["date_of_birth"] ?? "";
        phoneController.text = data["phoneNumber"] ?? data["phone_number"] ?? "";
        strengthController.text =
            data["strengths"] ?? data["strength"] ?? "";
        weaknessController.text =
            data["weaknesses"] ?? data["weakness"] ?? "";
        interestController.text =
            data["interests"] ?? data["interest"] ?? "";
        yearController.text = data["yearOfStudying"] ??
            data["year_of_studying"] ??
            "";
        courseController.text = data["course"] ?? "";
      });
    }

    setState(() {
      _isLoading = false;
      _isEditing = false; // ensure view mode after load
    });
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isSaving = true;
    });

    // Use the new preferred keys (strengths/weaknesses/interests).
    // Also include old keys as fallbacks to maximize compatibility.
    final Map<String, dynamic> updatedData = {
      // server route probably identifies student by name; still include for completeness
      "studentName": widget.studentName,
      "dateOfBirth": dobController.text,
      "phoneNumber": phoneController.text,
      // preferred (new) keys:
      "strengths": strengthController.text,
      "weaknesses": weaknessController.text,
      "interests": interestController.text,
      // legacy keys (fallback):
      "strength": strengthController.text,
      "weakness": weaknessController.text,
      "interest": interestController.text,
      "yearOfStudying": yearController.text,
      "course": courseController.text,
    };

    // Disable editing during save
    setState(() => _isEditing = false);

    final success =
        await ApiService.updateFullProfile(widget.studentName, updatedData);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success
          ? "Profile updated successfully!"
          : "Failed to update profile."),
      backgroundColor: success ? Colors.green : Colors.red,
    ));

    // Refresh the profile from server to reflect any normalization
    if (success) {
      await _loadProfile();
    } else {
      setState(() => _isSaving = false);
    }

    // ensure saving flag off
    setState(() {
      _isSaving = false;
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Profile"),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (!_isLoading)
            IconButton(
              icon: Icon(_isEditing ? Icons.save : Icons.edit),
              onPressed: _isSaving
                  ? null
                  : () {
                      if (_isEditing) {
                        _saveProfile();
                      } else {
                        setState(() => _isEditing = true);
                      }
                    },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                  ]
                ],
              ),
            ),
    );
  }

  Widget _sectionTitle(String title) => Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(title,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textColor)),
        ),
      );

  Widget _readonlyField(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Text("$label: ",
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: AppColors.textColor)),
            Expanded(
                child: Text(value,
                    style: const TextStyle(color: AppColors.subtitleColor))),
          ],
        ),
      );

  Widget _editableField(String label, TextEditingController controller,
      {String? hint, TextInputType? keyboard}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        enabled: _isEditing, // 🔹 disables editing in view mode
        keyboardType: keyboard ?? TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          filled: !_isEditing,
          fillColor:
              _isEditing ? Colors.white : Colors.grey.shade200, // subtle hint
        ),
      ),
    );
  }
}