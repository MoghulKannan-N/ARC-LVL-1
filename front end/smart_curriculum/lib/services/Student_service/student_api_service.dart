// lib/services/Student_service/student_api_service.dart
// Combined file: NEW ApiService (active) + LEGACY ApiService (preserved verbatim in block comment)

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

  // default timeout for HTTP calls (increased slightly for AI calls)
  static const Duration _httpTimeout = Duration(seconds: 12);

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

  // ---------------------- Generic helpers ----------------------

  static Future<Map<String, dynamic>?> _post(
    String base,
    String path,
    Map<String, String> body, {
    Duration? timeout,
  }) async {
    final uri = Uri.parse("$base$path");
    try {
      final res = await http.post(uri, body: body).timeout(timeout ?? _httpTimeout);
      return _handleResponse(res);
    } on TimeoutException {
      print("POST timeout: ${uri.toString()}");
      return {"_error": "timeout"};
    } catch (e) {
      print("POST error: ${uri.toString()} -> $e");
      return {"_error": e.toString()};
    }
  }

  static Future<Map<String, dynamic>?> _get(
    String base,
    String path, {
    Map<String, String>? query,
    Duration? timeout,
  }) async {
    final uri = Uri.parse("$base$path").replace(queryParameters: query);
    try {
      final res = await http.get(uri).timeout(timeout ?? _httpTimeout);
      return _handleResponse(res);
    } on TimeoutException {
      print("GET timeout: ${uri.toString()}");
      return {"_error": "timeout"};
    } catch (e) {
      print("GET error: ${uri.toString()} -> $e");
      return {"_error": e.toString()};
    }
  }

  static Map<String, dynamic>? _handleResponse(http.Response res) {
    try {
      final body = res.body;
      if (res.statusCode >= 200 && res.statusCode < 300) {
        if (body.isEmpty) return {};
        final parsed = jsonDecode(body);
        if (parsed is Map<String, dynamic>) return parsed;
        // if API returns list, wrap it
        return {"_list": parsed};
      } else {
        print("HTTP error ${res.statusCode}: ${res.body}");
        return {"_error": "status_${res.statusCode}", "body": res.body};
      }
    } catch (e) {
      print("Response parse error: $e");
      return {"_error": "parse_error", "raw": res.body};
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

  // ---------------------- AI / Backend endpoints (FastAPI) ----------------------

  /// GET /progress_roadmap?student_id=...
  static Future<Map<String, dynamic>?> fetchProgress(int studentId) async {
    final res = await _get(aiBase, "/progress_roadmap", query: {"student_id": studentId.toString()});
    return res;
  }

  /// POST /generate_roadmap (student_id, topic)
  /// NO TIMEOUT because GPT-5.0 Nano roadmap generation may take longer
  static Future<Map<String, dynamic>?> generateRoadmap(int studentId, String topic) async {
    final uri = Uri.parse("$aiBase/generate_roadmap");

    try {
      // No timeout applied here
      final res = await http.post(
        uri,
        body: {
          "student_id": studentId.toString(),
          "topic": topic,
        },
      );

      // Handle response normally
      return _handleResponse(res);
    } catch (e) {
      print("generateRoadmap error: $e");
      return {"_error": e.toString()};
    }
  }

  /// GET /open_mini_session?mini_session_id=...
/// Note: backend expects a mini_session_id (id from mini_sessions table)
  static Future<Map<String, dynamic>?> openMiniSession(int miniSessionId) async {
    final uri = Uri.parse("$aiBase/open_mini_session").replace(queryParameters: {
      "mini_session_id": miniSessionId.toString(),
    });

    try {
      // No timeout here (may generate content)
      final res = await http.get(uri);
      // _handleResponse exists in the same file — reuse it
      return _handleResponse(res);
    } catch (e) {
      print("openMiniSession error: $e");
      return {"_error": e.toString()};
    }
  }

  /// GET /next_mini_session?student_id=...
  /// NO TIMEOUT: grading & splitting can take longer
  static Future<Map<String, dynamic>?> getNextMiniSession(int studentId) async {
    final uri = Uri.parse("$aiBase/next_mini_session").replace(queryParameters: {
      "student_id": studentId.toString(),
    });

    try {
      // No timeout applied here
      final res = await http.get(uri);
      return _handleResponse(res);
    } catch (e) {
      print("getNextMiniSession error: $e");
      return {"_error": e.toString()};
    }
  }

  /// GET /mini_sessions_list?student_id=...&roadmap_id=...
/// Returns a List of mini session objects or null on error.
static Future<List<dynamic>?> fetchMiniSessions({
  required int studentId,
  int? roadmapId,
}) async {
  final query = {
    "student_id": studentId.toString(),
    if (roadmapId != null) "roadmap_id": roadmapId.toString(),
  };

  final res = await _get(aiBase, "/mini_sessions_list", query: query);

  if (res == null) return null;

  // If backend returned a map, try to extract known keys
  if (res is Map<String, dynamic>) {
    // Common shape: {"student_id":..., "mini_sessions":[ ... ]}
    if (res.containsKey("mini_sessions") && res["mini_sessions"] is List) {
      return List<dynamic>.from(res["mini_sessions"] as List);
    }

    // Older wrapper: {"_list": [...]}
    if (res.containsKey("_list") && res["_list"] is List) {
      return List<dynamic>.from(res["_list"] as List);
    }

    // If API returned a single mini_session object (unlikely) — wrap it in a list
    if (res.containsKey("id")) {
      return [res];
    }
  }

  // Unknown shape -> return null so caller falls back safely
  return null;
}

  /// POST /complete_mini_session
  /// answersMap: Map<int,String> where key is question index and value is chosen option (string)
  /// NO TIMEOUT: splitting + new AI content generation may be slow
  static Future<Map<String, dynamic>?> completeMiniSession({
    required int studentId,
    required int miniSessionId,
    required Map<int, String> answersMap,
  }) async {
    final uri = Uri.parse("$aiBase/complete_mini_session");

    final answersJson =
        jsonEncode({"answers": answersMap.map((k, v) => MapEntry(k.toString(), v))});

    try {
      final res = await http.post(
        uri,
        body: {
          "student_id": studentId.toString(),
          "mini_session_id": miniSessionId.toString(),
          "quiz_answers": answersJson,
        },
      );

      return _handleResponse(res);
    } catch (e) {
      print("completeMiniSession error: $e");
      return {"_error": e.toString()};
    }
  }
  

  /// POST /chatbot (message)
  static Future<String?> chatbot(String message) async {
    final res = await _post(aiBase, "/chatbot", {"message": message}, timeout: Duration(seconds: 20));
    if (res == null || res.containsKey("_error")) return null;
    // API returns {"reply": "..."}
    return (res["reply"] ?? "").toString();
  }

  // ---------------------- Admin helpers ----------------------
  static Future<List<dynamic>?> listStudents() async {
    try {
      final uri = Uri.parse("$aiBase/list_students");
      final res = await http.get(uri).timeout(_httpTimeout);
      if (res.statusCode == 200) {
        final parsed = jsonDecode(res.body);
        if (parsed is List) return parsed;
        // if server returned {"_list": [...]} from wrapper
        if (parsed is Map && parsed.containsKey("_list")) return parsed["_list"];
      }
    } catch (e) {
      print("listStudents error: $e");
    }
    return null;
  }

  static Future<Map<String, dynamic>?> addStudent({
    required String studentName,
    String? dateOfBirth,
    String? phoneNumber,
    String? strength,
    String? weakness,
    String? interest,
    String? yearOfStudying,
    String? course,
  }) async {
    final data = {
      "student_name": studentName,
      "date_of_birth": dateOfBirth ?? "",
      "phone_number": phoneNumber ?? "",
      "strength": strength ?? "",
      "weakness": weakness ?? "",
      "interest": interest ?? "",
      "year_of_studying": yearOfStudying ?? "",
      "course": course ?? "",
    };
    final uri = Uri.parse("$aiBase/add_student");
    try {
      final res = await http.post(uri, body: data).timeout(_httpTimeout);
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      } else {
        return {"_error": "status_${res.statusCode}", "body": res.body};
      }
    } catch (e) {
      print("addStudent error: $e");
      return {"_error": e.toString()};
    }
  }
}