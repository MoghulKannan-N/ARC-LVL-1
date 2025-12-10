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

    // ✔ STUDENT MARK ATTENDANCE
    @PostMapping("/mark")
    public Attendance markAttendance(@RequestBody Map<String, String> req) {
        return attendanceService.markAttendance(
                req.get("studentName"),
                req.get("status"),
                "SYSTEM"
        );
    }

    // ✔ GET CURRENT STATUS
    @GetMapping("/status")
    public Attendance getStatus(@RequestParam String studentName) {
        return attendanceService.getAttendance(studentName);
    }

    // ✔ TEACHER UPDATE ATTENDANCE
    @PostMapping("/update")
    public Attendance update(@RequestBody Map<String, String> body) {
        return attendanceService.updateAttendance(
                body.get("studentName"),
                body.get("status"),
                body.get("teacherName")
        );
    }
}
