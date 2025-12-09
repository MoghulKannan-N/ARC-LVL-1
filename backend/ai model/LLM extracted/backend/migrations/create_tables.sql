-- migrations/create_tables.sql

PRAGMA foreign_keys = ON;

-- migrations/create_tables.sql (example)
CREATE TABLE IF NOT EXISTS students (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, dept TEXT, points INTEGER DEFAULT 0, progress INTEGER DEFAULT 0);
CREATE TABLE IF NOT EXISTS roadmap (id INTEGER PRIMARY KEY AUTOINCREMENT, student_id INTEGER, topic TEXT, subtopic TEXT, resources TEXT, position INTEGER, status TEXT);
CREATE TABLE IF NOT EXISTS mini_sessions (id INTEGER PRIMARY KEY AUTOINCREMENT, roadmap_id INTEGER, student_id INTEGER, mini_title TEXT, description TEXT, estimated_minutes INTEGER, resources TEXT, videos TEXT, session_id INTEGER, status TEXT);
CREATE TABLE IF NOT EXISTS sessions (id INTEGER PRIMARY KEY AUTOINCREMENT, student_id INTEGER, mini_session_id INTEGER, content_json TEXT, quiz_json TEXT);
CREATE TABLE IF NOT EXISTS quiz_results (id INTEGER PRIMARY KEY AUTOINCREMENT, student_id INTEGER, session_id INTEGER, question TEXT, answer TEXT, score INTEGER, difficulty TEXT);
