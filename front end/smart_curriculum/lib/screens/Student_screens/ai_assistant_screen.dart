import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:smart_curriculum/config.dart';
import 'package:smart_curriculum/services/Student_service/student_api_service.dart';
import 'package:smart_curriculum/utils/constants.dart';

import 'mini_session_player.dart';
import 'ai_chatbot_screen.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  bool loading = false;
  String progressText = "Loading...";
  String statusMessage = "";

  String get aiUrl => aiBase;


  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  // ----------------------------------------------------------
  // LOAD PROGRESS
  // ----------------------------------------------------------
  Future<void> _loadProgress() async {
    final id = ApiService.loggedInStudentId;
    if (id == null) return;

    final url = Uri.parse("$aiUrl/progress_roadmap?student_id=$id");
    final res = await http.get(url);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        progressText = "Progress: ${data['progress']}";
      });
    } else {
      setState(() => progressText = "Progress unavailable");
    }
  }

  // ----------------------------------------------------------
  // GENERATE TOPIC FROM STRENGTH + WEAKNESS + INTEREST
  // ----------------------------------------------------------
  Future<String?> _getAIRecommendedTopic() async {
    final profile = await ApiService.fetchFullProfile(
      ApiService.loggedInStudentName ?? "",
    );

    if (profile == null) return null;

    String strength = profile["strength"] ?? "";
    String weakness = profile["weakness"] ?? "";
    String interest = profile["interest"] ?? "";

    if (strength.isEmpty && weakness.isEmpty && interest.isEmpty) {
      return "General Study Skills"; // fallback topic
    }

    // Build backend-side topic creator
    final topicPrompt = """
Use student profile:
Strength: $strength
Weakness: $weakness
Interest: $interest

Generate 1 best study topic they should learn next.  
Return ONLY the topic name without explanation.
""";

    final url = Uri.parse("$aiUrl/chatbot");
    final res = await http.post(url, body: {"message": topicPrompt});

    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      return json["reply"]?.toString().trim();
    }

    return null;
  }

  // ----------------------------------------------------------
  // GENERATE ROADMAP
  // ----------------------------------------------------------
  Future<void> _generateRoadmap() async {
    final id = ApiService.loggedInStudentId;
    if (id == null) return;

    setState(() {
      loading = true;
      statusMessage = "Generating best roadmap for you...";
    });

    // 1) AI picks best topic
    final topic = await _getAIRecommendedTopic();

    if (topic == null) {
      setState(() {
        loading = false;
        statusMessage = "⚠️ Unable to generate topic.";
      });
      return;
    }

    // 2) Call backend roadmap generator
    final url = Uri.parse("$aiUrl/generate_roadmap");

    final res = await http.post(url, body: {
      "student_id": id.toString(),
      "topic": topic,
    });

    setState(() => loading = false);

    if (res.statusCode == 200) {
      setState(() {
        statusMessage = "Roadmap generated for: $topic";
      });
      _loadProgress();
    } else {
      setState(() {
        statusMessage = "Failed to generate roadmap.";
      });
    }
  }

  // ----------------------------------------------------------
  // NEXT MINI SESSION
  // ----------------------------------------------------------
  Future<void> _nextMiniSession() async {
    final id = ApiService.loggedInStudentId;
    if (id == null) return;

    setState(() {
      loading = true;
      statusMessage = "Fetching your next learning session...";
    });

    final url = Uri.parse("$aiUrl/next_mini_session?student_id=$id");
    final res = await http.get(url);

    setState(() => loading = false);

    if (res.statusCode == 200) {
      final sessionData = jsonDecode(res.body);

      // Completed ALL learning
      if (sessionData["mini_session_id"] == 0) {
        setState(() {
          statusMessage = "🎉 All sessions completed!";
        });
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MiniSessionPlayer(session: sessionData),
        ),
      );
    } else {
      setState(() {
        statusMessage = "Unable to load next session.";
      });
    }
  }

  void _openChat() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AiChatbotScreen()),
    );
  }

  // ----------------------------------------------------------
  // UI
  // ----------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final studentName = ApiService.loggedInStudentName ?? "Student";

    return Scaffold(
      appBar: AppBar(
        title: Text("${AppStrings.aiAssistant} — $studentName"),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.aiAssistant,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textColor,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              progressText,
              style: const TextStyle(fontSize: 18, color: AppColors.subtitleColor),
            ),

            const SizedBox(height: 20),

            if (statusMessage.isNotEmpty)
              Text(
                statusMessage,
                style: const TextStyle(fontSize: 16),
              ),

            const SizedBox(height: 30),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: loading ? null : _generateRoadmap,
              child: const Text("Generate Personalized Roadmap",
                  style: TextStyle(color: Colors.white, fontSize: 18)),
            ),

            const SizedBox(height: 12),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: loading ? null : _nextMiniSession,
              child: const Text("Continue Learning",
                  style: TextStyle(color: Colors.white, fontSize: 18)),
            ),

            const SizedBox(height: 12),

            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primaryColor, width: 2),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _openChat,
              child: const Text("Ask AI",
                  style: TextStyle(color: AppColors.primaryColor, fontSize: 18)),
            ),

          ],
        ),
      ),
    );
  }
}
