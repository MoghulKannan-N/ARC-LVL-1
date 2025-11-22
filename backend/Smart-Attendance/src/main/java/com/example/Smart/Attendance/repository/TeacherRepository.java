package com.example.Smart.Attendance.repository;

import com.example.Smart.Attendance.model.Teacher;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface TeacherRepository extends JpaRepository<Teacher, Long> {

    // find teacher by display name (optional)
    Optional<Teacher> findByName(String name);

    // REQUIRED — used by /teacher/me
    Optional<Teacher> findByUsername(String username);
}
