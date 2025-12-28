package com.example.Smart.Attendance.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import com.example.Smart.Attendance.model.AttendanceNonce;

public interface AttendanceNonceRepository
        extends JpaRepository<AttendanceNonce, Long> {

    /**
     * Optional helper for diagnostics or audits.
     * NOT used for replay protection logic.
     */
    boolean existsByNonce(String nonce);
}
