package com.example.Smart.Attendance.controller;

import com.example.Smart.Attendance.model.Student;
import com.example.Smart.Attendance.repository.StudentRepository;
import com.example.Smart.Attendance.service.AuthService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/auth")
@CrossOrigin(origins = "*")
public class AuthController {

    @Autowired
    private AuthService authService;

    @Autowired
    private StudentRepository studentRepo;

    @PostMapping("/teacher/login")
    public String teacherLogin(@RequestBody Map<String, String> body) {

        String username = body.get("username");
        String password = body.get("password");

        System.out.println("Teacher login received: " + username);

        return authService.loginTeacher(username, password);
    }

    // ⭐ UPDATED STUDENT LOGIN → Now returns JSON with id + name
    @PostMapping("/student/login")
    public Map<String, Object> studentLogin(@RequestBody Map<String, String> body) {

        String username = body.get("username");
        String password = body.get("password");

        // Validate student
        Student student = authService.validateStudent(username, password);

        if (student == null) {
            return Map.of(
                "ok", false,
                "message", "Invalid username or password"
            );
        }

        // SUCCESS → Flutter needs this
        return Map.of(
            "ok", true,
            "id", student.getId(),
            "name", student.getName(),
            "username", student.getUsername()
        );
    }

    @GetMapping("/check-student")
    public String checkStudentExists(@RequestParam String name) {

        boolean exists = authService.doesStudentExist(name);

        return exists ? "exists" : "not_found";
    }
}
