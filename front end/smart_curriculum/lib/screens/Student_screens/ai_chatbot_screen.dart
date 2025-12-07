import 'package:flutter/material.dart';
import 'package:smart_curriculum/services/Student_service/student_api_service.dart';

class AiChatbotScreen extends StatefulWidget {
  const AiChatbotScreen({super.key});

  @override
  State<AiChatbotScreen> createState() => _AiChatbotScreenState();
}

class _AiChatbotScreenState extends State<AiChatbotScreen> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    print("🔄 Loading student login state...");
    await ApiService.loadLoginState();       // <-- CRITICAL

    print("---------------------------------------");
    print(" Chatbot Screen Opened");
    print(" Student ID: ${ApiService.loggedInStudentId}");
    print(" Student Name: ${ApiService.loggedInStudentName}");
    print("---------------------------------------");

    setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final studentId = ApiService.loggedInStudentId ?? "NULL";
    final studentName = ApiService.loggedInStudentName ?? "Unknown";

    return Scaffold(
      appBar: AppBar(
        title: Text("AI Chat — $studentName (ID: $studentId)"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Text(
          "Chatbot UI will be here\nStudent ID: $studentId",
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
