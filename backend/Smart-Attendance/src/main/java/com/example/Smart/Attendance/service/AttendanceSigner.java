package com.example.Smart.Attendance.service;

import java.security.KeyFactory;
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.PrivateKey;
import java.security.PublicKey;
import java.security.Signature;
import java.security.spec.PKCS8EncodedKeySpec;
import java.security.spec.X509EncodedKeySpec;
import java.util.Base64;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import jakarta.annotation.PostConstruct;

@Service
public class AttendanceSigner {

    @Value("${attendance.signing.private-key:#{null}}")
    private String privateKeyBase64;

    @Value("${attendance.signing.public-key:#{null}}")
    private String publicKeyBase64;

    private PrivateKey privateKey;
    private PublicKey publicKey;

    @PostConstruct
    public void init() throws Exception {
        if (privateKeyBase64 != null && publicKeyBase64 != null) {
            // Load from config
            loadKeysFromConfig();
        } else {
            // Generate new keys
            generateKeys();
        }
    }

    private void loadKeysFromConfig() throws Exception {
        // Load private key
        String privateKeyPem = privateKeyBase64;
        if (privateKeyPem.contains("-----BEGIN PRIVATE KEY-----")) {
            privateKeyPem = privateKeyPem
                    .replace("-----BEGIN PRIVATE KEY-----", "")
                    .replace("-----END PRIVATE KEY-----", "")
                    .replaceAll("\\s+", "");
        }
        byte[] privateKeyBytes = Base64.getDecoder().decode(privateKeyPem);
        PKCS8EncodedKeySpec privateSpec = new PKCS8EncodedKeySpec(privateKeyBytes);
        KeyFactory kf = KeyFactory.getInstance("RSA");
        privateKey = kf.generatePrivate(privateSpec);

        // Load public key
        String publicKeyPem = publicKeyBase64;
        if (publicKeyPem.contains("-----BEGIN PUBLIC KEY-----")) {
            publicKeyPem = publicKeyPem
                    .replace("-----BEGIN PUBLIC KEY-----", "")
                    .replace("-----END PUBLIC KEY-----", "")
                    .replaceAll("\\s+", "");
        }
        byte[] publicKeyBytes = Base64.getDecoder().decode(publicKeyPem);
        X509EncodedKeySpec publicSpec = new X509EncodedKeySpec(publicKeyBytes);
        publicKey = kf.generatePublic(publicSpec);
    }

    private void generateKeys() throws Exception {
        KeyPairGenerator kpg = KeyPairGenerator.getInstance("RSA");
        kpg.initialize(2048);
        KeyPair kp = kpg.generateKeyPair();
        privateKey = kp.getPrivate();
        publicKey = kp.getPublic();
    }

    public String signPayload(String payload) throws Exception {
        Signature sig = Signature.getInstance("SHA256withRSA");
        sig.initSign(privateKey);
        sig.update(payload.getBytes(java.nio.charset.StandardCharsets.UTF_8));
        byte[] signatureBytes = sig.sign();
        return Base64.getEncoder().encodeToString(signatureBytes);
    }

    public boolean verifySignature(String payload, String signatureB64) throws Exception {
        Signature sig = Signature.getInstance("SHA256withRSA");
        sig.initVerify(publicKey);
        sig.update(payload.getBytes(java.nio.charset.StandardCharsets.UTF_8));
        return sig.verify(Base64.getDecoder().decode(signatureB64));
    }

    public String getPublicKeyPem() {
        try {
            byte[] publicKeyBytes = publicKey.getEncoded();
            String base64 = Base64.getEncoder().encodeToString(publicKeyBytes);
            return "-----BEGIN PUBLIC KEY-----\n" +
                   base64.replaceAll("(.{64})", "$1\n") +
                   "\n-----END PUBLIC KEY-----";
        } catch (Exception e) {
            throw new RuntimeException("Failed to export public key", e);
        }
    }
}
