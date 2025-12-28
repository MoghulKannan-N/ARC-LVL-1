-- Flyway migration: create attendance tables (Postgres)

CREATE TABLE attendance_sessions (
  id UUID NOT NULL PRIMARY KEY,
  class_id BIGINT NOT NULL,
  teacher_id BIGINT NOT NULL,
  starts_at TIMESTAMP NOT NULL,
  ends_at TIMESTAMP NOT NULL,
  nonce VARCHAR(255),
  CONSTRAINT uq_attendance_sessions_id UNIQUE (id)
);

CREATE TABLE teacher_keys (
  id BIGSERIAL PRIMARY KEY,
  teacher_id BIGINT NOT NULL UNIQUE,
  public_key TEXT NOT NULL,
  valid_from TIMESTAMP NULL,
  valid_to TIMESTAMP NULL
);

CREATE TABLE attendance_nonces (
  id BIGSERIAL PRIMARY KEY,
  nonce VARCHAR(255) NOT NULL UNIQUE,
  used BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE attendance_records (
  id BIGSERIAL PRIMARY KEY,
  session_id UUID NOT NULL,
  student_id BIGINT NOT NULL,
  face_verified BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT uq_session_student UNIQUE (session_id, student_id),
  CONSTRAINT fk_records_session FOREIGN KEY (session_id) REFERENCES attendance_sessions(id)
);

-- Indexes
CREATE INDEX idx_attendance_sessions_teacher ON attendance_sessions(teacher_id);
CREATE INDEX idx_attendance_records_session ON attendance_records(session_id);
CREATE INDEX idx_attendance_nonces_nonce ON attendance_nonces(nonce);
