class Task {
  final String id;
  final String title;
  final String description;
  final String type;
  final String duration;
  final bool completed;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.duration,
    required this.completed,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      type: json['type'],
      duration: json['duration'],
      completed: json['completed'],
    );
  }
}