import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class ApiService {
  // Spring Boot base URL
  static const String springUrl = "$sb/api";

  // Flask face-recognition service
  static const String faceUrl = "$flask";

  static String? loggedInUsername;
  static String? loggedInStudentName;

  // ---------------------------------------------------------
  // STUDENT LOGIN (Improved)
  // ---------------------------------------------------------
  static Future<bool> studentLogin(String username, String password) async {
    final url = Uri.parse("$springUrl/auth/student/login");

    try {
      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": username.trim(),
          "password": password.trim(),
        }),
      );

      print("🔹 Login response code: ${res.statusCode}");
      print("🔹 Login response body: ${res.body}");

      if (res.statusCode != 200) {
        print("❌ HTTP error ${res.statusCode}");
        return false;
      }

      // Handle both plain text and JSON responses
      String raw = res.body.trim();
      bool ok = false;

      try {
        final json = jsonDecode(raw);
        if (json is Map && json["ok"] == true) {
          ok = true;
        } else if (json["message"]
                ?.toString()
                .toLowerCase()
                .contains("login successful") ==
            true) {
          ok = true;
        }
      } catch (_) {
        // If not JSON, handle as plain text
        if (raw.toLowerCase().contains("student login successful")) {
          ok = true;
        }
      }

      if (ok) {
        loggedInUsername = username;
        final profile = await getStudentProfile();
        if (profile != null && profile["name"] != null) {
          loggedInStudentName = profile["name"].toString();
        }
      }

      return ok;
    } catch (e) {
      print("❌ studentLogin error: $e");
      return false;
    }
  }

  // ---------------------------------------------------------
  // GET STUDENT PROFILE
  // ---------------------------------------------------------
  static Future<Map<String, dynamic>?> getStudentProfile() async {
    if (loggedInUsername == null) return null;

    final url = Uri.parse("$springUrl/student/me?username=$loggedInUsername");

    try {
      final res = await http.get(url);
      print("🔹 Profile response: ${res.statusCode} -> ${res.body}");

      if (res.statusCode == 200 && res.body.isNotEmpty) {
        return jsonDecode(res.body);
      }
      return null;
    } catch (e) {
      print("❌ getStudentProfile error: $e");
      return null;
    }
  }

  // ---------------------------------------------------------
  // MARK ATTENDANCE (PRESENT)
  // ---------------------------------------------------------
  static Future<bool> markAttendance(String studentName) async {
    final url = Uri.parse("$springUrl/attendance/mark");

    try {
      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "studentName": studentName,
          "status": "PRESENT",
        }),
      );

      print("🟢 markAttendance response: ${res.statusCode} -> ${res.body}");
      return res.statusCode == 200;
    } catch (e) {
      print("❌ markAttendance error: $e");
      return false;
    }
  }

  // ---------------------------------------------------------
  // MARK ATTENDANCE (ABSENT)
  // ---------------------------------------------------------
  static Future<bool> markAbsent(String studentName) async {
    final url = Uri.parse("$springUrl/attendance/mark");

    try {
      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "studentName": studentName,
          "status": "ABSENT",
        }),
      );

      print("🟠 markAbsent response: ${res.statusCode} -> ${res.body}");
      return res.statusCode == 200;
    } catch (e) {
      print("❌ markAbsent error: $e");
      return false;
    }
  }

  // ---------------------------------------------------------
  // FLASK — Capture frame
  // (kept as-is, in case you use it elsewhere)
  // ---------------------------------------------------------
  static Future<bool> captureFrame() async {
    final url = Uri.parse("$faceUrl/face/capture-frame");
    try {
      final res = await http.post(url);
      if (res.statusCode == 200) {
        final j = jsonDecode(res.body);
        return j["ok"] == true;
      }
      return false;
    } catch (e) {
      print("captureFrame error: $e");
      return false;
    }
  }

  // ---------------------------------------------------------
  // FLASK — Register Face (frame based)
  // ---------------------------------------------------------
  static Future<Map<String, dynamic>> registerFace(String studentName) async {
    final url = Uri.parse("$faceUrl/face/register-frame");
    try {
      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"name": studentName}),
      );

      return jsonDecode(res.body);
    } catch (e) {
      return {"ok": false, "error": e.toString()};
    }
  }

  // ---------------------------------------------------------
  // FLASK — Recognize Face (frame based, no file)
  // ---------------------------------------------------------
  static Future<Map<String, dynamic>> recognizeFace() async {
    final url = Uri.parse("$faceUrl/face/recognize");
    try {
      final res = await http.post(url);
      return jsonDecode(res.body);
    } catch (e) {
      print("recognizeFace error: $e");
      return {"ok": false, "error": e.toString()};
    }
  }
}
