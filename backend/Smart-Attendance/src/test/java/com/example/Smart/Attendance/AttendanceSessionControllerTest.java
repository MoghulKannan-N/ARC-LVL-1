package com.example.Smart.Attendance;

import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.PrivateKey;
import java.security.Signature;
import java.time.Instant;
import java.util.Base64;
import java.util.UUID;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.example.Smart.Attendance.model.TeacherKey;
import com.example.Smart.Attendance.repository.AttendanceNonceRepository;
import com.example.Smart.Attendance.repository.AttendanceSessionRepository;
import com.example.Smart.Attendance.repository.TeacherKeyRepository;

@SpringBootTest
@AutoConfigureMockMvc
public class AttendanceSessionControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private JdbcTemplate jdbc;

    @Autowired
    private AttendanceSessionRepository sessionRepository;

    @Autowired
    private TeacherKeyRepository teacherKeyRepository;

    @Autowired
    private AttendanceNonceRepository nonceRepository;

    @BeforeEach
    public void cleanup() {
        nonceRepository.deleteAll();
        sessionRepository.deleteAll();
        teacherKeyRepository.deleteAll();

        jdbc.execute("""
            INSERT INTO classes (id, class_code, class_name)
            VALUES (1, 'CSE-A', 'Computer Science A')
            ON CONFLICT (id) DO NOTHING
        """);

        jdbc.execute("""
            INSERT INTO subjects (id, subject_code, subject_name)
            VALUES (1, 'CS101', 'Intro to CS')
            ON CONFLICT (id) DO NOTHING
        """);

        // ensure class_students cleared
        jdbc.execute("DELETE FROM class_students");

        // ensure teacher FK parents exist for tests that create TeacherKey rows
        jdbc.execute("""
            INSERT INTO teacher (id, name)
            VALUES (100, 'Test Teacher 100')
            ON CONFLICT (id) DO NOTHING
        """);
        jdbc.execute("""
            INSERT INTO teacher (id, name)
            VALUES (101, 'Test Teacher 101')
            ON CONFLICT (id) DO NOTHING
        """);
        jdbc.execute("""
            INSERT INTO teacher (id, name)
            VALUES (102, 'Test Teacher 102')
            ON CONFLICT (id) DO NOTHING
        """);
        jdbc.execute("""
            INSERT INTO teacher (id, name)
            VALUES (103, 'Test Teacher 103')
            ON CONFLICT (id) DO NOTHING
        """);
        jdbc.execute("""
            INSERT INTO teacher (id, name)
            VALUES (104, 'Test Teacher 104')
            ON CONFLICT (id) DO NOTHING
        """);
    }

    @Test
    public void sessionCreationSuccess() throws Exception {
        long teacherId = 100L;

        KeyPairGenerator kpg = KeyPairGenerator.getInstance("RSA");
        kpg.initialize(1024); // use smaller key in tests to keep signature size < 255
        KeyPair kp = kpg.generateKeyPair();
        PrivateKey priv = kp.getPrivate();

        String pubPem = "-----BEGIN PUBLIC KEY-----\n" + Base64.getEncoder().encodeToString(kp.getPublic().getEncoded()) + "\n-----END PUBLIC KEY-----";

        TeacherKey tk = new TeacherKey();
        tk.setTeacherId(teacherId);
        tk.setPublicKeyPem(pubPem);
        teacherKeyRepository.save(tk);

        UUID sid = UUID.randomUUID();
        com.fasterxml.jackson.databind.ObjectMapper om = new com.fasterxml.jackson.databind.ObjectMapper();
        java.util.Map<String,Object> payloadMap = new java.util.HashMap<>();
        payloadMap.put("sessionId", sid.toString());
        payloadMap.put("teacherId", teacherId);
        payloadMap.put("classId", 1);
        payloadMap.put("subjectId", 1);
        payloadMap.put("issued_at", Instant.now().toString());
        payloadMap.put("expires_at", Instant.now().plusSeconds(3600).toString());
        String payload = om.writeValueAsString(payloadMap);

        String payloadB64 = Base64.getEncoder().encodeToString(payload.getBytes(java.nio.charset.StandardCharsets.UTF_8));

        Signature sig = Signature.getInstance("SHA256withRSA");
        sig.initSign(priv);
        sig.update(payload.getBytes(java.nio.charset.StandardCharsets.UTF_8));
        String signatureB64 = Base64.getEncoder().encodeToString(sig.sign());

        com.fasterxml.jackson.databind.ObjectMapper omReq = new com.fasterxml.jackson.databind.ObjectMapper();
        java.util.Map<String,Object> reqMap = new java.util.HashMap<>();
        reqMap.put("teacherId", teacherId);
        reqMap.put("payload_b64", payloadB64);
        reqMap.put("signature_b64", signatureB64);
        String body = omReq.writeValueAsString(reqMap);

        mockMvc.perform(post("/api/attendance/sessions")
                        .contentType("application/json")
                        .content(body))
                .andExpect(status().isCreated())
                .andExpect(content().string(org.hamcrest.Matchers.containsString(sid.toString())));
    }

    @Test
    public void sessionCreationBadSignature() throws Exception {
        long teacherId = 101L;

        KeyPairGenerator kpg = KeyPairGenerator.getInstance("RSA");
        kpg.initialize(1024); // use smaller key in tests to keep signature size < 255
        KeyPair kp = kpg.generateKeyPair();
        PrivateKey priv = kp.getPrivate();

        String pubPem = "-----BEGIN PUBLIC KEY-----\n" + Base64.getEncoder().encodeToString(kp.getPublic().getEncoded()) + "\n-----END PUBLIC KEY-----";

        TeacherKey tk = new TeacherKey();
        tk.setTeacherId(teacherId);
        tk.setPublicKeyPem(pubPem);
        teacherKeyRepository.save(tk);

        UUID sid = UUID.randomUUID();
        com.fasterxml.jackson.databind.ObjectMapper om = new com.fasterxml.jackson.databind.ObjectMapper();
        java.util.Map<String,Object> payloadMap = new java.util.HashMap<>();
        payloadMap.put("sessionId", sid.toString());
        payloadMap.put("teacherId", teacherId);
        payloadMap.put("classId", 1);
        payloadMap.put("subjectId", 1);
        payloadMap.put("issued_at", Instant.now().toString());
        payloadMap.put("expires_at", Instant.now().plusSeconds(3600).toString());
        String payload = om.writeValueAsString(payloadMap);

        String payloadB64 = Base64.getEncoder().encodeToString(payload.getBytes(java.nio.charset.StandardCharsets.UTF_8));

        Signature sig = Signature.getInstance("SHA256withRSA");
        sig.initSign(priv);
        sig.update(payload.getBytes(java.nio.charset.StandardCharsets.UTF_8));
        String signatureB64 = Base64.getEncoder().encodeToString(sig.sign());
        String badSig = signatureB64.substring(0, signatureB64.length() - 2) + "AA";

        com.fasterxml.jackson.databind.ObjectMapper omReq = new com.fasterxml.jackson.databind.ObjectMapper();
        java.util.Map<String,Object> reqMap = new java.util.HashMap<>();
        reqMap.put("teacherId", teacherId);
        reqMap.put("payload_b64", payloadB64);
        reqMap.put("signature_b64", badSig);
        String body = omReq.writeValueAsString(reqMap);

        mockMvc.perform(post("/api/attendance/sessions")
                        .contentType("application/json")
                        .content(body))
                .andExpect(status().isForbidden());
    }

    @Test
    public void nonceUniqueness() throws Exception {
        long teacherId = 102L;

        KeyPairGenerator kpg = KeyPairGenerator.getInstance("RSA");
        kpg.initialize(1024); // use smaller key in tests to keep signature size < 255
        KeyPair kp = kpg.generateKeyPair();
        PrivateKey priv = kp.getPrivate();

        String pubPem = "-----BEGIN PUBLIC KEY-----\n" + Base64.getEncoder().encodeToString(kp.getPublic().getEncoded()) + "\n-----END PUBLIC KEY-----";

        TeacherKey tk = new TeacherKey();
        tk.setTeacherId(teacherId);
        tk.setPublicKeyPem(pubPem);
        teacherKeyRepository.save(tk);

        UUID sid = UUID.randomUUID();
        com.fasterxml.jackson.databind.ObjectMapper om = new com.fasterxml.jackson.databind.ObjectMapper();
        java.util.Map<String,Object> payloadMap = new java.util.HashMap<>();
        payloadMap.put("sessionId", sid.toString());
        payloadMap.put("teacherId", teacherId);
        payloadMap.put("classId", 1);
        payloadMap.put("subjectId", 1);
        payloadMap.put("issued_at", Instant.now().toString());
        payloadMap.put("expires_at", Instant.now().plusSeconds(3600).toString());
        String payload = om.writeValueAsString(payloadMap);

        String payloadB64 = Base64.getEncoder().encodeToString(payload.getBytes(java.nio.charset.StandardCharsets.UTF_8));

        Signature sig = Signature.getInstance("SHA256withRSA");
        sig.initSign(priv);
        sig.update(payload.getBytes(java.nio.charset.StandardCharsets.UTF_8));
        String signatureB64 = Base64.getEncoder().encodeToString(sig.sign());

        com.fasterxml.jackson.databind.ObjectMapper omReq = new com.fasterxml.jackson.databind.ObjectMapper();
        java.util.Map<String,Object> reqMap = new java.util.HashMap<>();
        reqMap.put("teacherId", teacherId);
        reqMap.put("payload_b64", payloadB64);
        reqMap.put("signature_b64", signatureB64);
        String body = omReq.writeValueAsString(reqMap);

        // create session
        mockMvc.perform(post("/api/attendance/sessions")
                        .contentType("application/json")
                        .content(body))
                .andExpect(status().isCreated());

        // ensure student belongs to class
        long studentId = 5001L;
        // ensure student row exists to satisfy FK
        jdbc.update("INSERT INTO student (id, name) VALUES (?, ?) ON CONFLICT DO NOTHING", studentId, "Test Student 5001");
        jdbc.update("INSERT INTO class_students (class_id, student_id) VALUES (1, ?) ON CONFLICT DO NOTHING", studentId);

        String req = "{\"studentId\":" + studentId + "}";

        String r1 = mockMvc.perform(post("/api/attendance/sessions/" + sid + "/nonce")
                        .contentType("application/json")
                        .content(req))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();

        String r2 = mockMvc.perform(post("/api/attendance/sessions/" + sid + "/nonce")
                        .contentType("application/json")
                        .content(req))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();

        org.junit.jupiter.api.Assertions.assertNotEquals(r1, r2);
    }

    @Test
    public void nonceRejectedWhenSessionExpired() throws Exception {
        long teacherId = 103L;

        KeyPairGenerator kpg = KeyPairGenerator.getInstance("RSA");
        kpg.initialize(1024); // use smaller key in tests to keep signature size < 255
        KeyPair kp = kpg.generateKeyPair();
        PrivateKey priv = kp.getPrivate();

        String pubPem = "-----BEGIN PUBLIC KEY-----\n" + Base64.getEncoder().encodeToString(kp.getPublic().getEncoded()) + "\n-----END PUBLIC KEY-----";

        TeacherKey tk = new TeacherKey();
        tk.setTeacherId(teacherId);
        tk.setPublicKeyPem(pubPem);
        teacherKeyRepository.save(tk);

        UUID sid = UUID.randomUUID();
        com.fasterxml.jackson.databind.ObjectMapper om = new com.fasterxml.jackson.databind.ObjectMapper();
        java.util.Map<String,Object> payloadMap = new java.util.HashMap<>();
        payloadMap.put("sessionId", sid.toString());
        payloadMap.put("teacherId", teacherId);
        payloadMap.put("classId", 1);
        payloadMap.put("subjectId", 1);
        payloadMap.put("issued_at", Instant.now().minusSeconds(3600).toString());
        payloadMap.put("expires_at", Instant.now().minusSeconds(1800).toString());
        String payload = om.writeValueAsString(payloadMap);

        String payloadB64 = Base64.getEncoder().encodeToString(payload.getBytes(java.nio.charset.StandardCharsets.UTF_8));

        Signature sig = Signature.getInstance("SHA256withRSA");
        sig.initSign(priv);
        sig.update(payload.getBytes(java.nio.charset.StandardCharsets.UTF_8));
        String signatureB64 = Base64.getEncoder().encodeToString(sig.sign());

        com.fasterxml.jackson.databind.ObjectMapper omReq = new com.fasterxml.jackson.databind.ObjectMapper();
        java.util.Map<String,Object> reqMap = new java.util.HashMap<>();
        reqMap.put("teacherId", teacherId);
        reqMap.put("payload_b64", payloadB64);
        reqMap.put("signature_b64", signatureB64);
        String body = omReq.writeValueAsString(reqMap);

        mockMvc.perform(post("/api/attendance/sessions")
                        .contentType("application/json")
                        .content(body))
                .andExpect(status().isBadRequest());
    }

    @Test
    public void nonceRejectedOnStudentClassMismatch() throws Exception {
        long teacherId = 104L;

        KeyPairGenerator kpg = KeyPairGenerator.getInstance("RSA");
        kpg.initialize(1024); // use smaller key in tests to keep signature size < 255
        KeyPair kp = kpg.generateKeyPair();
        PrivateKey priv = kp.getPrivate();

        String pubPem = "-----BEGIN PUBLIC KEY-----\n" + Base64.getEncoder().encodeToString(kp.getPublic().getEncoded()) + "\n-----END PUBLIC KEY-----";

        TeacherKey tk = new TeacherKey();
        tk.setTeacherId(teacherId);
        tk.setPublicKeyPem(pubPem);
        teacherKeyRepository.save(tk);

        UUID sid = UUID.randomUUID();
        com.fasterxml.jackson.databind.ObjectMapper om = new com.fasterxml.jackson.databind.ObjectMapper();
        java.util.Map<String,Object> payloadMap = new java.util.HashMap<>();
        payloadMap.put("sessionId", sid.toString());
        payloadMap.put("teacherId", teacherId);
        payloadMap.put("classId", 1);
        payloadMap.put("subjectId", 1);
        payloadMap.put("issued_at", Instant.now().toString());
        payloadMap.put("expires_at", Instant.now().plusSeconds(3600).toString());
        String payload = om.writeValueAsString(payloadMap);

        String payloadB64 = Base64.getEncoder().encodeToString(payload.getBytes(java.nio.charset.StandardCharsets.UTF_8));

        Signature sig = Signature.getInstance("SHA256withRSA");
        sig.initSign(priv);
        sig.update(payload.getBytes(java.nio.charset.StandardCharsets.UTF_8));
        String signatureB64 = Base64.getEncoder().encodeToString(sig.sign());

        com.fasterxml.jackson.databind.ObjectMapper omReq = new com.fasterxml.jackson.databind.ObjectMapper();
        java.util.Map<String,Object> reqMap = new java.util.HashMap<>();
        reqMap.put("teacherId", teacherId);
        reqMap.put("payload_b64", payloadB64);
        reqMap.put("signature_b64", signatureB64);
        String body = omReq.writeValueAsString(reqMap);

        mockMvc.perform(post("/api/attendance/sessions")
                        .contentType("application/json")
                        .content(body))
                .andExpect(status().isCreated());

        long studentId = 9012L; // not inserted into class_students
        String req = "{\"studentId\":" + studentId + "}";

        mockMvc.perform(post("/api/attendance/sessions/" + sid + "/nonce")
                        .contentType("application/json")
                        .content(req))
                .andExpect(status().isForbidden());
    }
}
