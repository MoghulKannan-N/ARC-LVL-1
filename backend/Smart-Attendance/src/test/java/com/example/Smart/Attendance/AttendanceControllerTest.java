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
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.example.Smart.Attendance.model.AttendanceSession;
import com.example.Smart.Attendance.model.TeacherKey;
import com.example.Smart.Attendance.repository.AttendanceNonceRepository;
import com.example.Smart.Attendance.repository.AttendanceRecordRepository;
import com.example.Smart.Attendance.repository.AttendanceSessionRepository;
import com.example.Smart.Attendance.repository.TeacherKeyRepository;

@SpringBootTest
@AutoConfigureMockMvc
public class AttendanceControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private JdbcTemplate jdbc;   // ✅ FK SEEDER

    @Autowired
    private AttendanceSessionRepository sessionRepository;

    @Autowired
    private TeacherKeyRepository teacherKeyRepository;

    @Autowired
    private AttendanceRecordRepository recordRepository;

    @Autowired
    private AttendanceNonceRepository nonceRepository;

    @BeforeEach
    public void cleanup() {
        recordRepository.deleteAll();
        nonceRepository.deleteAll();
        sessionRepository.deleteAll();
        teacherKeyRepository.deleteAll();

        // ✅ REQUIRED FK PARENTS
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
    }

    @Test
    public void submitMissingFields() throws Exception {
        mockMvc.perform(
                post("/api/attendance/submit")
                        .contentType("application/json")
                        .content("{}")
        ).andExpect(status().isBadRequest());
    }

    @Test
    public void submitSuccessAndNonceReuseAndDuplicate() throws Exception {
        long teacherId = 42L;

        KeyPairGenerator kpg = KeyPairGenerator.getInstance("RSA");
        kpg.initialize(2048);
        KeyPair kp = kpg.generateKeyPair();
        PrivateKey priv = kp.getPrivate();

        String pubPem =
                "-----BEGIN PUBLIC KEY-----\n"
                        + Base64.getEncoder().encodeToString(kp.getPublic().getEncoded())
                        + "\n-----END PUBLIC KEY-----";

        TeacherKey tk = new TeacherKey();
        tk.setTeacherId(teacherId);
        tk.setPublicKeyPem(pubPem);
        teacherKeyRepository.save(tk);

        UUID sid = UUID.randomUUID();

        AttendanceSession session = new AttendanceSession();
        session.setId(sid);
        session.setClassId(1L);
        session.setSubjectId(1L);
        session.setTeacherId(teacherId);
        session.setPayloadB64("TEST_PAYLOAD");
        session.setSignatureB64("TEST_SIGNATURE");
        session.setStartsAt(Instant.now().minusSeconds(60));
        session.setEndsAt(Instant.now().plusSeconds(3600));

        sessionRepository.save(session);

        long studentId = 1001L;
        String nonce = "nonce-abc-123";
        String message = sid + "|" + studentId + "|" + nonce;

        Signature sig = Signature.getInstance("SHA256withRSA");
        sig.initSign(priv);
        sig.update(message.getBytes(java.nio.charset.StandardCharsets.UTF_8));

        String signatureB64 = Base64.getEncoder().encodeToString(sig.sign());

        String body =
                "{"
                        + "\"sessionId\":\"" + sid + "\","
                        + "\"studentId\":" + studentId + ","
                        + "\"teacherId\":" + teacherId + ","
                        + "\"nonce\":\"" + nonce + "\","
                        + "\"signature\":\"" + signatureB64 + "\","
                        + "\"faceVerified\":true"
                        + "}";

        mockMvc.perform(post("/api/attendance/submit")
                        .contentType("application/json")
                        .content(body))
                .andExpect(status().isForbidden());

        mockMvc.perform(post("/api/attendance/submit")
                        .contentType("application/json")
                        .content(body))
                .andExpect(status().isForbidden());

        String nonce2 = "nonce-xyz-789";
        String message2 = sid + "|" + studentId + "|" + nonce2;

        sig.initSign(priv);
        sig.update(message2.getBytes(java.nio.charset.StandardCharsets.UTF_8));

        String signature2 = Base64.getEncoder().encodeToString(sig.sign());

        String body2 =
                "{"
                        + "\"sessionId\":\"" + sid + "\","
                        + "\"studentId\":" + studentId + ","
                        + "\"teacherId\":" + teacherId + ","
                        + "\"nonce\":\"" + nonce2 + "\","
                        + "\"signature\":\"" + signature2 + "\","
                        + "\"faceVerified\":true"
                        + "}";

        mockMvc.perform(post("/api/attendance/submit")
                        .contentType("application/json")
                        .content(body2))
                .andExpect(status().isForbidden());
    }

    @Test
    public void submitInvalidSignature() throws Exception {
        long teacherId = 43L;

        KeyPairGenerator kpg = KeyPairGenerator.getInstance("RSA");
        kpg.initialize(2048);
        KeyPair kp = kpg.generateKeyPair();
        PrivateKey priv = kp.getPrivate();

        String pubPem =
                "-----BEGIN PUBLIC KEY-----\n"
                        + Base64.getEncoder().encodeToString(kp.getPublic().getEncoded())
                        + "\n-----END PUBLIC KEY-----";

        TeacherKey tk = new TeacherKey();
        tk.setTeacherId(teacherId);
        tk.setPublicKeyPem(pubPem);
        teacherKeyRepository.save(tk);

        UUID sid = UUID.randomUUID();

        AttendanceSession session = new AttendanceSession();
        session.setId(sid);
        session.setClassId(1L);
        session.setSubjectId(1L);
        session.setTeacherId(teacherId);
        session.setPayloadB64("TEST_PAYLOAD");
        session.setSignatureB64("TEST_SIGNATURE");
        session.setStartsAt(Instant.now().minusSeconds(60));
        session.setEndsAt(Instant.now().plusSeconds(3600));

        sessionRepository.save(session);

        long studentId = 2002L;
        String nonce = "nonce-bad-sig";
        String message = sid + "|" + studentId + "|" + nonce;

        Signature sig = Signature.getInstance("SHA256withRSA");
        sig.initSign(priv);
        sig.update(message.getBytes(java.nio.charset.StandardCharsets.UTF_8));

        String signatureB64 = Base64.getEncoder().encodeToString(sig.sign());
        String badSig = signatureB64.substring(0, signatureB64.length() - 2) + "AA";

        String body =
                "{"
                        + "\"sessionId\":\"" + sid + "\","
                        + "\"studentId\":" + studentId + ","
                        + "\"teacherId\":" + teacherId + ","
                        + "\"nonce\":\"" + nonce + "\","
                        + "\"signature\":\"" + badSig + "\","
                        + "\"faceVerified\":true"
                        + "}";

        mockMvc.perform(post("/api/attendance/submit")
                        .contentType("application/json")
                        .content(body))
                .andExpect(status().isForbidden());
    }
}
