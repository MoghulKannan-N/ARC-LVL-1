import 'dart:async';
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
  late FaceDetector _faceDetector;

  Timer? _timer;
  bool _processing = false;

  String _status = "Initializing camera...";
  String _result = "";

  // Liveness states
  bool leftDone = false;
  bool rightDone = false;
  bool smileDone = false;

  int stage = 0;

  @override
  void initState() {
    super.initState();
    _initCamera();

    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true,
        enableTracking: true,
        performanceMode: FaceDetectorMode.accurate,
      ),
    );
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final frontCam = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
    );

    _controller =
        CameraController(frontCam, ResolutionPreset.medium, enableAudio: false);
    await _controller!.initialize();

    setState(() => _status = "Turn your head LEFT");

    // Start periodic frame checking every 600 ms
    _timer = Timer.periodic(const Duration(milliseconds: 600), (_) {
      if (!_processing) {
        _processing = true;
        _captureFrame();
      }
    });
  }

  Future<void> _captureFrame() async {
    if (!mounted || _controller == null) return;

    try {
      final pic = await _controller!.takePicture();
      final input = InputImage.fromFilePath(pic.path);
      final faces = await _faceDetector.processImage(input);

      if (faces.isEmpty) {
        setState(() => _status = "Face not detected — hold steady");
        _processing = false;
        return;
      }

      final face = faces.first;
      _evaluateLiveness(face);

      if (stage == 3) {
        _timer?.cancel();
        await Future.delayed(const Duration(milliseconds: 300));
        _verifyFace(pic.path);
      }
    } catch (_) {}

    _processing = false;
  }

  void _evaluateLiveness(Face face) {
    // ✅ Use normal yaw (no inversion). MLKit angles are not mirrored.
    final yaw = face.headEulerAngleY ?? 0;
    final smile = face.smilingProbability ?? 0.0;

    // TURN LEFT (user’s left = yaw positive)
    if (!leftDone && yaw > 15) {
      leftDone = true;
      stage = 1;
      setState(() => _status = "✔ LEFT detected — Now turn RIGHT");
      return;
    }

    // TURN RIGHT (user’s right = yaw negative)
    if (leftDone && !rightDone && yaw < -15) {
      rightDone = true;
      stage = 2;
      setState(() => _status = "✔ RIGHT detected — Now SMILE 😊");
      return;
    }

    // SMILE
    if (leftDone && rightDone && !smileDone && smile > 0.65) {
      smileDone = true;
      stage = 3;
      setState(() => _status = "✔ Liveness Passed 🎉 Verifying...");
    }
  }

  Future<void> _verifyFace(String path) async {
    final studentName = ApiService.loggedInStudentName;
    if (studentName == null) return;

    setState(() => _status = "Sending for recognition...");

    final exists = await ApiService.checkFaceExists(studentName);
    if (!exists) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              StudentFaceRegistrationScreen(studentName: studentName),
        ),
      );
      return;
    }

    final uri =
        Uri.parse("${ApiService.faceUrl}/face/recognize?name=$studentName");
    final req = http.MultipartRequest("POST", uri)
      ..files.add(await http.MultipartFile.fromPath("file", path));

    final res = await req.send();
    final body = await res.stream.bytesToString();
    final data = jsonDecode(body);

    if (data["ok"] != true) {
      setState(() => _result = "Server Error");
      return;
    }

    bool ok = data["recognized"];
    double score = data["score"] ?? 0.0;

    if (ok) {
      await ApiService.markAttendance(studentName);
      setState(() {
        _status = "🎉 Verified!";
        _result = "Score: ${score.toStringAsFixed(3)}\nMarked PRESENT";
      });
    } else {
      await ApiService.markAbsent(studentName);
      setState(() {
        _status = "❌ Not Matched";
        _result = "Score: ${score.toStringAsFixed(3)}\nMarked ABSENT";
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Face Recognition + Liveness"),
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
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.black,
            width: double.infinity,
            child: Column(
              children: [
                Text(
                  _status,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 10),
                Text(
                  _result,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.greenAccent, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
