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
    // ✔ FIXED: Return clean JSON for login (NOT Student object)
    // Flutter needs: {id, name, username, teacherId}
    // ---------------------------------------------------------
    @GetMapping("/me")
    public Map<String, Object> getProfile(@RequestParam String username) {

        Optional<Student> opt = studentRepo.findByUsername(username);
        if (opt.isEmpty()) {
            return Map.of("error", "Student not found");
        }

        Student s = opt.get();

        return Map.of(
                "id", s.getId(),
                "name", s.getName(),
                "username", s.getUsername(),
                "teacherId", s.getTeacherId()
        );
    }

    // ---------------------------------------------------------
    // ✔ Full profile for Flutter Profile Screen
    // ---------------------------------------------------------
    @GetMapping("/profile/{name}")
    public Map<String, Object> getFullProfile(@PathVariable String name) {

        Optional<Student> opt = studentRepo.findByName(name);
        if (opt.isEmpty()) {
            return Map.of("error", "Student not found");
        }

        Student s = opt.get();

        return Map.of(
                "name", s.getName(),
                "dateOfBirth", s.getDateOfBirth(),
                "phoneNumber", s.getPhoneNumber(),
                "strength", s.getStrength(),
                "weakness", s.getWeakness(),
                "interest", s.getInterest(),
                "yearOfStudying", s.getYearOfStudying(),
                "course", s.getCourse()
        );
    }

    // ---------------------------------------------------------
    // ✔ Update profile (DOB, phone, course...)
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

        if (body.containsKey("dateOfBirth")) s.setDateOfBirth((String) body.get("dateOfBirth"));
        if (body.containsKey("phoneNumber")) s.setPhoneNumber((String) body.get("phoneNumber"));
        if (body.containsKey("strength")) s.setStrength((String) body.get("strength"));
        if (body.containsKey("weakness")) s.setWeakness((String) body.get("weakness"));
        if (body.containsKey("interest")) s.setInterest((String) body.get("interest"));
        if (body.containsKey("yearOfStudying")) s.setYearOfStudying((String) body.get("yearOfStudying"));
        if (body.containsKey("course")) s.setCourse((String) body.get("course"));

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
    // ✔ Simple test endpoint
    // ---------------------------------------------------------
    @GetMapping("/test-json")
    public Map<String, Object> testJson() {
        return Map.of(
                "status", "ok",
                "message", "Spring Boot is working!"
        );
    }
}
