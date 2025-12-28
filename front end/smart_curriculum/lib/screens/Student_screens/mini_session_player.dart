import 'dart:convert';
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    data = widget.session;
  }

  // --------------------------------------------------------
  // SUBMIT QUIZ → /complete_mini_session (uses ApiService)
  // --------------------------------------------------------
  Future<void> submitQuiz() async {
    if (submitting) return;

    final studentId = ApiService.loggedInStudentId;
    if (studentId == null) {
      _showDialog("Error", "Student not logged in.");
      return;
    }

    setState(() => submitting = true);

    final res = await ApiService.completeMiniSession(
      studentId: studentId,
      miniSessionId: data["mini_session_id"],
      answersMap: selectedAnswers,
    );

    setState(() => submitting = false);

    if (res == null || res.containsKey("_error")) {
      _showDialog("Error", "Something went wrong! (${res?["_error"] ?? "unknown"})");
      return;
    }

    final msg = (res["message"] ?? "").toString();

    if (msg.contains("Split")) {
      _showDialog("Need More Practice", msg);
    } else if (msg.toLowerCase().contains("passed")) {
      _showDialog("Great Job!", msg);
    } else {
      _showDialog("Result", msg);
    }

    // Load next session automatically
    await Future.delayed(const Duration(milliseconds: 400));
    await loadNextSession();
  }

  // --------------------------------------------------------
  // LOAD NEXT MINI SESSION
  // --------------------------------------------------------
  Future<void> loadNextSession() async {
    final id = ApiService.loggedInStudentId;
    if (id == null) return;

    final res = await ApiService.getNextMiniSession(id);

    if (res == null || res.containsKey("_error")) {
      _showDialog("Error", "Unable to fetch next session.");
      return;
    }

    // If roadmap is fully complete
    if ((res["mini_session_id"] ?? 0) == 0) {
      _showDialog("🎉 Completed", "All sessions are done!");
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MiniSessionPlayer(session: res),
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
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: const Text("No quiz available.", style: TextStyle(fontSize: 16)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
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
            elevation: 1,
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Q${index + 1}. ${q["question"]}",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),

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
      ],
    );
  }

  // --------------------------------------------------------
  // BUILD MAIN UI
  // --------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final parent = (data["parent_subtopic"] ?? "").toString();
    final title = (data["mini_subtopic"] ?? "").toString();
    final content = (data["content"] ?? "").toString();

    final List resources = data["resources"] ?? [];
    final List videos = data["videos"] ?? [];

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(title.isNotEmpty ? title : "Mini Session"),
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: Column(
          children: [
            // Content area (scrollable)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Parent breadcrumb
                    if (parent.isNotEmpty)
                      Text(
                        parent,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.subtitleColor,
                        ),
                      ),

                    if (parent.isNotEmpty) const SizedBox(height: 8),

                    // Title
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textColor,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // CONTENT
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6)],
                      ),
                      child: Text(
                        content,
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // RESOURCES
                    if (resources.isNotEmpty) ...[
                      const Text("Resources",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryColor)),
                      const SizedBox(height: 8),
                      ...resources.map((r) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Text("• $r", style: const TextStyle(fontSize: 14)),
                          )),
                      const SizedBox(height: 12),
                    ],

                    // VIDEOS
                    if (videos.isNotEmpty) ...[
                      const Text("Videos",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryColor)),
                      const SizedBox(height: 8),
                      ...videos.map((v) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Text("• $v", style: const TextStyle(fontSize: 14)),
                          )),
                      const SizedBox(height: 12),
                    ],

                    // QUIZ
                    buildQuiz(),

                    // small bottom spacing so submit button doesn't overlap content
                    const SizedBox(height: 90),
                  ],
                ),
              ),
            ),

            // Bottom action bar (Submit)
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Questions: ${ (data['quiz'] ?? []).length }",
                        style: const TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: submitting ? null : submitQuiz,
                      icon: submitting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.send),
                      label: Text(submitting ? "Submitting..." : "Submit Quiz"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
