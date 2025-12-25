import 'package:smart_curriculum/services/Student_service/student_api_service.dart';

class SessionMonitorService {

  static bool _exitSent = false;

  static Future<void> onStudentExit() async {
    if (_exitSent) return;

    try {
      _exitSent = true;
      await ApiService.notifyStudentExit();
    } catch (e) {
      // fail silently
    }
  }
}
