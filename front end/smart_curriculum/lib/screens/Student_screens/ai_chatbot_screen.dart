// lib/screens/Student_screens/ai_chatbot_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:smart_curriculum/config.dart';
import 'package:smart_curriculum/services/Student_service/student_api_service.dart';
import 'package:smart_curriculum/utils/constants.dart';

class AiChatbotScreen extends StatefulWidget {
  const AiChatbotScreen({super.key});

  @override
  State<AiChatbotScreen> createState() => _AiChatbotScreenState();
}

class _AiChatbotScreenState extends State<AiChatbotScreen> {
  final List<Map<String, String>> messages = [];
  final TextEditingController controller = TextEditingController();
  final ScrollController scroll = ScrollController();

  bool sending = false;
  bool aiTyping = false;

  String get apiUrl => "$aiBase/chatbot";

  @override
  void initState() {
    super.initState();

    final name = ApiService.loggedInStudentName ?? "Student";

    messages.add({
      "sender": "bot",
      "text":
          "👋 Hello $name, I'm your AI learning assistant.\nAsk me anything about your topics!"
    });
  }

  // -------------------------------------------------------------------
  // SEND MESSAGE TO AI
  // -------------------------------------------------------------------
  Future<void> sendMsg() async {
    final text = controller.text.trim();
    if (text.isEmpty || sending) return;

    setState(() {
      sending = true;
      aiTyping = true;
      messages.add({"sender": "user", "text": text});
    });

    controller.clear();
    scrollToBottom();

    try {
      final res = await http.post(
        Uri.parse(apiUrl),
        body: {"message": text},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        setState(() {
          messages.add({
            "sender": "bot",
            "text": data["reply"] ?? "I couldn't understand that."
          });
        });
      } else {
        setState(() {
          messages.add({
            "sender": "bot",
            "text": "⚠️ Server error: ${res.statusCode}"
          });
        });
      }
    } catch (e) {
      setState(() {
        messages.add({"sender": "bot", "text": "⚠️ Connection error: $e"});
      });
    }

    setState(() {
      sending = false;
      aiTyping = false;
    });

    scrollToBottom();
  }

  // -------------------------------------------------------------------
  // AUTO SCROLL
  // -------------------------------------------------------------------
  void scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      scroll.animateTo(
        scroll.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  // -------------------------------------------------------------------
  // BUILD MESSAGE BUBBLE
  // -------------------------------------------------------------------
  Widget bubble(Map<String, String> msg) {
    bool user = msg["sender"] == "user";

    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: user ? AppColors.primaryColor : AppColors.cardColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 4,
                spreadRadius: 1)
          ],
        ),
        constraints: const BoxConstraints(maxWidth: 280),
        child: Text(
          msg["text"]!,
          style: TextStyle(
            color: user ? Colors.white : AppColors.textColor,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------
  // BUILD
  // -------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final name = ApiService.loggedInStudentName ?? "Student";

    return Scaffold(
      appBar: AppBar(
        title: Text("AI Chat ($name)"),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),

      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: scroll,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length + (aiTyping ? 1 : 0),
              itemBuilder: (_, i) {
                if (i == messages.length) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.cardColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text("AI is typing...",
                              style: TextStyle(color: AppColors.subtitleColor)),
                        ),
                      ],
                    ),
                  );
                }

                return bubble(messages[i]);
              },
            ),
          ),

          // -------------------------------------------------------
          // INPUT BAR
          // -------------------------------------------------------
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    maxLines: null,
                    decoration: const InputDecoration(
                      hintText: "Ask something...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                sending
                    ? const CircularProgressIndicator(strokeWidth: 2)
                    : IconButton(
                        icon: const Icon(Icons.send,
                            color: AppColors.primaryColor),
                        onPressed: sendMsg,
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
