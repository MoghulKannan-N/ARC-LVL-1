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

    // ------------------ STUDENT LOGIN ---------------------
    public String loginStudent(String username, String password) {

        Optional<Student> opt = studentRepo.findByUsername(username);
        if (opt.isEmpty()) {
            return "Invalid credentials";
        }

        Student s = opt.get();

        if (s.getPassword() != null && s.getPassword().equals(password)) {
            return "Student login successful";
        }

        return "Invalid credentials";
    }

    // ------------------ TEACHER LOGIN (DB BASED) ---------------------
    public String loginTeacher(String username, String password) {

        System.out.println("Teacher login request: " + username + " / " + password);

        Optional<Teacher> opt = teacherRepo.findByUsername(username);

        if (opt.isEmpty()) {
            System.out.println("Teacher not found!");
            return "Invalid credentials";
        }

        Teacher t = opt.get();

        if (t.getPassword() != null && t.getPassword().equals(password)) {
            System.out.println("Teacher login success!");
            return "Teacher login successful";
        }

        System.out.println("Password mismatch!");
        return "Invalid credentials";
    }

    // ------------------ CHECK STUDENT ----------------------
    public boolean doesStudentExist(String name) {
        return studentRepo.findByName(name).isPresent();
    }
}
