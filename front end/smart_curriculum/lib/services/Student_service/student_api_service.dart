import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smart_curriculum/config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String springUrl = "$sb/api";
  static const String faceUrl = flask;

  static String? loggedInUsername;
  static String? loggedInStudentName;
  static int? loggedInStudentId;
  static bool? isFaceRegistered;

  // Keys for SharedPreferences
  static const _kUsername = 'student_logged_in_username';
  static const _kStudentName = 'student_logged_in_name';
  static const _kStudentId = 'student_logged_in_id';
  static const _kFaceRegistered = 'student_face_registered';

  // default timeout for HTTP calls
  static const Duration _httpTimeout = Duration(seconds: 7);

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
      if (loggedInStudentId != null) {
        await prefs.setInt(_kStudentId, loggedInStudentId!);
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
      loggedInStudentId = prefs.getInt(_kStudentId);
      isFaceRegistered = prefs.getBool(_kFaceRegistered);
    } catch (e) {
      print('loadLoginState error: $e');
    }
  }

  static Future<void> clearLoginState() async {
    loggedInUsername = null;
    loggedInStudentName = null;
    loggedInStudentId = null;
    isFaceRegistered = null;

    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove(_kUsername);
      await prefs.remove(_kStudentName);
      await prefs.remove(_kStudentId);
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
      final res = await http
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "username": username.trim(),
              "password": password.trim(),
            }),
          )
          .timeout(_httpTimeout);

      print("🔹 Login response code: ${res.statusCode}");
      print("🔹 Login response body: ${res.body}");

      if (res.statusCode != 200) return false;

      final data = jsonDecode(res.body);

      // ------------------------------
      // Login failed
      // ------------------------------
      if (data == null || data["ok"] != true) {
        return false;
      }

      // ------------------------------
      // SUCCESS — read ID & NAME DIRECTLY
      // (handle string or int id)
      // ------------------------------
      final rawId = data["id"];
      int? parsedId;
      if (rawId is int) {
        parsedId = rawId;
      } else if (rawId != null) {
        parsedId = int.tryParse(rawId.toString());
      }

      loggedInUsername = data["username"] ?? data["user"] ?? username;
      // fallback keys for name
      loggedInStudentName = data["name"] ?? data["studentName"] ?? data["fullName"] ?? loggedInUsername;
      loggedInStudentId = parsedId;

      print("🎯 Student Login Successful");
      print("ID: $loggedInStudentId");
      print("Name: $loggedInStudentName");

      // ------------------------------
      // Check if face is registered
      // ------------------------------
      if (loggedInStudentName != null) {
        isFaceRegistered = await checkFaceExists(loggedInStudentName!);
      }

      // Save to SharedPreferences
      await saveLoginState();

      return true;
    } on TimeoutException {
      print("❌ studentLogin timeout");
      return false;
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
      final res = await http.get(url).timeout(_httpTimeout);
      if (res.statusCode != 200) return false;

      final data = jsonDecode(res.body);
      return data["exists"] == true;
    } on TimeoutException {
      print("checkFaceExists timeout");
      return false;
    } catch (e) {
      print("checkFaceExists error: $e");
      return false;
    }
  }

  // ---------------------------------------------------------
  // GET STUDENT PROFILE (SPRING)
  // Prefer calling by ID if available, otherwise fallback to username
  // ---------------------------------------------------------
  static Future<Map<String, dynamic>?> getStudentProfile() async {
    if (loggedInStudentId != null) {
      // prefer id-based endpoint if server supports it
      final url = Uri.parse("$springUrl/student/${loggedInStudentId}");
      try {
        final res = await http.get(url).timeout(_httpTimeout);
        if (res.statusCode == 200 && res.body.isNotEmpty) {
          return jsonDecode(res.body);
        }
      } catch (e) {
        print("❌ getStudentProfile by id error: $e");
      }
    }

    if (loggedInUsername == null) return null;

    final url = Uri.parse("$springUrl/student/me?username=${Uri.encodeQueryComponent(loggedInUsername!)}");

    try {
      final res = await http.get(url).timeout(_httpTimeout);
      if (res.statusCode == 200 && res.body.isNotEmpty) {
        return jsonDecode(res.body);
      }
      return null;
    } on TimeoutException {
      print("getStudentProfile timeout");
      return null;
    } catch (e) {
      print("❌ getStudentProfile error: $e");
      return null;
    }
  }

  // ---------------------------------------------------------
  // EXTENDED PROFILE SYSTEM (SPRING)
  // ---------------------------------------------------------
  static Future<Map<String, dynamic>?> fetchFullProfile(String studentName) async {
    final url = Uri.parse("$springUrl/profile/${Uri.encodeComponent(studentName)}");

    try {
      final res = await http.get(url).timeout(_httpTimeout);
      if (res.statusCode == 200 && res.body.isNotEmpty) {
        return jsonDecode(res.body);
      }
      print("fetchFullProfile non-200: ${res.statusCode} ${res.body}");
      return null;
    } on TimeoutException {
      print("fetchFullProfile timeout");
      return null;
    } catch (e) {
      print("❌ fetchFullProfile error: $e");
      return null;
    }
  }

  static Future<bool> updateFullProfile(String studentName, Map<String, dynamic> profileData) async {
    final url = Uri.parse("$springUrl/profile/${Uri.encodeComponent(studentName)}");

    try {
      final res = await http
          .put(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(profileData),
          )
          .timeout(_httpTimeout);

      // accept 200 OK or 204 No Content as success
      if (res.statusCode == 200 || res.statusCode == 204) return true;

      print("updateFullProfile failed: ${res.statusCode} ${res.body}");
      return false;
    } on TimeoutException {
      print("updateFullProfile timeout");
      return false;
    } catch (e) {
      print("❌ updateFullProfile error: $e");
      return false;
    }
  }

  // ---------------------------------------------------------
  // ATTENDANCE SYSTEM
  // ---------------------------------------------------------
  static Future<bool> markAttendance(String studentName) async {
    final url = Uri.parse("$springUrl/attendance/mark");

    try {
      final res = await http
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "studentName": studentName,
              "status": "PRESENT",
            }),
          )
          .timeout(_httpTimeout);

      return res.statusCode == 200;
    } on TimeoutException {
      print("markAttendance timeout");
      return false;
    } catch (e) {
      print("markAttendance error: $e");
      return false;
    }
  }

  static Future<bool> markAbsent(String studentName) async {
    final url = Uri.parse("$springUrl/attendance/mark");

    try {
      final res = await http
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "studentName": studentName,
              "status": "ABSENT",
            }),
          )
          .timeout(_httpTimeout);

      return res.statusCode == 200;
    } on TimeoutException {
      print("markAbsent timeout");
      return false;
    } catch (e) {
      print("markAbsent error: $e");
      return false;
    }
  }
}