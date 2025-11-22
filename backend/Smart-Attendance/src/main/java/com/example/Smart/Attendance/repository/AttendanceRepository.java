package com.example.Smart.Attendance.repository;

import com.example.Smart.Attendance.model.Attendance;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface AttendanceRepository extends JpaRepository<Attendance, Long> {

    // ✔ Get the latest record of a student
    Optional<Attendance> findTopByStudentNameOrderByMarkedAtDesc(String studentName);
}
