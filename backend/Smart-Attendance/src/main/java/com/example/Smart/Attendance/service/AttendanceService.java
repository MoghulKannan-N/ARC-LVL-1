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
    AttendanceRepository attendanceRepo;

    @Autowired
    StudentRepository studentRepo;

    @Autowired
    TeacherRepository teacherRepo;

    // ✔ MARK ATTENDANCE (student-side → teacherName="SYSTEM")
    public Attendance markAttendance(String studentName, String status, String teacherName) {

        Student student = studentRepo.findByName(studentName)
                .orElseThrow(() -> new RuntimeException("Student not found: " + studentName));

        Attendance att = new Attendance();
        att.setStudentId(student.getId());
        att.setStudentName(student.getName());

        if (!"SYSTEM".equals(teacherName)) {
            Teacher teacher = teacherRepo.findByName(teacherName)
                    .orElseThrow(() -> new RuntimeException("Teacher not found: " + teacherName));

            att.setTeacherId(teacher.getId());
            att.setTeacherName(teacher.getName());
        } else {
            att.setTeacherId(0L);
            att.setTeacherName("SYSTEM");
        }

        att.setStatus(status);
        att.setMarkedAt(LocalDateTime.now());
        return attendanceRepo.save(att);
    }

    // GET LATEST STATUS
    public Attendance getLatestAttendance(String studentName) {
        return attendanceRepo.findTopByStudentNameOrderByMarkedAtDesc(studentName)
                .orElse(null);
    }

    // ✔ TEACHER MANUAL UPDATE
    public Attendance updateAttendance(String studentName, String newStatus, String teacherName) {

        Student student = studentRepo.findByName(studentName)
                .orElseThrow(() -> new RuntimeException("Student not found: " + studentName));

        Teacher teacher = teacherRepo.findByName(teacherName)
                .orElseThrow(() -> new RuntimeException("Teacher not found: " + teacherName));

        Attendance latest = attendanceRepo.findTopByStudentNameOrderByMarkedAtDesc(studentName)
                .orElse(new Attendance());

        latest.setStudentId(student.getId());
        latest.setStudentName(student.getName());
        latest.setTeacherId(teacher.getId());
        latest.setTeacherName(teacher.getName());
        latest.setStatus(newStatus);
        latest.setMarkedAt(LocalDateTime.now());

        return attendanceRepo.save(latest);
    }
}
