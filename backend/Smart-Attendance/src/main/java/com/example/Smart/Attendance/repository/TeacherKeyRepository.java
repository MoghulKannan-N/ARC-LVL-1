package com.example.Smart.Attendance.repository;

import java.time.Instant;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.example.Smart.Attendance.model.TeacherKey;

public interface TeacherKeyRepository
        extends JpaRepository<TeacherKey, Long> {

    /**
     * Returns the currently valid public key for a teacher at a given instant.
     * Used for signature verification.
     */
    @Query("""
        SELECT k
        FROM TeacherKey k
        WHERE k.teacherId = :teacherId
          AND (k.validFrom IS NULL OR k.validFrom <= :now)
          AND (k.validTo IS NULL OR k.validTo >= :now)
        ORDER BY k.id DESC
    """)
    Optional<TeacherKey> findActiveKeyForTeacher(
        @Param("teacherId") Long teacherId,
        @Param("now") Instant now
    );
}
