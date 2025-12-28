package com.example.Smart.Attendance.controller;

import java.nio.charset.StandardCharsets;
import java.security.SecureRandom;
import java.time.Instant;
import java.util.Base64;
import java.util.Map;
import java.util.UUID;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.example.Smart.Attendance.model.AttendanceNonce;
import com.example.Smart.Attendance.model.AttendanceSession;
import com.example.Smart.Attendance.repository.AttendanceNonceRepository;
import com.example.Smart.Attendance.repository.AttendanceSessionRepository;
import com.example.Smart.Attendance.service.AttendanceSigner;

@RestController
@RequestMapping("/api/attendance")
@CrossOrigin(origins = "*")
public class AttendanceSessionController {

    @Autowired
    private AttendanceSessionRepository sessionRepository;

    @Autowired
    private AttendanceSigner attendanceSigner;

    @Autowired
    private AttendanceNonceRepository nonceRepository;

    private static final SecureRandom RNG = new SecureRandom();
    private static final int NONCE_BYTE_LEN = 24;

    /* ===================== DTO ===================== */

    static class SessionCreateRequest {
        public Long teacherId;
        public Long classId;
        public Long subjectId;
    }

    static class NonceRequest {
        public Long studentId;
    }

    /* ===================== CREATE SESSION ===================== */

    @PostMapping("/sessions")
    public ResponseEntity<Map<String, Object>> createSession(
            @RequestBody SessionCreateRequest req) {

        if (req == null || req.teacherId == null ||
            req.classId == null || req.subjectId == null) {

            return ResponseEntity.badRequest()
                    .body(Map.of("error", "teacherId, classId, subjectId required"));
        }

        try {
            UUID sessionId = UUID.randomUUID();
            Instant issuedAt = Instant.now();
            Instant expiresAt = issuedAt.plusSeconds(120);

            /* ✅ BUILD SINGLE SOURCE OF TRUTH PAYLOAD */
            String payloadJson = String.format(
                "{\"sessionId\":\"%s\",\"issuedAt\":\"%s\",\"expiresAt\":\"%s\",\"classId\":%d,\"subjectId\":%d}",
                sessionId, issuedAt, expiresAt, req.classId, req.subjectId
            );

            /* ✅ SIGN EXACT PAYLOAD */
            String signatureB64 =
                    attendanceSigner.signPayload(payloadJson);

            /* ✅ STORE EXACT PAYLOAD */
            String payloadB64 = Base64.getEncoder()
                    .encodeToString(payloadJson.getBytes(StandardCharsets.UTF_8));

            AttendanceSession session = new AttendanceSession();
            session.setId(sessionId);
            session.setTeacherId(req.teacherId);
            session.setClassId(req.classId);
            session.setSubjectId(req.subjectId);
            session.setPayloadB64(payloadB64);
            session.setSignatureB64(signatureB64);
            session.setIssuedAt(issuedAt);
            session.setExpiresAt(expiresAt);
            session.setStartsAt(issuedAt);
            session.setEndsAt(expiresAt);

            sessionRepository.save(session);

            return ResponseEntity.status(HttpStatus.CREATED).body(Map.of(
                    "sessionId", sessionId.toString(),
                    "payload_b64", payloadB64,
                    "signature_b64", signatureB64,
                    "expiresAt", expiresAt.toString()
            ));

        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", e.getMessage()));
        }
    }

    /* ===================== NONCE ===================== */

    @PostMapping("/sessions/{sessionId}/nonce")
    public ResponseEntity<Map<String, Object>> createNonce(
            @PathVariable String sessionId,
            @RequestBody NonceRequest req) {

        if (req == null || req.studentId == null) {
            return ResponseEntity.badRequest()
                    .body(Map.of("error", "studentId required"));
        }

        UUID sid;
        try {
            sid = UUID.fromString(sessionId);
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                    .body(Map.of("error", "invalid sessionId"));
        }

        Instant now = Instant.now();
        AttendanceSession session =
                sessionRepository.findActiveSession(sid, now)
                        .orElse(null);

        if (session == null) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(Map.of("error", "session not active"));
        }

        if (!sessionRepository.studentBelongsToSessionClass(sid, req.studentId)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(Map.of("error", "student not in session class"));
        }

        for (int i = 0; i < 10; i++) {
            byte[] buf = new byte[NONCE_BYTE_LEN];
            RNG.nextBytes(buf);
            String nonce = Base64.getUrlEncoder()
                    .withoutPadding()
                    .encodeToString(buf);

            if (!nonceRepository.existsByNonce(nonce)) {
                AttendanceNonce an = new AttendanceNonce();
                an.setNonce(nonce);
                an.setSessionId(sid);
                an.setUsed(false);
                try {
                    nonceRepository.save(an);
                    return ResponseEntity.status(HttpStatus.CREATED)
                            .body(Map.of("nonce", nonce));
                } catch (DataIntegrityViolationException ignored) {}
            }
        }

        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of("error", "nonce generation failed"));
    }
}
