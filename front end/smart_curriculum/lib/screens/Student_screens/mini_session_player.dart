import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:smart_curriculum/config.dart';
import 'package:smart_curriculum/services/Student_service/student_api_service.dart';
import 'package:smart_curriculum/utils/constants.dart';

class MiniSessionPlayer extends StatefulWidget {
  final Map<String, dynamic> session;

  const MiniSessionPlayer({super.key, required this.session});

  @override
  State<MiniSessionPlayer> createState() => _MiniSessionPlayerState();
}

class _MiniSessionPlayerState extends State<MiniSessionPlayer> {
  late Map<String, dynamic> data;
  bool submitting = false;

  Map<int, String> selectedAnswers = {}; // stores selected mcq answers

  String get baseUrl => aiBase;

  @override
  void initState() {
    super.initState();
    data = widget.session;
  }

  // --------------------------------------------------------
  // SUBMIT QUIZ → /complete_mini_session
  // --------------------------------------------------------
  Future<void> submitQuiz() async {
    if (submitting) return;

    final studentId = ApiService.loggedInStudentId;
    if (studentId == null) return;

    setState(() => submitting = true);

    final url = Uri.parse("$baseUrl/complete_mini_session");

    final answersJson = {
      "answers": selectedAnswers.map((k, v) => MapEntry(k.toString(), v))
    };

    final res = await http.post(url, body: {
      "student_id": studentId.toString(),
      "mini_session_id": data["mini_session_id"].toString(),
      "quiz_answers": jsonEncode(answersJson),
    });

    setState(() => submitting = false);

    if (res.statusCode != 200) {
      _showDialog("Error", "Something went wrong! (${res.statusCode})");
      return;
    }

    final result = jsonDecode(res.body);

    // Backend now returns: message: "Quiz passed" OR "Split..."
    final msg = result["message"].toString();

    if (msg.contains("Split")) {
      _showDialog("Need More Practice", msg);
    } else if (msg.contains("passed")) {
      _showDialog("Great Job!", msg);
    }

    // Load next session automatically
    await Future.delayed(const Duration(milliseconds: 400));
    loadNextSession();
  }

  // --------------------------------------------------------
  // LOAD NEXT MINI SESSION
  // --------------------------------------------------------
  Future<void> loadNextSession() async {
    final id = ApiService.loggedInStudentId;
    if (id == null) return;

    final url = Uri.parse("$baseUrl/next_mini_session?student_id=$id");
    final res = await http.get(url);

    if (res.statusCode != 200) return;

    final next = jsonDecode(res.body);

    // If roadmap is fully complete
    if (next["mini_session_id"] == 0) {
      _showDialog("🎉 Completed", "All sessions are done!");
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MiniSessionPlayer(session: next),
      ),
    );
  }

  // --------------------------------------------------------
  // SHOW ALERT
  // --------------------------------------------------------
  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text("OK"),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
    );
  }

  // --------------------------------------------------------
  // BUILD QUIZ QUESTION UI
  // --------------------------------------------------------
  Widget buildQuiz() {
    List quiz = data["quiz"] ?? [];

    if (quiz.isEmpty) {
      return const Text("No quiz available.");
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          "Quiz",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
        ),
        const SizedBox(height: 10),

        ...List.generate(quiz.length, (index) {
          final q = quiz[index];
          List options = q["options"] ?? [];

          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Q${index + 1}. ${q["question"]}",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),

                  ...options.map((opt) {
                    return RadioListTile<String>(
                      title: Text(opt),
                      value: opt,
                      groupValue: selectedAnswers[index],
                      onChanged: (val) {
                        setState(() => selectedAnswers[index] = val!);
                      },
                    );
                  }).toList(),
                ],
              ),
            ),
          );
        }),

        const SizedBox(height: 20),

        Center(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
            ),
            onPressed: submitting ? null : submitQuiz,
            child: submitting
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text("Submit Quiz",
                    style: TextStyle(fontSize: 18, color: Colors.white)),
          ),
        ),

        const SizedBox(height: 40),
      ],
    );
  }

  // --------------------------------------------------------
  // BUILD MAIN UI
  // --------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final parent = data["parent_subtopic"] ?? "";
    final title = data["mini_subtopic"] ?? "";
    final content = data["content"] ?? "";

    final List resources = data["resources"] ?? [];
    final List videos = data["videos"] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (parent.isNotEmpty)
              Text(
                parent,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.subtitleColor,
                ),
              ),

            const SizedBox(height: 10),

            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textColor,
              ),
            ),

            const SizedBox(height: 20),

            // CONTENT
            Text(
              content,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),

            const SizedBox(height: 20),

            // RESOURCES
            if (resources.isNotEmpty) ...[
              const Text("Resources",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor)),
              const SizedBox(height: 8),
              ...resources.map((r) => Text("• $r")),
              const SizedBox(height: 20),
            ],

            // VIDEOS
            if (videos.isNotEmpty) ...[
              const Text("Videos",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor)),
              const SizedBox(height: 8),
              ...videos.map((v) => Text("• $v")),
              const SizedBox(height: 20),
            ],

            // QUIZ
            buildQuiz(),
          ],
        ),
      ),
    );
  }
}
