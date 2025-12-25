import 'package:flutter/material.dart';

class SessionWarningDialog {
  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("⚠ Attendance Warning"),
        content: const Text(
          "Please do not exit the app during attendance.\n"
          "Your teacher will be notified if you leave.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}
