-- Flyway migration: Fix column types for server-side signing
-- RSA-2048 signatures are ~344 characters, exceeding VARCHAR(255)
-- This migration ensures payload_b64 and signature_b64 can store full cryptographic data

-- ========================================
-- Fix attendance_sessions column types
-- ========================================

-- Change payload_b64 from VARCHAR(255) to TEXT
-- Stores Base64-encoded JSON payload that gets cryptographically signed
ALTER TABLE attendance_sessions
ALTER COLUMN payload_b64 TYPE TEXT;

-- Change signature_b64 from VARCHAR(255) to TEXT
-- Stores Base64-encoded RSA signature (~344 chars for RSA-2048)
ALTER TABLE attendance_sessions
ALTER COLUMN signature_b64 TYPE TEXT;

-- ========================================
-- Verification comments
-- ========================================
-- After this migration:
-- - payload_b64: Can store JSON payloads of any reasonable size
-- - signature_b64: Can store RSA-2048 signatures (~344 chars)
-- - No data loss: TEXT is backward compatible with VARCHAR data
-- - Server-side signing will work without truncation errors
