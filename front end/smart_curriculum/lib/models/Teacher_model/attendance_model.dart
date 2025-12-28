class Attendance {
  final String id;
  final String studentId;
  final String studentName;
  final DateTime date;
  final bool isPresent;
  final String classId;
  final String method; // QR, Bluetooth, Face

  Attendance({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.date,
    required this.isPresent,
    required this.classId,
    required this.method,
  });

  // Convert to JSON for API calls
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'date': date.toIso8601String(),
      'isPresent': isPresent,
      'classId': classId,
      'method': method,
    };
  }

  // Create from JSON
  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'],
      studentId: json['studentId'],
      studentName: json['studentName'],
      date: DateTime.parse(json['date']),
      isPresent: json['isPresent'],
      classId: json['classId'],
      method: json['method'],
    );
  }

  // Get formatted date string
  String get formattedDate {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Get formatted time string
  String get formattedTime {
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  // Get status text with color indicator
  String get statusText {
    return isPresent ? 'Present' : 'Absent';
  }

  // Get status color
  String get statusColor {
    return isPresent ? 'green' : 'red';
  }
}

class AttendanceRecord {
  final String studentId;
  final String studentName;
  final List<Attendance> attendanceList;

  AttendanceRecord({
    required this.studentId,
    required this.studentName,
    required this.attendanceList,
  });

  // Calculate attendance percentage
  double get attendancePercentage {
    if (attendanceList.isEmpty) return 0.0;
    
    final presentCount = attendanceList.where((att) => att.isPresent).length;
    return (presentCount / attendanceList.length) * 100;
  }

  // Get formatted percentage string
  String get formattedPercentage {
    return '${attendancePercentage.toStringAsFixed(1)}%';
  }

  // Get attendance status
  String get attendanceStatus {
    if (attendancePercentage >= 90) return 'Excellent';
    if (attendancePercentage >= 80) return 'Good';
    if (attendancePercentage >= 70) return 'Average';
    return 'Poor';
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'attendanceList': attendanceList.map((att) => att.toJson()).toList(),
      'attendancePercentage': attendancePercentage,
      'attendanceStatus': attendanceStatus,
    };
  }

  // Create from JSON
  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      studentId: json['studentId'],
      studentName: json['studentName'],
      attendanceList: (json['attendanceList'] as List)
          .map((item) => Attendance.fromJson(item))
          .toList(),
    );
  }
}

class ClassAttendance {
  final String classId;
  final String className;
  final DateTime date;
  final List<Attendance> attendanceList;
  final int totalStudents;
  final int presentStudents;

  ClassAttendance({
    required this.classId,
    required this.className,
    required this.date,
    required this.attendanceList,
    required this.totalStudents,
    required this.presentStudents,
  });

  // Calculate attendance percentage for the class
  double get classAttendancePercentage {
    if (totalStudents == 0) return 0.0;
    return (presentStudents / totalStudents) * 100;
  }

  // Get formatted percentage string
  String get formattedClassPercentage {
    return '${classAttendancePercentage.toStringAsFixed(1)}%';
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'classId': classId,
      'className': className,
      'date': date.toIso8601String(),
      'attendanceList': attendanceList.map((att) => att.toJson()).toList(),
      'totalStudents': totalStudents,
      'presentStudents': presentStudents,
      'classAttendancePercentage': classAttendancePercentage,
    };
  }

  // Create from JSON
  factory ClassAttendance.fromJson(Map<String, dynamic> json) {
    return ClassAttendance(
      classId: json['classId'],
      className: json['className'],
      date: DateTime.parse(json['date']),
      attendanceList: (json['attendanceList'] as List)
          .map((item) => Attendance.fromJson(item))
          .toList(),
      totalStudents: json['totalStudents'],
      presentStudents: json['presentStudents'],
    );
  }
}

// Dummy data generator for testing
class AttendanceData {
  static List<Attendance> generateDummyAttendance() {
    return [
      Attendance(
        id: '1',
        studentId: '727724EUCS018',
        studentName: 'Dhanapriyan S',
        date: DateTime.now(),
        isPresent: true,
        classId: 'CS101',
        method: 'Bluetooth',
      ),
      Attendance(
        id: '2',
        studentId: '727724EUCS019',
        studentName: 'John Doe',
        date: DateTime.now(),
        isPresent: true,
        classId: 'CS101',
        method: 'Bluetooth',
      ),
      Attendance(
        id: '3',
        studentId: '727724EUCS020',
        studentName: 'Jane Smith',
        date: DateTime.now(),
        isPresent: false,
        classId: 'CS101',
        method: 'Bluetooth',
      ),
      Attendance(
        id: '4',
        studentId: '727724EUCS021',
        studentName: 'Robert Johnson',
        date: DateTime.now(),
        isPresent: true,
        classId: 'CS101',
        method: 'Bluetooth',
      ),
      Attendance(
        id: '5',
        studentId: '727724EUCS022',
        studentName: 'Sarah Wilson',
        date: DateTime.now(),
        isPresent: true,
        classId: 'CS101',
        method: 'Bluetooth',
      ),
    ];
  }

  static AttendanceRecord generateDummyAttendanceRecord(String studentId, String studentName) {
    return AttendanceRecord(
      studentId: studentId,
      studentName: studentName,
      attendanceList: [
        Attendance(
          id: '1',
          studentId: studentId,
          studentName: studentName,
          date: DateTime.now().subtract(const Duration(days: 4)),
          isPresent: true,
          classId: 'CS101',
          method: 'QR',
        ),
        Attendance(
          id: '2',
          studentId: studentId,
          studentName: studentName,
          date: DateTime.now().subtract(const Duration(days: 3)),
          isPresent: false,
          classId: 'CS101',
          method: 'Bluetooth',
        ),
        Attendance(
          id: '3',
          studentId: studentId,
          studentName: studentName,
          date: DateTime.now().subtract(const Duration(days: 2)),
          isPresent: true,
          classId: 'CS101',
          method: 'Face',
        ),
        Attendance(
          id: '4',
          studentId: studentId,
          studentName: studentName,
          date: DateTime.now().subtract(const Duration(days: 1)),
          isPresent: true,
          classId: 'CS101',
          method: 'Bluetooth',
        ),
        Attendance(
          id: '5',
          studentId: studentId,
          studentName: studentName,
          date: DateTime.now(),
          isPresent: true,
          classId: 'CS101',
          method: 'Bluetooth',
        ),
      ],
    );
  }
}