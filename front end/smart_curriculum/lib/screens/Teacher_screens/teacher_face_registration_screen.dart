import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_mjpeg/flutter_mjpeg.dart';
import 'package:smart_curriculum/config.dart'; // ✅ updated path

class FaceRegistrationScreen extends StatefulWidget {
  final String studentName;

  const FaceRegistrationScreen({super.key, required this.studentName});

  @override
  State<FaceRegistrationScreen> createState() => _FaceRegistrationScreenState();
}

class _FaceRegistrationScreenState extends State<FaceRegistrationScreen> {
  bool captured = false;
  bool registering = false;
  Uint8List? capturedImage;

  // -----------------------------
  // CAPTURE FRAME FROM FLASK CAMERA STREAM
  // -----------------------------
  Future<void> captureFrame() async {
    final url = Uri.parse("$flask/face/capture-frame");

    try {
      final response = await http.post(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["ok"] == true) {
          setState(() => captured = true);
          _showMessage("✅ Frame captured! Now click Register Face.");
        } else {
          _showMessage("⚠️ Capture failed: ${data["error"] ?? 'unknown'}");
        }
      } else {
        _showMessage("❌ Capture failed (${response.statusCode})");
      }
    } catch (e) {
      _showMessage("⚠️ Failed to connect to AI service: $e");
    }
  }

  // -----------------------------
  // REGISTER THE FACE (NEW LOGIC)
  // -----------------------------
  Future<void> registerFace() async {
    setState(() => registering = true);

    try {
      // 🧠 Step 1: Read the captured temp frame image from Flask server
      final getUrl = Uri.parse("$flask/temp_frame.jpg");
      final getResponse = await http.get(getUrl);

      if (getResponse.statusCode != 200) {
        _showMessage("❌ Could not fetch captured frame from Flask.");
        setState(() => registering = false);
        return;
      }

      // 🧠 Step 2: Prepare multipart request to /face/register-mobile
      final registerUrl = Uri.parse("$flask/face/register-mobile");
      final request = http.MultipartRequest("POST", registerUrl)
        ..fields["name"] = widget.studentName
        ..files.add(
          http.MultipartFile.fromBytes(
            "file",
            getResponse.bodyBytes,
            filename: "${widget.studentName}.jpg",
          ),
        );

      // 🧠 Step 3: Send request
      final streamed = await request.send();
      final res = await http.Response.fromStream(streamed);

      // 🧠 Step 4: Handle response
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data["ok"] == true) {
          _showMessage("✅ Face registered successfully!");
        } else {
          _showMessage("⚠️ Registration failed: ${data["error"] ?? 'unknown'}");
        }
      } else {
        _showMessage("❌ Registration failed (${res.statusCode})");
      }
    } catch (e) {
      _showMessage("⚠️ Network error: $e");
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
                    stream: "$flask/face/stream",
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
