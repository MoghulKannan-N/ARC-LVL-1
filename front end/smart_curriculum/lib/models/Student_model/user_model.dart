class User {
  final String name;
  final String studentId;
  final String email;
  final String bloodGroup;
  final String department;
  final String year;
  final List<String> strengths;
  final List<String> weaknesses;
  final List<String> interests;
  final String careerGoals;

  User({
    required this.name,
    required this.studentId,
    required this.email,
    required this.bloodGroup,
    required this.department,
    required this.year,
    required this.strengths,
    required this.weaknesses,
    required this.interests,
    required this.careerGoals,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name: json['name'],
      studentId: json['studentId'],
      email: json['email'],
      bloodGroup: json['bloodGroup'],
      department: json['department'],
      year: json['year'],
      strengths: List<String>.from(json['strengths']),
      weaknesses: List<String>.from(json['weaknesses']),
      interests: List<String>.from(json['interests']),
      careerGoals: json['careerGoals'],
    );
  }
}