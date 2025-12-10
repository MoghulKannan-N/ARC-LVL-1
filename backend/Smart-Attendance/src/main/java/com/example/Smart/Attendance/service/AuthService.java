package com.example.Smart.Attendance.service;

import com.example.Smart.Attendance.model.Student;
import com.example.Smart.Attendance.model.Teacher;
import com.example.Smart.Attendance.repository.StudentRepository;
import com.example.Smart.Attendance.repository.TeacherRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
public class AuthService {

    @Autowired
    private StudentRepository studentRepo;

    @Autowired
    private TeacherRepository teacherRepo;

    // -----------------------------------------------------
    // NEW: Validate student & return Student object
    // -----------------------------------------------------
    public Student validateStudent(String username, String password) {

        Optional<Student> opt = studentRepo.findByUsername(username);
        if (opt.isEmpty()) {
            return null;
        }

        Student s = opt.get();

        if (s.getPassword() != null && s.getPassword().equals(password)) {
            return s;   // return full student object
        }

        return null;
    }

    // -----------------------------------------------------
    // TEACHER LOGIN
    // -----------------------------------------------------
    public String loginTeacher(String username, String password) {

        Optional<Teacher> opt = teacherRepo.findByUsername(username);

        if (opt.isEmpty()) {
            return "Invalid credentials";
        }

        Teacher t = opt.get();

        if (t.getPassword() != null && t.getPassword().equals(password)) {
            return "Teacher login successful";
        }

        return "Invalid credentials";
    }

    // -----------------------------------------------------
    // CHECK STUDENT EXISTS
    // -----------------------------------------------------
    public boolean doesStudentExist(String name) {
        return studentRepo.findByName(name).isPresent();
    }
}
