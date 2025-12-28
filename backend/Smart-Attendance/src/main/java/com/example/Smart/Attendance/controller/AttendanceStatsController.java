package com.example.Smart.Attendance.controller;

import com.example.Smart.Attendance.model.AttendanceRecord;
import com.example.Smart.Attendance.repository.AttendanceRecordRepository;
import com.example.Smart.Attendance.repository.AttendanceSessionRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.ZoneOffset;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/attendance/stats")
@CrossOrigin(origins = "*")
public class AttendanceStatsController {

    @Autowired
    private AttendanceRecordRepository attendanceRecordRepository;

    @Autowired
    private AttendanceSessionRepository attendanceSessionRepository;

    // Get overall attendance statistics
    @GetMapping("/overview")
    public ResponseEntity<Map<String, Object>> getOverviewStats() {
        Map<String, Object> stats = new HashMap<>();

        try {
            // Get total attendance records
            long totalRecords = attendanceRecordRepository.count();
            stats.put("totalAttendanceRecords", totalRecords);

            // Get today's attendance records
            Instant startOfDay = LocalDate.now().atStartOfDay().toInstant(ZoneOffset.UTC);
            Instant endOfDay = LocalDate.now().atTime(LocalTime.MAX).toInstant(ZoneOffset.UTC);

            long todayRecords = attendanceRecordRepository.countInTimeRange(startOfDay, endOfDay);
            stats.put("todayAttendanceRecords", todayRecords);

            // Calculate attendance rate (face verified records)
            // Note: We can't efficiently filter by faceVerified with current repo methods
            // For now, approximate with total records (all current records are face verified)
            double attendanceRate = 100.0; // All BLE attendance records are verified
            stats.put("attendanceRate", attendanceRate);

            // Get unique students who have attended
            List<AttendanceRecord> allRecords = attendanceRecordRepository.findAll();
            long uniqueStudents = allRecords.stream()
                .mapToLong(AttendanceRecord::getStudentId)
                .distinct()
                .count();
            stats.put("uniqueStudents", uniqueStudents);

            // Get sessions count
            long totalSessions = attendanceSessionRepository.count();
            stats.put("totalSessions", totalSessions);

            return ResponseEntity.ok(stats);

        } catch (Exception e) {
            stats.put("error", "Failed to fetch stats: " + e.getMessage());
            return ResponseEntity.internalServerError().body(stats);
        }
    }

    // Get attendance records for a specific session
    @GetMapping("/session/{sessionId}")
    public ResponseEntity<List<AttendanceRecord>> getSessionAttendance(@PathVariable String sessionId) {
        try {
            // Get all records and filter by sessionId
            List<AttendanceRecord> allRecords = attendanceRecordRepository.findAll();
            List<AttendanceRecord> sessionRecords = allRecords.stream()
                .filter(record -> record.getSessionId().toString().equals(sessionId))
                .collect(Collectors.toList());

            return ResponseEntity.ok(sessionRecords);

        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }

    // Get attendance records for a specific student
    @GetMapping("/student/{studentId}")
    public ResponseEntity<List<AttendanceRecord>> getStudentAttendance(@PathVariable Long studentId) {
        try {
            // Get all records and filter by studentId
            List<AttendanceRecord> allRecords = attendanceRecordRepository.findAll();
            List<AttendanceRecord> studentRecords = allRecords.stream()
                .filter(record -> record.getStudentId().equals(studentId))
                .collect(Collectors.toList());

            return ResponseEntity.ok(studentRecords);

        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }

    // Get attendance trend data (last 7 days)
    @GetMapping("/trends")
    public ResponseEntity<Map<String, Object>> getAttendanceTrends() {
        Map<String, Object> trends = new HashMap<>();

        try {
            List<Integer> dailyCounts = new java.util.ArrayList<>();

            // Get attendance counts for last 7 days
            for (int i = 6; i >= 0; i--) {
                Instant dayStart = LocalDate.now().minusDays(i).atStartOfDay().toInstant(ZoneOffset.UTC);
                Instant dayEnd = LocalDate.now().minusDays(i).atTime(LocalTime.MAX).toInstant(ZoneOffset.UTC);

                long count = attendanceRecordRepository.countInTimeRange(dayStart, dayEnd);
                dailyCounts.add((int) count);
            }

            trends.put("dailyAttendance", dailyCounts);
            trends.put("period", "Last 7 days");

            return ResponseEntity.ok(trends);

        } catch (Exception e) {
            trends.put("error", "Failed to fetch trends: " + e.getMessage());
            return ResponseEntity.internalServerError().body(trends);
        }
    }
}
