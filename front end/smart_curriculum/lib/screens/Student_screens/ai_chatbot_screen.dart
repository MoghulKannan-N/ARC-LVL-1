import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:smart_curriculum/config.dart';
import 'package:smart_curriculum/services/Student_service/student_api_service.dart';

class AiChatbotScreen extends StatefulWidget {
  const AiChatbotScreen({super.key});

  @override
  State<AiChatbotScreen> createState() => _AiChatbotScreenState();
}

class _AiChatbotScreenState extends State<AiChatbotScreen> {
  final List<Map<String, String>> messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool isSending = false;

  String get aiUrl => "$flask/chatbot";

  @override
  void initState() {
    super.initState();

    print("---------------------------------------");
    print(" Chatbot Screen Opened");
    print(" Student ID: ${ApiService.loggedInStudentId}");
    print(" Student Name: ${ApiService.loggedInStudentName}");
    print("---------------------------------------");

    // Add greeting
    messages.add({
      "sender": "bot",
      "text": "Hello ${ApiService.loggedInStudentName}! 👋\nI'm your AI Learning Assistant. How can I help you today?"
    });
  }

  Future<void> sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      messages.add({"sender": "user", "text": text});
      isSending = true;
    });

    _controller.clear();
    scrollToBottom();

    try {
      final url = Uri.parse(aiUrl);

      final res = await http.post(
        url,
        body: {"message": text},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        String reply = data["reply"] ?? "I couldn't understand that.";

        setState(() {
          messages.add({"sender": "bot", "text": reply});
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

    setState(() => isSending = false);
    scrollToBottom();
  }

  void scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Widget buildMessageBubble(Map<String, String> msg) {
    bool isUser = msg["sender"] == "user";

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isUser ? Colors.deepPurple : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          msg["text"] ?? "",
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black87,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = ApiService.loggedInStudentName ?? "Student";
    final id = ApiService.loggedInStudentId?.toString() ?? "Unknown";

    return Scaffold(
      appBar: AppBar(
        title: Text("AI Assistant ($name – ID: $id)"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),

      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (ctx, index) {
                return buildMessageBubble(messages[index]);
              },
            ),
          ),

          // ---------------- INPUT BAR ----------------
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    maxLines: null,
                    decoration: const InputDecoration(
                      hintText: "Type your question...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                isSending
                    ? const SizedBox(
                        height: 28,
                        width: 28,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        icon: const Icon(Icons.send, color: Colors.deepPurple),
                        onPressed: sendMessage,
                      ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
