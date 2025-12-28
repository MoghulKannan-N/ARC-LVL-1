package com.example.Smart.Attendance.model;

import java.time.Instant;
import java.util.UUID;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;

@Entity
@Table(name = "attendance_sessions")
public class AttendanceSession {

    @Id
    @Column(name = "id", nullable = false)
    private UUID id;

    @Column(name = "class_id", nullable = false)
    private Long classId;

    @Column(name = "subject_id", nullable = false)
    private Long subjectId;

    @Column(name = "teacher_id", nullable = false)
    private Long teacherId;

    @Column(name = "payload_b64", nullable = false, columnDefinition = "TEXT")
    private String payloadB64;

    @Column(name = "signature_b64", nullable = false, columnDefinition = "TEXT")
    private String signatureB64;

    // ✅ MISSING NOT-NULL COLUMN
    @Column(name = "issued_at", nullable = false)
    private Instant issuedAt;

    // Optional but exists in schema
    @Column(name = "expires_at", nullable = false)
    private Instant expiresAt;

    @Column(name = "consumed", nullable = false)
    private Boolean consumed = false;

    @Column(name = "starts_at", nullable = false)
    private Instant startsAt;

    @Column(name = "ends_at", nullable = false)
    private Instant endsAt;

    /* ===================== AUTO DEFAULTS ===================== */

    @PrePersist
    void prePersist() {
        Instant now = Instant.now();

        if (issuedAt == null) {
            issuedAt = now;
        }

        if (expiresAt == null && endsAt != null) {
            expiresAt = endsAt;
        }

        if (consumed == null) {
            consumed = false;
        }
    }

    /* ===================== Getters / Setters ===================== */

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public Long getClassId() { return classId; }
    public void setClassId(Long classId) { this.classId = classId; }

    public Long getSubjectId() { return subjectId; }
    public void setSubjectId(Long subjectId) { this.subjectId = subjectId; }

    public Long getTeacherId() { return teacherId; }
    public void setTeacherId(Long teacherId) { this.teacherId = teacherId; }

    public String getPayloadB64() { return payloadB64; }
    public void setPayloadB64(String payloadB64) { this.payloadB64 = payloadB64; }

    public String getSignatureB64() { return signatureB64; }
    public void setSignatureB64(String signatureB64) { this.signatureB64 = signatureB64; }

    public Instant getIssuedAt() { return issuedAt; }
    public void setIssuedAt(Instant issuedAt) { this.issuedAt = issuedAt; }

    public Instant getExpiresAt() { return expiresAt; }
    public void setExpiresAt(Instant expiresAt) { this.expiresAt = expiresAt; }

    public Boolean getConsumed() { return consumed; }
    public void setConsumed(Boolean consumed) { this.consumed = consumed; }

    public Instant getStartsAt() { return startsAt; }
    public void setStartsAt(Instant startsAt) { this.startsAt = startsAt; }

    public Instant getEndsAt() { return endsAt; }
    public void setEndsAt(Instant endsAt) { this.endsAt = endsAt; }
}
