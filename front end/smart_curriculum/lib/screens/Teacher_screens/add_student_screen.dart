import 'package:flutter/material.dart';
import 'package:smart_curriculum/services/Teacher_service/teacher_api_service.dart';
import 'package:smart_curriculum/utils/constants.dart';

class AddStudentScreen extends StatefulWidget {
  const AddStudentScreen({super.key});

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;

  Future<void> _addStudent() async {
    setState(() => isLoading = true);

    final success = await ApiService.addStudent(
      teacherId: 1, // ✅ FIXED NAMED PARAMETER
      name: nameController.text.trim(),
      username: usernameController.text.trim(),
      password: passwordController.text.trim(),
    );

    setState(() => isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Student added successfully!")),
      );

      nameController.clear();
      usernameController.clear();
      passwordController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Failed to add student")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Student"),
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
      ),
      backgroundColor: AppColors.teacherGradientLight,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: "Student Name",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.teacherSurface,
                prefixIcon: Icon(Icons.person, color: AppColors.teacherPrimary),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: AppColors.teacherPrimary,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: usernameController,
              decoration: InputDecoration(
                labelText: "Username",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.teacherSurface,
                prefixIcon:
                    Icon(Icons.account_circle, color: AppColors.teacherPrimary),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: AppColors.teacherPrimary,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.teacherSurface,
                prefixIcon: Icon(Icons.lock, color: AppColors.teacherPrimary),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: AppColors.teacherPrimary,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            TeacherCustomButtons.primaryAction(
              text: "ADD STUDENT",
              onPressed: isLoading ? () {} : _addStudent,
              icon: Icons.person_add,
              isLoading: isLoading,
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }
}
