import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smart_curriculum/config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String springUrl = "$sb/api";
  static const String faceUrl = flask;

  static String? loggedInUsername;
  static String? loggedInStudentName;
  static bool? isFaceRegistered;

  // Keys for SharedPreferences
  static const _kUsername = 'student_logged_in_username';
  static const _kStudentName = 'student_logged_in_name';
  static const _kFaceRegistered = 'student_face_registered';

  // ---------------------------------------------------------
  // SAVE / LOAD / CLEAR LOGIN STATE
  // ---------------------------------------------------------
  static Future<void> saveLoginState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (loggedInUsername != null) {
        await prefs.setString(_kUsername, loggedInUsername!);
      }
      if (loggedInStudentName != null) {
        await prefs.setString(_kStudentName, loggedInStudentName!);
      }
      if (isFaceRegistered != null) {
        await prefs.setBool(_kFaceRegistered, isFaceRegistered!);
      }
    } catch (e) {
      print('saveLoginState error: $e');
    }
  }

  static Future<void> loadLoginState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      loggedInUsername = prefs.getString(_kUsername);
      loggedInStudentName = prefs.getString(_kStudentName);
      isFaceRegistered = prefs.getBool(_kFaceRegistered);
    } catch (e) {
      print('loadLoginState error: $e');
    }
  }

  static Future<void> clearLoginState() async {
    loggedInUsername = null;
    loggedInStudentName = null;
    isFaceRegistered = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kUsername);
      await prefs.remove(_kStudentName);
      await prefs.remove(_kFaceRegistered);
    } catch (e) {
      print('clearLoginState error: $e');
    }
  }

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

      if (loggedInStudentName != null) {
        isFaceRegistered = await checkFaceExists(loggedInStudentName!);
      }

      await saveLoginState();

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
  // GET STUDENT PROFILE (OLD SYSTEM)
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
  // PROFILE MANAGEMENT (NEW)
  // ---------------------------------------------------------

  /// Fetch extended student profile (from ProfileController)
  static Future<Map<String, dynamic>?> fetchFullProfile(
      String studentName) async {
    final url = Uri.parse("$springUrl/profile/$studentName");

    try {
      final res = await http.get(url);
      if (res.statusCode == 200 && res.body.isNotEmpty) {
        return jsonDecode(res.body);
      }
      return null;
    } catch (e) {
      print("❌ fetchFullProfile error: $e");
      return null;
    }
  }

  /// Update profile fields (DOB, phone, course, etc.)
  static Future<bool> updateFullProfile(
      String studentName, Map<String, dynamic> profileData) async {
    final url = Uri.parse("$springUrl/profile/$studentName");
    try {
      final res = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(profileData),
      );
      return res.statusCode == 200;
    } catch (e) {
      print("❌ updateFullProfile error: $e");
      return false;
    }
  }

  // ---------------------------------------------------------
  // ATTENDANCE MANAGEMENT
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
