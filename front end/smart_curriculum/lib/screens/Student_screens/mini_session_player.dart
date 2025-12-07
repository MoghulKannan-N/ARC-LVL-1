import 'package:flutter/material.dart';

class MiniSessionPlayer extends StatelessWidget {
  final Map<String, dynamic> session;   // <-- add this

  const MiniSessionPlayer({
    super.key,
    required this.session,              // <-- add this
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(session["mini_subtopic"] ?? "Mini Session"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                session["content"] ?? "No content found",
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),

              Text(
                "Quiz:",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              ...List.generate(
                (session["quiz"]?.length ?? 0),
                (index) {
                  final q = session["quiz"][index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("${index + 1}. ${q["question"]}",
                            style: TextStyle(fontSize: 16)),
                        const SizedBox(height: 6),
                        ...List.generate(
                          q["options"].length,
                              (i) => Text("• ${q["options"][i]}"),
                        )
                      ],
                    ),
                  );
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
