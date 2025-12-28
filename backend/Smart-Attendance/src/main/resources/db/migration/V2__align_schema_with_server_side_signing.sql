-- Flyway migration: Align schema with server-side signing architecture (Option A)
-- This migration adds missing columns and constraints required for server-side session signing
-- and secure nonce management per session-student pair.

-- ========================================
-- attendance_sessions table additions
-- ========================================

-- Add subject_id column (required for session payload)
-- This allows sessions to be tied to specific subjects for proper academic tracking
ALTER TABLE attendance_sessions
ADD COLUMN IF NOT EXISTS subject_id BIGINT;

-- Add payload_b64 column (stores signed session data)
-- Critical for server-side signing: stores the canonical payload that gets signed
ALTER TABLE attendance_sessions
ADD COLUMN IF NOT EXISTS payload_b64 TEXT;

-- Add signature_b64 column (server-generated signature)
-- Stores the RSA signature of the session payload using server's private key
ALTER TABLE attendance_sessions
ADD COLUMN IF NOT EXISTS signature_b64 TEXT;

-- Add issued_at column (server timestamp when session was created)
-- Used for time-based validation and audit trails
ALTER TABLE attendance_sessions
ADD COLUMN IF NOT EXISTS issued_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

-- Add expires_at column (absolute expiry time for session)
-- Critical for security: sessions expire even if ends_at is manipulated
ALTER TABLE attendance_sessions
ADD COLUMN IF NOT EXISTS expires_at TIMESTAMP;

-- Add consumed column (tracks if session has been used)
-- Prevents replay attacks by marking sessions as consumed after first use
ALTER TABLE attendance_sessions
ADD COLUMN IF NOT EXISTS consumed BOOLEAN DEFAULT FALSE;

-- ========================================
-- attendance_nonces table additions
-- ========================================

-- Add session_id column (links nonce to specific session)
-- Essential for per-session nonce uniqueness and replay protection
ALTER TABLE attendance_nonces
ADD COLUMN IF NOT EXISTS session_id UUID;

-- Add student_id column (links nonce to specific student)
-- Required for per-student nonce issuance within a session
ALTER TABLE attendance_nonces
ADD COLUMN IF NOT EXISTS student_id BIGINT;

-- Add unique constraint on (session_id, student_id)
-- Prevents multiple active nonces for the same student in the same session
-- This is the primary security constraint for nonce replay protection
ALTER TABLE attendance_nonces
ADD CONSTRAINT uq_nonces_session_student
UNIQUE (session_id, student_id);

-- Add unique constraint on (session_id, nonce)
-- Ensures nonce uniqueness within a session (stronger than global uniqueness)
ALTER TABLE attendance_nonces
ADD CONSTRAINT uq_nonces_session_nonce
UNIQUE (session_id, nonce);

-- ========================================
-- Note: Foreign key constraints moved to separate migration
-- ========================================
-- Foreign key constraints require the "students" table to exist.
-- Since this is a production system with missing tables, FK constraints
-- are deferred to a later migration when all tables are properly created.

-- ========================================
-- Performance indexes (safe additions)
-- ========================================

-- Index on attendance_sessions.class_id for class-based queries
CREATE INDEX IF NOT EXISTS idx_attendance_sessions_class
ON attendance_sessions(class_id);

-- Index on attendance_sessions.subject_id for subject-based queries
CREATE INDEX IF NOT EXISTS idx_attendance_sessions_subject
ON attendance_sessions(subject_id);

-- Index on attendance_records.student_id for student attendance queries
CREATE INDEX IF NOT EXISTS idx_attendance_records_student
ON attendance_records(student_id);

-- Index on attendance_nonces.session_id for session-based nonce queries
CREATE INDEX IF NOT EXISTS idx_attendance_nonces_session
ON attendance_nonces(session_id);

-- Index on attendance_nonces.student_id for student-based nonce queries
CREATE INDEX IF NOT EXISTS idx_attendance_nonces_student
ON attendance_nonces(student_id);

-- Composite index on attendance_nonces(session_id, used) for efficient nonce validation
-- Critical for performance when checking active nonces during attendance submission
CREATE INDEX IF NOT EXISTS idx_attendance_nonces_session_used
ON attendance_nonces(session_id, used);
