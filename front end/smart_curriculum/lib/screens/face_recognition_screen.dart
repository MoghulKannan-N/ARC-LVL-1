import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';

class FaceRecognitionScreen extends StatefulWidget {
  const FaceRecognitionScreen({super.key});

  @override
  State<FaceRecognitionScreen> createState() => _FaceRecognitionScreenState();
}

class _FaceRecognitionScreenState extends State<FaceRecognitionScreen> {
  final ImagePicker picker = ImagePicker();
  String status = "Tap a button to begin.";
  bool busy = false;

  List<String> actions = [];

  Future<List<String>> _fetchActions() async {
    try {
      final res = await http.get(Uri.parse("${ApiService.faceUrl}/face/get-actions"));
      if (res.statusCode == 200) {
        final j = jsonDecode(res.body);
        if (j["ok"] == true && j["actions"] is List) {
          return List<String>.from(j["actions"]);
        }
      }
    } catch (e) {
      debugPrint("get-actions error: $e");
    }
    return ["turn_head_left", "move_eyes_right"]; // fallback
  }

  Future<void> registerMobile() async {
    final name = ApiService.loggedInStudentName ?? ApiService.loggedInUsername ?? "Unknown";
    final shot = await picker.pickImage(source: ImageSource.camera);
    if (shot == null) return;

    setState(() {
      busy = true;
      status = "Uploading your selfie to register...";
    });

    final req = http.MultipartRequest(
      "POST",
      Uri.parse("${ApiService.faceUrl}/face/register-mobile"),
    );
    req.fields["name"] = name;
    req.files.add(await http.MultipartFile.fromPath("file", shot.path));

    final resp = await req.send();
    final body = await resp.stream.bytesToString();

    try {
      final Map<String, dynamic> j = jsonDecode(body);
      if (j["ok"] == true) {
        setState(() => status = "✅ Registered successfully for $name");
      } else {
        setState(() => status = "❌ Register failed: ${j["error"] ?? "unknown"}");
      }
    } catch (e) {
      setState(() => status = "❌ Register failed: $e");
    }

    setState(() => busy = false);
  }

  Future<void> livenessAndRecognize() async {
    setState(() {
      busy = true;
      status = "Getting actions for liveness...";
    });

    actions = await _fetchActions();
    if (actions.length != 2) {
      actions = ["turn_head_left", "move_eyes_right"];
    }

    // Take two selfies: before and after performing actions
    setState(() => status = "Action 1: ${actions[0]}\nTake FIRST selfie (before).");
    final first = await picker.pickImage(source: ImageSource.camera);
    if (first == null) {
      setState(() {
        busy = false;
        status = "Cancelled.";
      });
      return;
    }

    setState(() => status = "Action 2: ${actions[1]}\nNow perform the action and take SECOND selfie.");
    final second = await picker.pickImage(source: ImageSource.camera);
    if (second == null) {
      setState(() {
        busy = false;
        status = "Cancelled.";
      });
      return;
    }

    setState(() => status = "Verifying liveness & recognition...");

    final req = http.MultipartRequest(
      "POST",
      Uri.parse("${ApiService.faceUrl}/face/recognize-two-step"),
    );
    req.files.add(await http.MultipartFile.fromPath("file1", first.path));
    req.files.add(await http.MultipartFile.fromPath("file2", second.path));
    req.fields["actions[]"] = actions[0];
    req.fields["actions[]"] = actions[1];

    final resp = await req.send();
    final body = await resp.stream.bytesToString();

    try {
      final Map<String, dynamic> j = jsonDecode(body);

      final live = j["liveness"] == true;
      final rec = j["recognized"] == true;
      final name = (j["name"] ?? "") as String;
      final score = (j["score"] ?? 0).toString();

      if (!live) {
        setState(() => status = "❌ Liveness failed. Please try again clearly.");
        busy = false;
        return;
      }

      if (!rec) {
        setState(() => status = "⚠️ Liveness passed but face not recognized.");
        busy = false;
        return;
      }

      final expected = ApiService.loggedInStudentName ?? ApiService.loggedInUsername ?? "";
      if (expected.isNotEmpty && expected != name) {
        setState(() => status = "❌ Recognized as $name, but logged-in user is $expected.");
        busy = false;
        return;
      }

      setState(() => status = "✅ Liveness passed & recognized: $name (score: $score) — marking attendance...");

      final ok = await ApiService.markAttendance(name);
      setState(() => status = ok
          ? "✅ Attendance marked for $name."
          : "⚠️ Recognition OK, attendance failed.");

    } catch (e) {
      setState(() => status = "❌ Error: $e");
    }

    setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Liveness + Face Recognition"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(22.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.face_6, size: 120, color: Colors.blue),
              const SizedBox(height: 24),
              Text(status, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 36),
              ElevatedButton.icon(
                onPressed: busy ? null : registerMobile,
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text("Register My Face (Mobile)"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(250, 52),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: busy ? null : livenessAndRecognize,
                icon: const Icon(Icons.verified_user),
                label: const Text("Verify Liveness + Recognize"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: const Size(250, 52),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
