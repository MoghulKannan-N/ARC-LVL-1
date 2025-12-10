package com.example.Smart.Attendance.service;

import com.example.Smart.Attendance.model.Attendance;
import com.example.Smart.Attendance.model.Student;
import com.example.Smart.Attendance.model.Teacher;
import com.example.Smart.Attendance.repository.AttendanceRepository;
import com.example.Smart.Attendance.repository.StudentRepository;
import com.example.Smart.Attendance.repository.TeacherRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;

@Service
public class AttendanceService {

    @Autowired
    private AttendanceRepository attendanceRepo;

    @Autowired
    private StudentRepository studentRepo;

    @Autowired
    private TeacherRepository teacherRepo;

    // MARK OR UPDATE ATTENDANCE (Student or Teacher)
    public Attendance markAttendance(String studentName, String status, String teacherName) {

        Student student = studentRepo.findByName(studentName)
                .orElseThrow(() -> new RuntimeException("Student not found: " + studentName));

        Attendance att = attendanceRepo.findById(student.getId()).orElse(new Attendance());
        att.setStudentId(student.getId());
        att.setStudentName(student.getName());
        att.setStatus(status);
        att.setMarkedAt(LocalDateTime.now());

        if (!"SYSTEM".equals(teacherName)) {
            Teacher teacher = teacherRepo.findByName(teacherName)
                    .orElseThrow(() -> new RuntimeException("Teacher not found: " + teacherName));
            att.setTeacherId(teacher.getId());
            att.setTeacherName(teacher.getName());
        } else {
            att.setTeacherId(0L);
            att.setTeacherName("SYSTEM");
        }

        return attendanceRepo.save(att); // 🔹 save() updates same row
    }

    // GET CURRENT ATTENDANCE STATUS
    public Attendance getAttendance(String studentName) {
        return attendanceRepo.findByStudentName(studentName)
                .orElse(null);
    }

    // MANUAL UPDATE BY TEACHER
    public Attendance updateAttendance(String studentName, String newStatus, String teacherName) {
        return markAttendance(studentName, newStatus, teacherName);
    }
}
