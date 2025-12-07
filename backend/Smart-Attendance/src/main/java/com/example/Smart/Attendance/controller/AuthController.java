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

    // ---------------------------------------------------------
    // STUDENT LOGIN — returns JSON with ID + Name
    // ---------------------------------------------------------
    @PostMapping("/student/login")
    public Map<String, Object> studentLogin(@RequestBody Map<String, String> body) {

        String username = body.get("username");
        String password = body.get("password");

        Student student = authService.validateStudent(username, password);

        if (student == null) {
            return Map.of(
                "ok", false,
                "message", "Invalid username or password"
            );
        }

        return Map.of(
            "ok", true,
            "id", student.getId(),
            "name", student.getName(),
            "username", student.getUsername()
        );
    }

    // ---------------------------------------------------------
    // TEACHER LOGIN
    // ---------------------------------------------------------
    @PostMapping("/teacher/login")
    public String teacherLogin(@RequestBody Map<String, String> body) {

        String username = body.get("username");
        String password = body.get("password");

        return authService.loginTeacher(username, password);
    }

    // ---------------------------------------------------------
    // CHECK STUDENT EXISTS
    // ---------------------------------------------------------
    @GetMapping("/check-student")
    public String checkStudentExists(@RequestParam String name) {

        boolean exists = authService.doesStudentExist(name);
        return exists ? "exists" : "not_found";
    }
}
