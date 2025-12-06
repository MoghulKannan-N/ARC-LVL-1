import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:smart_curriculum/services/Student_service/student_api_service.dart';
import 'package:smart_curriculum/screens/Student_screens/student_face_registration_screen.dart';

class FaceRecognitionScreen extends StatefulWidget {
  const FaceRecognitionScreen({super.key});

  @override
  State<FaceRecognitionScreen> createState() => _FaceRecognitionScreenState();
}

class _FaceRecognitionScreenState extends State<FaceRecognitionScreen> {
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
      options: FaceDetectorOptions(
        enableClassification: true,
        enableTracking: true,
      ),
    );
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (cam) => cam.lensDirection == CameraLensDirection.front,
    );

    _controller = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _controller!.initialize();

    setState(() => _status = "Camera ready. Press Capture.");
  }

  Future<void> _captureAndRecognize() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    setState(() {
      _isBusy = true;
      _status = "Capturing face...";
      _result = "";
    });

    try {
      final file = await _controller!.takePicture();

      /// Step 1 — Local ML Face Detection
      final inputImage = InputImage.fromFilePath(file.path);
      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        setState(() {
          _isBusy = false;
          _status = "❌ No face detected. Try again with better lighting.";
        });
        return;
      }

      /// Step 2 — Get student name
      final studentName = ApiService.loggedInStudentName;
      if (studentName == null || studentName.trim().isEmpty) {
        setState(() {
          _isBusy = false;
          _status = "❌ Error: No logged-in student found.";
          _result = "Please log in again.";
        });
        return;
      }

      /// Step 3 — Check if student already has face embedding
      final faceExists = await ApiService.checkFaceExists(studentName);

      if (!faceExists) {
        setState(() {
          _isBusy = false;
          _status = "⚠️ No face embedding found for $studentName";
          _result = "Redirecting to face registration...";
        });

        await Future.delayed(const Duration(seconds: 1));

        if (!mounted) return;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StudentFaceRegistrationScreen(studentName: studentName),
          ),
        );

        return;
      }

      /// Step 4 — Send image for recognition
      setState(() => _status = "🔍 Sending for recognition...");

      final uri = Uri.parse(
        "${ApiService.faceUrl}/face/recognize?name=${Uri.encodeQueryComponent(studentName)}",
      );

      final request = http.MultipartRequest('POST', uri);
      request.files.add(
        await http.MultipartFile.fromPath('file', file.path),
      );

      final response = await request.send();
      final body = await response.stream.bytesToString();
      final data = jsonDecode(body);

      if (response.statusCode != 200) {
        setState(() {
          _status = "⚠️ Server error";
          _result = data.toString();
        });
        return;
      }

      if (data["ok"] != true) {
        setState(() {
          _status = "⚠️ Face service error";
          _result = data.toString();
        });
        return;
      }

      final recognized = data["recognized"] == true;
      final score = (data["score"] ?? 0.0).toStringAsFixed(3);

      if (recognized) {
        /// Matched → Mark PRESENT
        setState(() {
          _status = "✅ Face verified as $studentName";
          _result = "Score: $score\nMarking PRESENT...";
        });

        final ok = await ApiService.markAttendance(studentName);

        setState(() {
          _result += ok
              ? "\n🟢 Attendance marked PRESENT"
              : "\n⚠️ Failed to update attendance";
        });
      } else {
        /// Not matched → Mark ABSENT
        setState(() {
          _status = "❌ Face does NOT match $studentName";
          _result = "Score: $score\nMarking ABSENT...";
        });

        final ok = await ApiService.markAbsent(studentName);

        setState(() {
          _result += ok
              ? "\n🟠 Attendance marked ABSENT"
              : "\n⚠️ Failed to update attendance";
        });
      }
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
        title: const Text("Face Recognition"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: _controller == null || !_controller!.value.isInitialized
                ? const Center(child: CircularProgressIndicator())
                : CameraPreview(_controller!),
          ),

          /// Bottom panel
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.black87,
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
                  onPressed: _isBusy ? null : _captureAndRecognize,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Capture & Verify"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
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
