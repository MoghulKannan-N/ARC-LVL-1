package com.example.Smart.Attendance.repository;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.example.Smart.Attendance.model.AttendanceRecord;

public interface AttendanceRecordRepository
        extends JpaRepository<AttendanceRecord, Long> {

    /**
     * Used by attendance submission controller to prevent duplicates.
     */
    Optional<AttendanceRecord> findBySessionIdAndStudentId(
        UUID sessionId,
        Long studentId
    );

    /**
     * Faster existence check (no entity load).
     */
    boolean existsBySessionIdAndStudentId(
        UUID sessionId,
        Long studentId
    );

    /**
     * Count total attendance records for a session.
     * Used for attendance percentage and absent lists.
     */
    long countBySessionId(UUID sessionId);

    /**
     * Count attendance for a student across sessions.
     * Used for student-wise attendance analytics.
     */
    long countByStudentId(Long studentId);

    /**
     * Count attendance records in a time window.
     * Used for trend analysis.
     */
    @Query("""
        SELECT COUNT(r)
        FROM AttendanceRecord r
        WHERE r.createdAt BETWEEN :from AND :to
    """)
    long countInTimeRange(
        @Param("from") Instant from,
        @Param("to") Instant to
    );
}
