class Student {
  final String regNo;
  final String name;
  final bool isPresent;
  final List<int> examScores;

  const Student({
    required this.regNo,
    required this.name,
    required this.isPresent,
    required this.examScores,
  });

  double get averageScore {
    if (examScores.isEmpty) return 0;
    return examScores.reduce((a, b) => a + b) / examScores.length;
  }

  String get performanceStatus {
    if (averageScore >= 80) return 'Excellent';
    if (averageScore >= 60) return 'Good';
    if (averageScore >= 40) return 'Average';
    return 'Poor';
  }

  String get teacherFeedback {
    if (averageScore >= 80) return 'Student is performing excellently. Keep monitoring progress.';
    if (averageScore >= 60) return 'Student is performing well. Continue regular assessments.';
    if (averageScore >= 40) return 'Student needs improvement. Consider additional support.';
    return 'Immediate attention required. Parents have been notified.';
  }

  String get actionRequired {
    if (averageScore >= 80) return 'Maintain current teaching methods';
    if (averageScore >= 60) return 'Provide occasional challenges';
    if (averageScore >= 40) return 'Schedule extra help sessions';
    return 'Contact parents and create intervention plan';
  }
}