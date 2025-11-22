package com.example.Smart.Attendance.controller;

import com.example.Smart.Attendance.model.Attendance;
import com.example.Smart.Attendance.service.AttendanceService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/attendance")
@CrossOrigin(origins = "*")
public class AttendanceController {

    @Autowired
    private AttendanceService attendanceService;

    // ✔ STUDENT MARK ATTENDANCE (no teacherName required)
    @PostMapping("/mark")
    public Attendance mark(@RequestBody Map<String, String> req) {
        return attendanceService.markAttendance(
                req.get("studentName"),
                req.get("status"),
                "SYSTEM"        // teacherName auto-set
        );
    }

    // GET LATEST STATUS
    @GetMapping("/status")
    public Attendance getStatus(@RequestParam String studentName) {
        return attendanceService.getLatestAttendance(studentName);
    }

    // ✔ TEACHER MANUAL UPDATE (teacherName required)
    @PostMapping("/update")
    public Attendance update(@RequestBody Map<String, String> body) {
        return attendanceService.updateAttendance(
                body.get("studentName"),
                body.get("status"),
                body.get("teacherName")
        );
    }
}
