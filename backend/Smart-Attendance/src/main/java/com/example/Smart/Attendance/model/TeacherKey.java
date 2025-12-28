package com.example.Smart.Attendance.model;

import java.time.Instant;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;

@Entity
@Table(name = "teacher_keys")
public class TeacherKey {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "teacher_id", nullable = false)
    private Long teacherId;

    @Column(
        name = "public_key_pem",
        nullable = false,
        columnDefinition = "TEXT"
    )
    private String publicKeyPem;

    @Column(name = "valid_from", nullable = false)
    private Instant validFrom;

    @Column(name = "valid_to", nullable = false)
    private Instant validTo;

    /* ===================== AUTO FIX ===================== */

    @PrePersist
    protected void onCreate() {
        Instant now = Instant.now();

        if (this.validFrom == null) {
            this.validFrom = now.minusSeconds(60); // small skew tolerance
        }

        if (this.validTo == null) {
            this.validTo = now.plusSeconds(3600); // 1 hour validity
        }
    }

    /* ===================== Helpers ===================== */

    public boolean isValidAt(Instant now) {
        return !now.isBefore(validFrom) && !now.isAfter(validTo);
    }

    /* ===================== Getters & Setters ===================== */

    public Long getId() {
        return id;
    }

    public Long getTeacherId() {
        return teacherId;
    }

    public void setTeacherId(Long teacherId) {
        this.teacherId = teacherId;
    }

    public String getPublicKeyPem() {
        return publicKeyPem;
    }

    public void setPublicKeyPem(String publicKeyPem) {
        this.publicKeyPem = publicKeyPem;
    }

    public Instant getValidFrom() {
        return validFrom;
    }

    public void setValidFrom(Instant validFrom) {
        this.validFrom = validFrom;
    }

    public Instant getValidTo() {
        return validTo;
    }

    public void setValidTo(Instant validTo) {
        this.validTo = validTo;
    }
}
