import 'package:flutter/material.dart';
import 'package:smart_curriculum/utils/constants.dart';
import 'package:smart_curriculum/services/Teacher_service/teacher_api_service.dart';
import 'package:smart_curriculum/screens/Teacher_screens/add_student_screen.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen>
    with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> students = [];
  bool loading = true;
  bool updating = false;

  @override
  void initState() {
    super.initState();
    loadStudents();
  }

  @override
  bool get wantKeepAlive => true;

  Future<void> loadStudents() async {
    setState(() => loading = true);

    final data = await ApiService.getAllStudents();
    if (data == null) {
      setState(() {
        students = [];
        loading = false;
      });
      return;
    }

    List<Map<String, dynamic>> merged = [];
    for (var s in data) {
      final name = (s["name"]?.toString().trim().isNotEmpty ?? false)
          ? s["name"]
          : "Kavin";
      String? status = await ApiService.getAttendanceStatus(name);
      merged.add({
        "name": name,
        "status": status ?? "UNKNOWN",
      });
    }

    setState(() {
      students = merged;
      loading = false;
    });
  }

  Future<void> changeStatus(String studentName, String status) async {
    setState(() => updating = true);

    final ok = await ApiService.updateAttendanceStatus(studentName, status);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? "Attendance updated successfully"
              : "Failed to update attendance",
        ),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );

    await loadStudents();
    setState(() => updating = false);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,

      /// 🔹 BODY WITH FLOATING + IN WHITE AREA
      body: Stack(
        children: [
          loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: loadStudents,
                  color: AppColors.primaryColor,
                  child: students.isEmpty
                      ? const Center(
                          child: Text(
                            "No students found.",
                            style: TextStyle(color: AppColors.subtitleColor),
                          ),
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(
                              12, 80, 12, 12), // 👈 space for +
                          itemCount: students.length,
                          itemBuilder: (context, index) {
                            final s = students[index];
                            final name = s["name"] ?? "Kavin";
                            final status = s["status"] ?? "UNKNOWN";

                            Color color = Colors.grey;
                            if (status == "PRESENT") color = Colors.green;
                            if (status == "ABSENT") color = Colors.red;
                            if (status == "LATE") color = Colors.orange;

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
                                          color: Colors.white),
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            "Status: $status",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: color,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.edit,
                                          color: AppColors.primaryColor),
                                      onSelected: (value) =>
                                          changeStatus(name, value),
                                      itemBuilder: (context) => const [
                                        PopupMenuItem(
                                          value: "PRESENT",
                                          child: Text("Mark as PRESENT"),
                                        ),
                                        PopupMenuItem(
                                          value: "ABSENT",
                                          child: Text("Mark as ABSENT"),
                                        ),
                                        PopupMenuItem(
                                          value: "LATE",
                                          child: Text("Mark as LATE"),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),

          /// 🔹 BLUE CIRCLE + BUTTON (WHITE AREA)
          Positioned(
            top: 16,
            right: 16,
            child: FloatingActionButton(
              backgroundColor: AppColors.primaryColor,
              elevation: 4,
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddStudentScreen()),
                );
                await loadStudents();
              },
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
