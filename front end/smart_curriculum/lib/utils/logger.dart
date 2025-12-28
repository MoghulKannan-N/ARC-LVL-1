import 'dart:developer' as developer;

class Logger {
  static void log(String message, {String? name}) {
    developer.log(message, name: name ?? 'ApiService');
  }

  static void error(String message, {String? name}) {
    developer.log('❌ $message', name: name ?? 'ApiService');
  }

  static void success(String message, {String? name}) {
    developer.log('🎯 $message', name: name ?? 'ApiService');
  }

  static void info(String message, {String? name}) {
    developer.log('🔹 $message', name: name ?? 'ApiService');
  }
}
