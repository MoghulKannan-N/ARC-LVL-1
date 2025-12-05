import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smart_curriculum/config.dart'; // ✅ corrected import path

class ApiService {
  static const String baseUrl = "$sb/api";

  // Store logged-in teacher username + name
  static String? loggedInTeacherUsername;
  static String? loggedInTeacherName;

  // --------------------------------------------------------
  // TEACHER LOGIN (Stores teacherName too)
  // --------------------------------------------------------
  static Future<bool> teacherLogin(String username, String password) async {
    final url = Uri.parse("$baseUrl/auth/teacher/login");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": username,
          "password": password,
        }),
      );

      final ok = response.statusCode == 200 &&
          response.body.trim() == "Teacher login successful";

      if (ok) {
        loggedInTeacherUsername = username;

        // Fetch teacher profile to get real name
        final profile = await getTeacherProfile();
        if (profile != null && profile["name"] != null) {
          loggedInTeacherName = profile["name"];
          print("Teacher logged in as: $loggedInTeacherName");
        } else {
          print("Teacher profile fetch failed.");
        }
      }

      return ok;
    } catch (e) {
      print("teacherLogin error: $e");
      return false;
    }
  }

  // --------------------------------------------------------
  // GET TEACHER PROFILE
  // --------------------------------------------------------
  static Future<Map<String, dynamic>?> getTeacherProfile() async {
    if (loggedInTeacherUsername == null) return null;

    final url = Uri.parse(
        "$baseUrl/teacher/me?username=$loggedInTeacherUsername");

    try {
      final res = await http.get(url);

      if (res.statusCode == 200 && res.body.isNotEmpty) {
        return jsonDecode(res.body);
      }

      return null;
    } catch (e) {
      print("getTeacherProfile error -> $e");
      return null;
    }
  }

  // --------------------------------------------------------
  // ADD STUDENT
  // --------------------------------------------------------
  static Future<bool> addStudent({
    required int teacherId,
    required String name,
    required String username,
    required String password,
  }) async {
    final url = Uri.parse("$baseUrl/teacher/$teacherId/add-student");

    try {
      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": name,
          "username": username,
          "password": password,
        }),
      );

      return res.statusCode == 200;
    } catch (e) {
      print("addStudent error: $e");
      return false;
    }
  }

  // --------------------------------------------------------
  // CHECK STUDENT EXISTS
  // --------------------------------------------------------
  static Future<bool> checkStudentExists(String name) async {
    final url = Uri.parse("$baseUrl/auth/check-student?name=$name");

    try {
      final res = await http.get(url);
      return res.statusCode == 200 && res.body.trim() == "exists";
    } catch (e) {
      print("checkStudentExists error: $e");
      return false;
    }
  }

  // --------------------------------------------------------
  // GET ALL STUDENTS
  // --------------------------------------------------------
  static Future<List<Map<String, dynamic>>?> getAllStudents() async {
    final url = Uri.parse("$baseUrl/student/all");

    try {
      final res = await http.get(url);

      if (res.statusCode == 200 && res.body.isNotEmpty) {
        return List<Map<String, dynamic>>.from(jsonDecode(res.body));
      }

      return null;
    } catch (e) {
      print("getAllStudents error: $e");
      return null;
    }
  }

  // --------------------------------------------------------
  // GET LATEST ATTENDANCE STATUS
  // --------------------------------------------------------
  static Future<String?> getAttendanceStatus(String studentName) async {
    final url =
        Uri.parse("$baseUrl/attendance/status?studentName=$studentName");

    try {
      final res = await http.get(url);

      if (res.statusCode == 200 && res.body.isNotEmpty) {
        final data = jsonDecode(res.body);
        return data["status"] ?? "UNKNOWN";
      }

      return null;
    } catch (e) {
      print("getAttendanceStatus error: $e");
      return null;
    }
  }

  // --------------------------------------------------------
  // UPDATE ATTENDANCE — MUST SEND teacherName
  // --------------------------------------------------------
  static Future<bool> updateAttendanceStatus(
      String studentName, String newStatus) async {
    if (loggedInTeacherName == null) {
      print("ERROR: Teacher not logged in, no teacherName");
      return false;
    }

    final url = Uri.parse("$baseUrl/attendance/update");

    try {
      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "studentName": studentName,
          "status": newStatus,
          "teacherName": loggedInTeacherName, // REQUIRED
        }),
      );

      print("Update response: ${res.statusCode} | ${res.body}");

      return res.statusCode == 200;
    } catch (e) {
      print("updateAttendanceStatus error: $e");
      return false;
    }
  }
}
