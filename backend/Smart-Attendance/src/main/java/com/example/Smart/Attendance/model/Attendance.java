package com.example.Smart.Attendance.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "attendance")
public class Attendance {

    @Id
    private Long studentId; // 🔹 Primary Key — one record per student

    @Column(nullable = false)
    private String studentName;

    private String status; // PRESENT / ABSENT / LATE etc.
    private LocalDateTime markedAt = LocalDateTime.now();

    private Long teacherId;
    private String teacherName;

    // --- Getters and Setters ---
    public Long getStudentId() {
        return studentId;
    }
    public void setStudentId(Long studentId) {
        this.studentId = studentId;
    }

    public String getStudentName() {
        return studentName;
    }
    public void setStudentName(String studentName) {
        this.studentName = studentName;
    }

    public String getStatus() {
        return status;
    }
    public void setStatus(String status) {
        this.status = status;
    }

    public LocalDateTime getMarkedAt() {
        return markedAt;
    }
    public void setMarkedAt(LocalDateTime markedAt) {
        this.markedAt = markedAt;
    }

    public Long getTeacherId() {
        return teacherId;
    }
    public void setTeacherId(Long teacherId) {
        this.teacherId = teacherId;
    }

    public String getTeacherName() {
        return teacherName;
    }
    public void setTeacherName(String teacherName) {
        this.teacherName = teacherName;
    }
}
