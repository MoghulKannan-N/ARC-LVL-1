import 'package:flutter/material.dart';
import 'package:smart_curriculum/utils/constants.dart';
import 'package:smart_curriculum/services/Teacher_service/teacher_api_service.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  List<Map<String, dynamic>> students = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadStudents();
  }

  // ------------------------------------------------------
  // LOAD ALL STUDENTS
  // ------------------------------------------------------
  Future<void> loadStudents() async {
    final data = await ApiService.getAllStudents();

    setState(() {
      students = data ?? [];
      loading = false;
    });
  }

  // ------------------------------------------------------
  // UPDATE ATTENDANCE STATUS
  // ------------------------------------------------------
  Future<void> changeStatus(String studentName, String status) async {
    final ok = await ApiService.updateAttendanceStatus(studentName, status);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? "Attendance updated" : "Failed to update"),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );

    setState(() {}); // refresh UI
  }

  // ------------------------------------------------------
  // UI
  // ------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text("Attendance Management"),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: students.length,
              itemBuilder: (context, index) {
                final s = students[index];

                return Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.primaryColor,
                          child: Icon(Icons.person,
                              size: 30, color: Colors.white),
                        ),

                        const SizedBox(width: 15),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s["name"],
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textColor,
                                ),
                              ),

                              const SizedBox(height: 5),

                              FutureBuilder<String?>(
                                future:
                                    ApiService.getAttendanceStatus(s["name"]),
                                builder: (context, snapshot) {
                                  final status = snapshot.data ?? "UNKNOWN";

                                  Color color = Colors.grey;
                                  if (status == "PRESENT") color = Colors.green;
                                  if (status == "ABSENT") color = Colors.red;
                                  if (status == "LATE") color = Colors.orange;

                                  return Text(
                                    "Status: $status",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: color,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        PopupMenuButton(
                          icon: const Icon(Icons.edit,
                              color: AppColors.primaryColor),
                          onSelected: (value) =>
                              changeStatus(s["name"], value),
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                                value: "PRESENT",
                                child: Text("Mark as PRESENT")),
                            PopupMenuItem(
                                value: "ABSENT",
                                child: Text("Mark as ABSENT")),
                            PopupMenuItem(
                                value: "LATE",
                                child: Text("Mark as LATE")),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
