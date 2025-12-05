import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import 'package:smart_curriculum/services/Student_service/student_api_service.dart';
import 'package:smart_curriculum/screens/Student_screens/student_home_screen.dart';
import 'package:smart_curriculum/utils/constants.dart';

/// Handles face registration for students via ML Kit + API upload.
class StudentFaceRegistrationScreen extends StatefulWidget {
  final String studentName;

  const StudentFaceRegistrationScreen({super.key, required this.studentName});

  @override
  State<StudentFaceRegistrationScreen> createState() =>
      _StudentFaceRegistrationScreenState();
}

class _StudentFaceRegistrationScreenState
    extends State<StudentFaceRegistrationScreen> {
  CameraController? _controller;
  bool _isBusy = false;
  String _status = "Initializing camera...";
  String _result = "";

  late FaceDetector _faceDetector;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(enableClassification: true, enableTracking: true),
    );
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final front = cameras.firstWhere(
      (cam) => cam.lensDirection == CameraLensDirection.front,
    );
    _controller = CameraController(front, ResolutionPreset.medium, enableAudio: false);
    await _controller!.initialize();
    setState(() => _status = "Camera ready. Capture your face to register.");
  }

  Future<void> _captureAndRegister() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    setState(() {
      _isBusy = true;
      _status = "Capturing face...";
    });

    try {
      final file = await _controller!.takePicture();

      // Local face detection
      final input = InputImage.fromFilePath(file.path);
      final faces = await _faceDetector.processImage(input);

      if (faces.isEmpty) {
        setState(() {
          _isBusy = false;
          _status = "❌ No face detected. Try again.";
        });
        return;
      }

      setState(() => _status = "📤 Uploading and registering...");

      final request = http.MultipartRequest(
        "POST",
        Uri.parse("${ApiService.faceUrl}/face/register-mobile"),
      );
      request.fields["name"] = widget.studentName;
      request.files.add(await http.MultipartFile.fromPath("file", file.path));

      final response = await request.send();
      final body = await response.stream.bytesToString();
      final data = jsonDecode(body);

      if (data["ok"] != true) {
        setState(() {
          _status = "❌ Registration failed";
          _result = data["error"] ?? "Unknown error";
        });
        return;
      }

      setState(() {
        _status = "✅ Face registered successfully!";
        _result = "Welcome, ${widget.studentName}";
      });

      await Future.delayed(const Duration(seconds: 2));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => StudentHomeScreen(studentName: widget.studentName),
        ),
      );
    } catch (e) {
      setState(() {
        _status = "❌ Error occurred";
        _result = e.toString();
      });
    } finally {
      setState(() => _isBusy = false);
    }
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
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                  onPressed: _isBusy ? null : _captureAndRegister,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Capture & Register"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
