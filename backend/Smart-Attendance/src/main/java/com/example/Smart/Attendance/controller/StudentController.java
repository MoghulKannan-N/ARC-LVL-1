package com.example.Smart.Attendance.controller;

import com.example.Smart.Attendance.model.Student;
import com.example.Smart.Attendance.repository.StudentRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/student")
@CrossOrigin(origins = "*")
public class StudentController {

    @Autowired
    private StudentRepository studentRepo;

    // ---------------------------------------------------------
    // ✔ Fetch student profile by username (for login)
    // ---------------------------------------------------------
    @GetMapping("/me")
    public Student getProfile(@RequestParam String username) {
        return studentRepo.findByUsername(username).orElse(null);
    }

    // ---------------------------------------------------------
    // ✔ Fetch FULL student profile by name (for profile screen)
    // Flutter calls: GET /api/student/profile/{studentName}
    // ---------------------------------------------------------
    @GetMapping("/profile/{name}")
    public Student getFullProfile(@PathVariable String name) {
        return studentRepo.findByName(name).orElse(null);
    }

    // ---------------------------------------------------------
    // ✔ Update profile fields (DOB, phone, interest, strengths)
    // Flutter calls this on SAVE
    // ---------------------------------------------------------
    @PutMapping("/profile/{name}")
    public Map<String, Object> updateProfile(
            @PathVariable String name,
            @RequestBody Map<String, Object> body
    ) {
        Optional<Student> optionalStudent = studentRepo.findByName(name);
        if (optionalStudent.isEmpty()) {
            return Map.of("ok", false, "message", "Student not found");
        }

        Student s = optionalStudent.get();

        // Update fields ONLY if they exist in request
        if (body.containsKey("dateOfBirth"))
            s.setDateOfBirth((String) body.get("dateOfBirth"));

        if (body.containsKey("phoneNumber"))
            s.setPhoneNumber((String) body.get("phoneNumber"));

        if (body.containsKey("strength"))
            s.setStrength((String) body.get("strength"));

        if (body.containsKey("weakness"))
            s.setWeakness((String) body.get("weakness"));

        if (body.containsKey("interest"))
            s.setInterest((String) body.get("interest"));

        if (body.containsKey("yearOfStudying"))
            s.setYearOfStudying((String) body.get("yearOfStudying"));

        if (body.containsKey("course"))
            s.setCourse((String) body.get("course"));

        studentRepo.save(s);

        return Map.of("ok", true, "message", "Profile updated successfully");
    }

    // ---------------------------------------------------------
    // ✔ Get ALL students
    // ---------------------------------------------------------
    @GetMapping("/all")
    public List<Student> getAllStudents() {
        return studentRepo.findAll();
    }

    // ---------------------------------------------------------
    // ✔ Test JSON route
    // ---------------------------------------------------------
    @GetMapping("/test-json")
    public Map<String, Object> testJson() {
        return Map.of(
                "status", "ok",
                "message", "Spring Boot is working!"
        );
    }
}
