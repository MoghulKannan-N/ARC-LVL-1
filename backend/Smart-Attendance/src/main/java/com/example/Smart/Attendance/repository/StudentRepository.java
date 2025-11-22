package com.example.Smart.Attendance.repository;

import com.example.Smart.Attendance.model.Student;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;
import java.util.List;

public interface StudentRepository extends JpaRepository<Student, Long> {
    Optional<Student> findByUsername(String username);
    List<Student> findByTeacherId(Long teacherId);
    Optional<Student> findByName(String name);

}
