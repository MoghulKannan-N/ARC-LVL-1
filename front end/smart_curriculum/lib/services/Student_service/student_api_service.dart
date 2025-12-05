import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smart_curriculum/config.dart';

class ApiService {
  static const String springUrl = "$sb/api";
  static const String faceUrl = "$flask";

  static String? loggedInUsername;
  static String? loggedInStudentName;
  static bool? isFaceRegistered;

  // ---------------------------------------------------------
  // STUDENT LOGIN
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

      if (res.statusCode != 200) return false;

      String raw = res.body.trim();
      bool ok = false;

      try {
        final json = jsonDecode(raw);
        if (json is Map && json["ok"] == true) ok = true;
      } catch (_) {
        if (raw.toLowerCase().contains("student login successful")) ok = true;
      }

      if (!ok) return false;

      loggedInUsername = username;

      final profile = await getStudentProfile();
      if (profile != null && profile["name"] != null) {
        loggedInStudentName = profile["name"].toString();
      }

      // (Optional) still checks face registration for later
      if (loggedInStudentName != null) {
        isFaceRegistered = await checkFaceExists(loggedInStudentName!);
      }

      return true;
    } catch (e) {
      print("❌ studentLogin error: $e");
      return false;
    }
  }

  // ---------------------------------------------------------
  // CHECK IF FACE EXISTS
  // ---------------------------------------------------------
  static Future<bool> checkFaceExists(String studentName) async {
    final url = Uri.parse(
      "$faceUrl/face/exists?name=${Uri.encodeQueryComponent(studentName)}",
    );

    try {
      final res = await http.get(url);
      if (res.statusCode != 200) return false;
      final data = jsonDecode(res.body);
      return data["exists"] == true;
    } catch (e) {
      print("checkFaceExists error: $e");
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
  // MARK PRESENT
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
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ---------------------------------------------------------
  // MARK ABSENT
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
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
