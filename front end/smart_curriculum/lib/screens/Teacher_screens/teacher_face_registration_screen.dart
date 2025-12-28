import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import 'package:smart_curriculum/services/Student_service/student_api_service.dart';
import 'package:smart_curriculum/screens/Teacher_screens/teacher_home_screen.dart';
import 'package:smart_curriculum/utils/constants.dart';

class FaceRegistrationScreen extends StatefulWidget {
  final String studentName;

  const FaceRegistrationScreen({super.key, required this.studentName});

  @override
  State<FaceRegistrationScreen> createState() => _FaceRegistrationScreenState();
}

class _FaceRegistrationScreenState extends State<FaceRegistrationScreen> {
  CameraController? _controller;
  bool captured = false;
  bool registering = false;

  String _status = "Initializing camera...";
  String _result = "";

  late FaceDetector _faceDetector;

  @override
  void initState() {
    super.initState();
    _initializeCamera();

    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true,
        enableTracking: true,
      ),
    );
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final front = cameras.firstWhere(
      (cam) => cam.lensDirection == CameraLensDirection.front,
    );

    _controller = CameraController(
      front,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _controller!.initialize();

    setState(() {
      _status = "Camera ready. Align face and press Capture.";
    });
  }

  Future<void> captureFrame() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    setState(() {
      _status = "📸 Capturing...";
      _result = "";
      captured = false;
    });

    try {
      final file = await _controller!.takePicture();

      final input = InputImage.fromFilePath(file.path);
      final faces = await _faceDetector.processImage(input);

      if (faces.isEmpty) {
        setState(() {
          _status = "❌ No face detected. Try again.";
          _result = "";
        });
        return;
      }

      setState(() {
        _status = "✅ Face captured! Now click Register.";
        captured = true;
      });

      capturedImage = await file.readAsBytes();
    } catch (e) {
      setState(() {
        _status = "❌ Error capturing image";
        _result = e.toString();
      });
    }
  }

  Uint8List? capturedImage;

  Future<void> registerFace() async {
    if (!captured || capturedImage == null) return;

    setState(() {
      registering = true;
      _status = "📤 Registering face...";
    });

    try {
      final url = Uri.parse("${ApiService.faceUrl}/face/register-mobile");

      final request = http.MultipartRequest("POST", url)
        ..fields["name"] = widget.studentName
        ..files.add(
          http.MultipartFile.fromBytes(
            "file",
            capturedImage!,
            filename: "${widget.studentName}.jpg",
          ),
        );

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["ok"] == true) {
        setState(() {
          _status = "✅ Registration successful!";
          _result = "Welcome, ${widget.studentName}";
        });

        await Future.delayed(const Duration(seconds: 2));

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const TeacherHomeScreen(),
          ),
        );
      } else {
        setState(() {
          _status = "❌ Registration failed";
          _result = data["error"] ?? "Unknown error";
        });
      }
    } catch (e) {
      setState(() {
        _status = "❌ Network error";
        _result = e.toString();
      });
    }

    setState(() => registering = false);
  }

  @override
  void dispose() {
    _controller?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Register Face (${widget.studentName})"),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: _controller == null || !_controller!.value.isInitialized
                ? const Center(child: CircularProgressIndicator())
                : CameraPreview(_controller!),
          ),

          Container(
            color: Colors.black87,
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            child: Column(
              children: [
                Text(
                  _status,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _result,
                  style: const TextStyle(color: Colors.greenAccent),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                ElevatedButton.icon(
                  onPressed: registering ? null : captureFrame,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Capture"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                ),

                const SizedBox(height: 10),

                ElevatedButton.icon(
                  onPressed:
                      (!captured || registering) ? null : registerFace,
                  icon: const Icon(Icons.how_to_reg),
                  label: Text(
                      registering ? "Registering..." : "Register Face"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        captured ? Colors.green : Colors.green.shade200,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
