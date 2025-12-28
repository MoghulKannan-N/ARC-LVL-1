package com.example.Smart.Attendance.controller;

import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Base64;
import java.util.Optional;
import java.util.UUID;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.example.Smart.Attendance.model.AttendanceNonce;
import com.example.Smart.Attendance.model.AttendanceRecord;
import com.example.Smart.Attendance.model.AttendanceSession;
import com.example.Smart.Attendance.repository.AttendanceNonceRepository;
import com.example.Smart.Attendance.repository.AttendanceRecordRepository;
import com.example.Smart.Attendance.repository.AttendanceSessionRepository;
import com.example.Smart.Attendance.service.AttendanceSigner;

@RestController
@RequestMapping("/api/attendance")
public class SignatureAttendanceController {

    @Autowired
    private AttendanceSessionRepository sessionRepository;

    @Autowired
    private AttendanceRecordRepository recordRepository;

    @Autowired
    private AttendanceNonceRepository nonceRepository;

    @Autowired
    private AttendanceSigner attendanceSigner;

    /* ===================== DTO ===================== */
    public static class AttendanceSubmission {
        public String sessionId;
        public Long studentId;
        public String nonce;

        // Option A → client signature ignored
        public String signature;
        public Boolean faceVerified;
    }

    /* ===================== SUBMIT ===================== */
    @PostMapping("/submit")
    @Transactional
    public ResponseEntity<?> submit(@RequestBody AttendanceSubmission s) {

        /* ---------- 0. Basic validation ---------- */
        if (s.sessionId == null || s.studentId == null || s.nonce == null) {
            return ResponseEntity.badRequest().body("Missing fields");
        }

        try {
            UUID sessionId = UUID.fromString(s.sessionId);
            Instant now = Instant.now();

            /* ---------- 1. Active session ---------- */
            AttendanceSession session = sessionRepository
                    .findActiveSession(sessionId, now)
                    .orElseThrow(() ->
                            new IllegalStateException("Session not active or expired"));

            /* ---------- 2. VERIFY SESSION SIGNATURE (CORRECT) ---------- */
            // ✅ Decode the EXACT payload that was signed
            String payloadJson = new String(
                    Base64.getDecoder().decode(session.getPayloadB64()),
                    StandardCharsets.UTF_8
            );

            boolean signatureValid =
                    attendanceSigner.verifySignature(
                            payloadJson,
                            session.getSignatureB64()
                    );

            if (!signatureValid) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN)
                        .body("Invalid session signature");
            }

            /* ---------- 3. Nonce validation ---------- */
            Optional<AttendanceNonce> nonceOpt =
                    nonceRepository.findAll().stream()
                            .filter(n ->
                                    n.getSessionId().equals(sessionId) &&
                                    n.getNonce().equals(s.nonce) &&
                                    !n.isUsed()
                            )
                            .findFirst();

            if (nonceOpt.isEmpty()) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN)
                        .body("Invalid or reused nonce");
            }

            AttendanceNonce nonce = nonceOpt.get();
            nonce.setUsed(true);
            nonceRepository.save(nonce);

            /* ---------- 4. Student belongs to class ---------- */
            boolean studentInClass =
                    sessionRepository.studentBelongsToSessionClass(
                            sessionId,
                            s.studentId
                    );

            if (!studentInClass) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN)
                        .body("Student not in session class");
            }

            /* ---------- 5. Prevent duplicate attendance ---------- */
            if (recordRepository
                    .findBySessionIdAndStudentId(sessionId, s.studentId)
                    .isPresent()) {

                return ResponseEntity.status(HttpStatus.CONFLICT)
                        .body("Attendance already recorded");
            }

            /* ---------- 6. FACE VERIFICATION (TEMP PASS – OPTION A) ---------- */
            boolean faceVerified = true;

            /* ---------- 7. RECORD ATTENDANCE ---------- */
            AttendanceRecord record = new AttendanceRecord();
            record.setSessionId(sessionId);
            record.setStudentId(s.studentId);
            record.setFaceVerified(faceVerified);

            recordRepository.save(record);

            return ResponseEntity.ok("Attendance recorded successfully");

        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body("Invalid sessionId format");
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("Internal server error: " + e.getMessage());
        }
    }
}
