import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:smart_curriculum/config.dart';
import 'package:smart_curriculum/services/Student_service/student_api_service.dart';
import 'mini_session_player.dart';
import 'ai_chatbot_screen.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  bool loading = false;
  String currentTopic = "";
  String resultText = "";

  String get aiUrl => "$flask"; // flask backend

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final id = ApiService.loggedInStudentId;
    if (id == null) return;

    final url = Uri.parse("$aiUrl/progress_roadmap?student_id=$id");
    final res = await http.get(url);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        resultText = "Progress: ${data["progress"]}";
      });
    }
  }

  Future<void> _generateRoadmap() async {
    final id = ApiService.loggedInStudentId;
    if (id == null) return;

    setState(() => loading = true);

    final url = Uri.parse("$aiUrl/generate_roadmap");
    final res = await http.post(url, body: {
      "student_id": id.toString(),
    });

    setState(() => loading = false);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        currentTopic = data["topic"];
        resultText = "Roadmap generated for: $currentTopic";
      });
    }
  }

  Future<void> _nextMiniSession() async {
    final id = ApiService.loggedInStudentId;
    if (id == null) return;

    setState(() => loading = true);

    final url = Uri.parse("$aiUrl/next_mini_session?student_id=$id");
    final res = await http.get(url);

    setState(() => loading = false);

    if (res.statusCode == 200) {
      final sessionData = jsonDecode(res.body);
  
      Navigator.push(
        context,
        MaterialPageRoute(
          // FIX: changed data: to session:
          builder: (_) => MiniSessionPlayer(session: sessionData),
        ),
      );
    }
  }

  void _openChatbot() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AiChatbotScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final studentName = ApiService.loggedInStudentName ?? "Student";

    return Scaffold(
      appBar: AppBar(
        title: Text("AI Assistant — $studentName"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "AI Learning Assistant",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            Text(resultText, style: TextStyle(fontSize: 16)),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: loading ? null : _generateRoadmap,
              child: Text("Generate Roadmap"),
            ),

            ElevatedButton(
              onPressed: loading ? null : _nextMiniSession,
              child: Text("Next Mini Session"),
            ),
            ElevatedButton(
              onPressed: _openChatbot,
              child: Text("Open AI Chatbot"),
            ),
          ],
        ),
      ),
    );
  }
}
