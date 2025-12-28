package com.example.Smart.Attendance.controller;

import java.security.KeyFactory;
import java.security.PublicKey;
import java.security.spec.X509EncodedKeySpec;
import java.time.Instant;
import java.util.Base64;
import java.util.HashMap;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.example.Smart.Attendance.model.TeacherKey;
import com.example.Smart.Attendance.repository.TeacherKeyRepository;

@RestController
@RequestMapping("/api/teachers")
@CrossOrigin(origins = "*")
public class TeacherKeyController {

    @Autowired
    private TeacherKeyRepository teacherKeyRepository;

    static class KeyRequest {
        public String publicKeyPem;
        public String validFrom; // optional ISO-8601
        public String validTo;   // optional ISO-8601
    }

    @PostMapping("/{teacherId}/key")
    public ResponseEntity<Map<String, Object>> uploadKey(
            @PathVariable Long teacherId,
            @RequestBody KeyRequest req
    ) {
        if (req == null || req.publicKeyPem == null || req.publicKeyPem.trim().isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("error", "publicKeyPem is required"));
        }

        String pem = req.publicKeyPem.trim();

        try {
            // Normalize PEM: strip header/footer if present and base64-decode
            String base64 = pem;
            if (pem.contains("-----BEGIN PUBLIC KEY-----")) {
                base64 = pem
                        .replace("-----BEGIN PUBLIC KEY-----", "")
                        .replace("-----END PUBLIC KEY-----", "")
                        .replaceAll("\\s+", "");
            }

            byte[] keyBytes = Base64.getDecoder().decode(base64);
            X509EncodedKeySpec spec = new X509EncodedKeySpec(keyBytes);
            KeyFactory kf = KeyFactory.getInstance("RSA");
            PublicKey pub = kf.generatePublic(spec);

            TeacherKey tk = new TeacherKey();
            tk.setTeacherId(teacherId);
            tk.setPublicKeyPem(pem);

            // Optionally use validFrom / validTo if provided
            if (req.validFrom != null) tk.setValidFrom(Instant.parse(req.validFrom));
            if (req.validTo != null) tk.setValidTo(Instant.parse(req.validTo));

            teacherKeyRepository.save(tk);

            Map<String, Object> body = new HashMap<>();
            body.put("teacherId", teacherId);
            body.put("saved", true);
            return ResponseEntity.status(HttpStatus.CREATED).body(body);

        } catch (IllegalArgumentException iae) {
            return ResponseEntity.badRequest().body(Map.of("error", "publicKeyPem is not valid base64 or PEM"));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "unable to parse public key"));
        }
    }
}
