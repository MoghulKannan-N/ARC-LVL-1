package com.example.Smart.Attendance.repository;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.example.Smart.Attendance.model.AttendanceSession;

public interface AttendanceSessionRepository
        extends JpaRepository<AttendanceSession, UUID> {

    /**
     * Load an active session at a given instant.
     * Used to enforce time-window validity.
     */
    @Query("""
        SELECT s
        FROM AttendanceSession s
        WHERE s.id = :sessionId
          AND :now BETWEEN s.startsAt AND s.endsAt
    """)
    Optional<AttendanceSession> findActiveSession(
        @Param("sessionId") UUID sessionId,
        @Param("now") Instant now
    );

    /**
     * Check whether a student belongs to the class of a session.
     *
     * Uses native SQL because class_students
     * is NOT a mapped JPA entity.
     *
     * This FIXES:
     * - UnknownEntityException: ClassStudent
     * - ApplicationContext startup failure
     * - Test crashes
     */
    @Query(
        value = """
            SELECT EXISTS (
                SELECT 1
                FROM class_students cs
                JOIN attendance_sessions s
                  ON s.class_id = cs.class_id
                WHERE s.id = :sessionId
                  AND cs.student_id = :studentId
            )
        """,
        nativeQuery = true
    )
    boolean studentBelongsToSessionClass(
        @Param("sessionId") UUID sessionId,
        @Param("studentId") Long studentId
    );
}
