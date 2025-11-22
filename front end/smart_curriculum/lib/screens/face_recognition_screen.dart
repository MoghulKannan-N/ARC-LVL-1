import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../services/api_service.dart';
import 'package:flutter/foundation.dart';

class FaceRecognitionScreen extends StatefulWidget {
  const FaceRecognitionScreen({super.key});

  @override
  State<FaceRecognitionScreen> createState() => _FaceRecognitionScreenState();
}

class _FaceRecognitionScreenState extends State<FaceRecognitionScreen> {
  CameraController? _controller;
  bool _isBusy = false;
  bool _showRegister = false;
  XFile? _capturedImage;

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

    _controller = CameraController(frontCamera, ResolutionPreset.medium,
        enableAudio: false);
    await _controller!.initialize();

    setState(() => _status = "Camera ready. Press Capture.");
  }

  /// Converts a [CameraImage] to [InputImage] for ML Kit
  InputImage _convertCameraImage(CameraImage image) {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize =
        Size(image.width.toDouble(), image.height.toDouble());

    final InputImageRotation rotation = InputImageRotation.rotation0deg;

    final InputImageFormat format =
        InputImageFormatValue.fromRawValue(image.format.raw) ??
            InputImageFormat.nv21;

    final metadata = InputImageMetadata(
      size: imageSize,
      rotation: rotation,
      format: format,
      bytesPerRow: image.planes.first.bytesPerRow,
    );

    return InputImage.fromBytes(bytes: bytes, metadata: metadata);
  }

  Future<void> _captureAndRecognize() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    setState(() {
      _isBusy = true;
      _showRegister = false;
      _status = "Capturing face...";
    });

    try {
      final file = await _controller!.takePicture();
      _capturedImage = file;

      final inputImage = InputImage.fromFilePath(file.path);
      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        setState(() {
          _isBusy = false;
          _status = "❌ No face detected. Try again with better lighting.";
        });
        return;
      }

      setState(() => _status = "🔍 Sending for recognition...");
      final request = http.MultipartRequest(
        'POST',
        Uri.parse("${ApiService.faceUrl}/face/recognize"),
      );
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

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

      final recognized = data["recognized"] == true;
      final name = data["name"] ?? "Unknown";
      final score = (data["score"] ?? 0.0).toStringAsFixed(3);

      if (!recognized) {
        setState(() {
          _status = "⚠️ Face not recognized.";
          _result = "Score: $score";
          _showRegister = true;
        });
        return;
      }

      setState(() {
        _status = "✅ Recognized as $name";
        _result = "Score: $score";
      });

      final ok = await ApiService.markAttendance(name);
      setState(() {
        _result += ok
            ? "\n✅ Attendance marked for $name"
            : "\n⚠️ Attendance marking failed";
      });
    } catch (e) {
      setState(() {
        _status = "❌ Error occurred";
        _result = e.toString();
      });
    } finally {
      setState(() => _isBusy = false);
    }
  }

  Future<void> _registerFace() async {
    if (_capturedImage == null) return;

    final nameController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Register Face"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: "Enter your name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final name = nameController.text.trim();
              if (name.isEmpty) return;

              setState(() {
                _status = "🧠 Registering face...";
                _isBusy = true;
              });

              try {
                final request = http.MultipartRequest(
                  'POST',
                  Uri.parse("${ApiService.faceUrl}/face/register-mobile"),
                );
                request.files.add(await http.MultipartFile.fromPath(
                    'file', _capturedImage!.path));
                request.fields['name'] = name;

                final response = await request.send();
                final respBody = await response.stream.bytesToString();
                final data = jsonDecode(respBody);

                if (data["ok"] == true) {
                  setState(() {
                    _status = "✅ Face registered successfully!";
                    _result = "Welcome, $name!";
                    _showRegister = false;
                  });
                } else {
                  setState(() {
                    _status = "❌ Registration failed";
                    _result = data["error"] ?? "Unknown error";
                  });
                }
              } catch (e) {
                setState(() {
                  _status = "❌ Error during registration";
                  _result = e.toString();
                });
              } finally {
                setState(() => _isBusy = false);
              }
            },
            child: const Text("Register"),
          ),
        ],
      ),
    );
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
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.black87,
            width: double.infinity,
            child: Column(
              children: [
                Text(
                  _status,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
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
                  label: const Text("Capture & Recognize"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                ),
                if (_showRegister)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: ElevatedButton.icon(
                      onPressed: _isBusy ? null : _registerFace,
                      icon: const Icon(Icons.person_add),
                      label: const Text("Register Face"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
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
