import 'dart:async';

enum AttendanceState {
  idle,
  scanning,
  candidateDetected,
  awaitingFaceVerification,
  faceVerified,
  submitting,
  success,
  rejected
}

class AttendanceEvent {
  final AttendanceState state;
  final String? sessionId;
  final String? reason;

  AttendanceEvent(this.state, {this.sessionId, this.reason});
}

/// Holds cryptographic submission data
class AttendancePayload {
  final int? studentId;
  final String? nonce;
  final String? signature;

  AttendancePayload({this.studentId, this.nonce, this.signature});
}

/// Deterministic attendance state machine
class AttendanceStateManager {
  static final StreamController<AttendanceEvent> _controller =
      StreamController<AttendanceEvent>.broadcast();

  static AttendanceState _current = AttendanceState.idle;
  static AttendancePayload? _currentPayload;

  static Stream<AttendanceEvent> get stream => _controller.stream;

  static AttendanceState get current => _current;
  static AttendancePayload? get currentPayload => _currentPayload;

  static void setPayload(AttendancePayload payload) {
    _currentPayload = payload;
  }

  static void clearPayload() {
    _currentPayload = null;
  }

  static void emit(AttendanceState state,
      {String? sessionId, String? reason}) {
    _current = state;
    _controller.add(
      AttendanceEvent(state, sessionId: sessionId, reason: reason),
    );

    // 🔒 Clear cryptographic material on terminal states
    if (state == AttendanceState.success ||
        state == AttendanceState.rejected) {
      clearPayload();
    }
  }

  static void dispose() {
    _controller.close();
  }
}
