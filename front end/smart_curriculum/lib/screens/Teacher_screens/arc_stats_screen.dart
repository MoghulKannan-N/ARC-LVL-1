import 'package:flutter/material.dart';
import 'package:smart_curriculum/utils/constants.dart';

class ArcStatsScreen extends StatelessWidget {
  const ArcStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("ARC's Stats"),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const SizedBox(height: 10),
            const Text(
              "Analytics Overview",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textColor,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "This dashboard shows summarized academic performance and attendance insights powered by ARC’s AI engine.",
              style: TextStyle(color: AppColors.subtitleColor, fontSize: 14),
            ),
            const SizedBox(height: 20),

            // ---- Stats Cards ----
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                _ArcStatCard(title: "Avg Attendance", value: "92%"),
                _ArcStatCard(title: "Class Accuracy", value: "87%"),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                _ArcStatCard(title: "AI Predictions", value: "120"),
                _ArcStatCard(title: "Students Monitored", value: "58"),
              ],
            ),

            const SizedBox(height: 30),
            const Text(
              "Recent Trends",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textColor,
              ),
            ),
            const SizedBox(height: 12),
            _trendTile("Attendance Growth", "Steady 4% increase this month"),
            _trendTile("Top Performing Course", "AI & Data Science"),
            _trendTile("Lowest Attendance Day", "Monday"),
            _trendTile("ARC’s Next Recommendation", "Increase engagement in ML labs"),

            const SizedBox(height: 30),
            const Text(
              "AI Summary",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textColor,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade300,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: const Text(
                "ARC’s analysis indicates strong academic engagement. "
                "Students show consistent attendance patterns and high learning retention. "
                "Focus on improving participation during early-week sessions for balanced performance.",
                style: TextStyle(color: AppColors.subtitleColor, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------
// Reusable Components
// ------------------------------------------------------

class _ArcStatCard extends StatelessWidget {
  final String title;
  final String value;

  const _ArcStatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor)),
            const SizedBox(height: 4),
            Text(title,
                style: const TextStyle(
                    fontSize: 14, color: AppColors.subtitleColor)),
          ],
        ),
      ),
    );
  }
}

Widget _trendTile(String title, String subtitle) {
  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    margin: const EdgeInsets.symmetric(vertical: 6),
    child: ListTile(
      leading: const Icon(Icons.trending_up, color: AppColors.primaryColor),
      title: Text(title,
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: AppColors.textColor)),
      subtitle: Text(subtitle,
          style:
              const TextStyle(fontSize: 13, color: AppColors.subtitleColor)),
    ),
  );
}
