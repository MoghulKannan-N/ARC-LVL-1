import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_mjpeg/flutter_mjpeg.dart';

class FaceRegistrationScreen extends StatefulWidget {
  final String studentName;

  const FaceRegistrationScreen({super.key, required this.studentName});

  @override
  State<FaceRegistrationScreen> createState() => _FaceRegistrationScreenState();
}

class _FaceRegistrationScreenState extends State<FaceRegistrationScreen> {
  bool captured = false;
  bool registering = false;

  // -----------------------------
  // CAPTURE FRAME FROM FLUTTER UI
  // -----------------------------
  Future<void> captureFrame() async {
    final url = Uri.parse("http://192.168.137.1:5000/face/capture-frame");

    try {
      final response = await http.post(url);

      if (response.statusCode == 200) {
        setState(() => captured = true);
        _showMessage("Captured! Now click Register Face.");
      } else {
        _showMessage("Capture failed.");
      }
    } catch (e) {
      _showMessage("Failed to connect to AI service.");
    }
  }

  // -----------------------------
  // REGISTER THE FACE (NO POPUP)
  // -----------------------------
  Future<void> registerFace() async {
    setState(() => registering = true);

    final url = Uri.parse("http://192.168.137.1:5000/face/register-frame");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"name": widget.studentName}),
      );

      final data = jsonDecode(response.body);

      if (data["ok"] == true) {
        _showMessage("Face registered successfully!");
      } else {
        _showMessage("Registration failed: ${data["error"]}");
      }
    } catch (e) {
      _showMessage("Failed to register face.");
    }

    setState(() => registering = false);
  }

  // -----------------------------
  // UI HELPER
  // -----------------------------
  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  // -----------------------------
  // UI BUILD
  // -----------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Register Face - ${widget.studentName}"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              const Text(
                "Align your face inside the circle",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 25),

              // ---------------------
              // CAMERA PREVIEW CIRCLE
              // ---------------------
              ClipOval(
                child: Container(
                  width: 320,
                  height: 320,
                  color: Colors.black12,
                  child: Mjpeg(
                    stream: "http://192.168.137.1:5000/face/stream",
                    isLive: true,
                    fit: BoxFit.cover,
                    timeout: const Duration(seconds: 3),
                    error: (context, error, stack) {
                      return const Center(
                        child: Text(
                          "Camera Offline",
                          style: TextStyle(color: Colors.red),
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // ---------------------
              // CAPTURE BUTTON
              // ---------------------
              ElevatedButton(
                onPressed: captureFrame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: const Size(160, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Capture",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),

              const SizedBox(height: 20),

              // ---------------------
              // REGISTER BUTTON
              // ---------------------
              ElevatedButton(
                onPressed: (!captured || registering)
                    ? null
                    : () => registerFace(),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      captured ? Colors.blue : Colors.blue.shade200,
                  minimumSize: const Size(200, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  registering ? "Registering..." : "Register Face",
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
