import 'dart:convert';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';

class TeacherSocketService {
  static StompClient? _client;

  static void connect({
    required int teacherId,
    required Function(String message) onAlert,
  }) {
    _client = StompClient(
      config: StompConfig.sockJS(
        url: 'http://<YOUR_SPRING_IP>:8081/ws',
        onConnect: (StompFrame frame) {
          print("✅ Teacher WebSocket connected");

          _client!.subscribe(
            destination: '/topic/teacher/$teacherId',
            callback: (frame) {
              if (frame.body != null) {
                final data = jsonDecode(frame.body!);
                onAlert(data["message"]);
              }
            },
          );
        },
        onWebSocketError: (error) {
          print("❌ WebSocket error: $error");
        },
      ),
    );

    _client!.activate();
  }

  static void disconnect() {
    _client?.deactivate();
  }
}
