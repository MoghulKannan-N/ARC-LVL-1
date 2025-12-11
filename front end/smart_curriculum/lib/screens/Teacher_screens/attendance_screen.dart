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

  // ------------------ Load Students ------------------
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

  // ---------------- Update Attendance -----------------
  Future<void> changeStatus(String studentName, String status) async {
    setState(() => updating = true);

    final ok = await ApiService.updateAttendanceStatus(studentName, status);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? "Attendance updated successfully"
            : "Failed to update attendance"),
        backgroundColor: ok ? Colors.green : Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );

    await loadStudents();
    setState(() => updating = false);
  }

  // ----------------------- UI -------------------------
  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false, // ✅ Prevents back arrow
        title: const Text("Attendance Management"),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddStudentScreen()),
              );
              await loadStudents();
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add,
                  size: 26,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
          ),
        ],
      ),

      body: loading
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
                      padding: const EdgeInsets.all(12),
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
                                      size: 30, color: Colors.white),
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
                                          color: AppColors.textColor,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        "Status: $status",
                                        style: TextStyle(
                                          fontSize: 15,
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

      // Keep bottom nav visible — no floating overlays
      floatingActionButton: updating
          ? Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            )
          : null,
    );
  }
}
