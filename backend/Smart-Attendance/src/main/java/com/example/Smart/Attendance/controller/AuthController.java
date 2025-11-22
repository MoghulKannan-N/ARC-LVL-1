package com.example.Smart.Attendance.controller;

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

    @PostMapping("/teacher/login")
    public String teacherLogin(@RequestBody Map<String, String> body) {

        String username = body.get("username");
        String password = body.get("password");

        System.out.println("Teacher login received: " + username);

        return authService.loginTeacher(username, password);
    }

    @PostMapping("/student/login")
    public String studentLogin(@RequestBody Map<String, String> body) {

        String username = body.get("username");
        String password = body.get("password");

        return authService.loginStudent(username, password);
    }

    @GetMapping("/check-student")
    public String checkStudentExists(@RequestParam String name) {

        boolean exists = authService.doesStudentExist(name);

        return exists ? "exists" : "not_found";
    }
}
