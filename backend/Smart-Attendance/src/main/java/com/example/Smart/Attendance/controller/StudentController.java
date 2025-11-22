package com.example.Smart.Attendance.controller;

import com.example.Smart.Attendance.model.Student;
import com.example.Smart.Attendance.repository.StudentRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/student")
@CrossOrigin(origins = "*")
public class StudentController {

    @Autowired
    private StudentRepository studentRepo;

    // ✔ Get student profile by username
    @GetMapping("/me")
    public Student getProfile(@RequestParam String username) {
        return studentRepo.findByUsername(username).orElse(null);
    }
    @GetMapping("/all")
    public List<Student> getAllStudents() {
        return studentRepo.findAll();
    }
    @GetMapping("/test-json")
    public Map<String, Object> testJson() {
        return Map.of(
                "status", "ok",
                "message", "Spring Boot is working!"
        );
    }


}
