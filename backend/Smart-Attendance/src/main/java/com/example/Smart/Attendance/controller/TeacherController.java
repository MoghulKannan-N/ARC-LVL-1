package com.example.Smart.Attendance.controller;

import com.example.Smart.Attendance.model.Student;
import com.example.Smart.Attendance.model.Teacher;
import com.example.Smart.Attendance.service.TeacherService;
import com.example.Smart.Attendance.repository.TeacherRepository;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/teacher")
@CrossOrigin(origins = "*")
public class TeacherController {

    @Autowired
    private TeacherService teacherService;

    @Autowired
    private TeacherRepository teacherRepository;

    // ----------------------------------------------------------
    // ADD STUDENT
    // ----------------------------------------------------------
    @PostMapping("/{teacherId}/add-student")
    public Student addStudent(
            @PathVariable Long teacherId,
            @RequestBody Map<String, String> body) {

        String name = body.get("name");
        String username = body.get("username");
        String password = body.get("password");

        return teacherService.addStudent(teacherId, name, username, password);
    }

    // ----------------------------------------------------------
    // NEW: GET TEACHER PROFILE FOR LOGIN (required by Flutter)
    // ----------------------------------------------------------
    @GetMapping("/me")
    public Teacher getTeacherProfile(@RequestParam String username) {
        return teacherRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("Teacher not found: " + username));
    }
}
