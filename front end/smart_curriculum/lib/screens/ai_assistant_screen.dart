import 'package:flutter/material.dart';
import 'package:smart_curriculum/utils/constants.dart';
import '../models/task_model.dart';

class AIAssistantScreen extends StatelessWidget {
  const AIAssistantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample data - will be replaced with API data
    final List<Task> tasks = [
      Task(
        id: '1',
        title: 'Security Fundamentals',
        description: 'Learn the basics of cybersecurity',
        type: 'Course',
        duration: '2h 30m',
        completed: false,
      ),
      Task(
        id: '2',
        title: 'Ethical Hacking',
        description: 'Introduction to ethical hacking techniques',
        type: 'Tutorial',
        duration: '1h 15m',
        completed: false,
      ),
      Task(
        id: '3',
        title: 'Network Security',
        description: 'Securing network infrastructure',
        type: 'Course',
        duration: '1h 45m',
        completed: false,
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            AppStrings.aiAssistant,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textColor,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.warningColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.warningColor),
            ),
            child: const Text(
              AppStrings.freePeriodDetected,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          RichText(
            text: const TextSpan(
              text: '${AppStrings.welcome}, ',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textColor,
              ),
              children: [
                TextSpan(
                  text: 'Dhanapriyan S!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Based on your interests and academic performance, we've prepared personalized learning resources for you.",
            style: TextStyle(
              fontSize: 16,
              color: AppColors.subtitleColor,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            AppStrings.recommendedResources,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textColor,
            ),
          ),
          const SizedBox(height: 24),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        task.description,
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.subtitleColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Chip(
                            label: Text(task.type),
                            backgroundColor: AppColors.primaryColor.withOpacity(0.1),
                          ),
                          const Spacer(),
                          Text(
                            task.duration,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.subtitleColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}