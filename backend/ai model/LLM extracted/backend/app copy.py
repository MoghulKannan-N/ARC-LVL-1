# ============================================================
# backend/app_full_prototype_improved.py  (POSTGRESQL VERSION)
# PART 1 / 3
# ============================================================

import os
import json
import socket
import logging
from typing import List, Optional, Dict, Any

import psycopg2
import psycopg2.extras

from fastapi import FastAPI, Form, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from dotenv import load_dotenv

from openai import OpenAI
# ============================================================
# Pydantic Response Models  (REQUIRED)
# ============================================================

class RoadmapOut(BaseModel):
    student_id: int
    topic: str
    roadmap: List[dict]


class MiniSessionOut(BaseModel):
    mini_session_id: int
    parent_subtopic: str
    mini_subtopic: str
    content: Optional[str] = None
    resources: List[str] = []
    videos: List[str] = []
    quiz: List[dict] = []


class ProgressOut(BaseModel):
    student_id: int
    completed: int
    total: int
    progress: str

load_dotenv()

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("ai-roadmap")

# ============================================================
# CONFIG
# ============================================================

DB = {
    "dbname": "Smart_curriculum",
    "user": "postgres",
    "password": "Dhana@2007",
    "host": "localhost",
    "port": 5433,
}



OPENAI_KEY = os.environ.get("OPENAI_API_KEY")
if not OPENAI_KEY:
    logger.warning("OPENAI_API_KEY not set!")

client = OpenAI()  # reads OPENAI_API_KEY from env

MODEL_STUDY = os.environ.get("MODEL_STUDY", "gpt-4o")
MODEL_QUIZ = os.environ.get("MODEL_QUIZ", "gpt-4o-mini")
MODEL_PLANNER = os.environ.get("MODEL_PLANNER", "gpt-5-nano")
DEFAULT_MODEL = os.environ.get("DEFAULT_MODEL", MODEL_PLANNER)

app = FastAPI(title="AI Roadmap + Student Intelligence System (PostgreSQL Backend)")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_origin_regex=".*",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ============================================================
# PostgreSQL CONNECTION HELPERS
# ============================================================

def get_conn():
    """Create PostgreSQL connection."""
    return psycopg2.connect(
        dbname=DB["dbname"],
        user=DB["user"],
        password=DB["password"],
        host=DB["host"],
        port=DB["port"]
    )

def query_db(query: str, args: tuple = (), one: bool = False):
    """Unified DB executor — SELECT returns dict rows, others commit."""
    conn = get_conn()
    try:
        cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
        cur.execute(query, args)

        if query.strip().upper().startswith("SELECT"):
            rows = cur.fetchall()
            if one:
                return rows[0] if rows else None
            return rows
        else:
            conn.commit()
            return None

    except Exception as e:
        logger.error("DB ERROR: %s", e)
        raise
    finally:
        conn.close()

# ============================================================
# ENSURE SCHEMA (MATCHES YOUR POSTGRES TABLES)
# ============================================================

def ensure_schema():
    """Creates all tables exactly as user defined — safe & idempotent."""
    conn = get_conn()
    cur = conn.cursor()

    cur.execute("""
        CREATE TABLE IF NOT EXISTS student_profiles (
            id BIGSERIAL PRIMARY KEY,
            student_name VARCHAR(255) NOT NULL,
            date_of_birth VARCHAR(255),
            phone_number VARCHAR(255),
            strength TEXT,
            weakness TEXT,
            interest TEXT,
            year_of_studying VARCHAR(255),
            course VARCHAR(255)
        );
    """)

    cur.execute("""
        CREATE TABLE IF NOT EXISTS student_learning_status (
            id SERIAL PRIMARY KEY,
            student_id BIGINT NOT NULL,
            current_topic TEXT,
            progress INT DEFAULT 0,
            last_updated TIMESTAMP DEFAULT NOW(),
            FOREIGN KEY (student_id) REFERENCES student_profiles(id)
        );
    """)

    cur.execute("""
        CREATE TABLE IF NOT EXISTS roadmap (
            id SERIAL PRIMARY KEY,
            student_id BIGINT,
            topic TEXT,
            subtopic TEXT,
            resources TEXT,
            position INT,
            status VARCHAR(50),
            parent_id INT,
            FOREIGN KEY (student_id) REFERENCES student_profiles(id)
        );
    """)

    cur.execute("""
        CREATE TABLE IF NOT EXISTS mini_sessions (
            id SERIAL PRIMARY KEY,
            roadmap_id BIGINT,
            student_id BIGINT,
            mini_title TEXT,
            description TEXT,
            estimated_minutes INT,
            resources TEXT,
            videos TEXT,
            status VARCHAR(50),
            session_id BIGINT,
            FOREIGN KEY (roadmap_id) REFERENCES roadmap(id),
            FOREIGN KEY (student_id) REFERENCES student_profiles(id)
        );
    """)

    cur.execute("""
        CREATE TABLE IF NOT EXISTS sessions (
            id SERIAL PRIMARY KEY,
            student_id BIGINT,
            mini_session_id BIGINT,
            content_json TEXT,
            quiz_json TEXT,
            FOREIGN KEY (student_id) REFERENCES student_profiles(id),
            FOREIGN KEY (mini_session_id) REFERENCES mini_sessions(id)
        );
    """)

    cur.execute("""
        CREATE TABLE IF NOT EXISTS quiz_results (
            id SERIAL PRIMARY KEY,
            student_id BIGINT,
            session_id BIGINT,
            question TEXT,
            answer TEXT,
            score INT,
            difficulty TEXT,
            FOREIGN KEY (student_id) REFERENCES student_profiles(id),
            FOREIGN KEY (session_id) REFERENCES sessions(id)
        );
    """)

    cur.execute("""
        CREATE TABLE IF NOT EXISTS student_faces (
            id SERIAL PRIMARY KEY,
            student_name VARCHAR(255) UNIQUE NOT NULL,
            embedding TEXT
        );
    """)

    conn.commit()
    conn.close()

ensure_schema()

# ============================================================
# OPENAI HELPERS
# ============================================================

def openai_text(prompt: str, model: str, max_tokens: int = 1500) -> str:
    try:
        resp = client.chat.completions.create(
            model=model,
            messages=[
                {"role": "system", "content": "Expert academic author. Produce clear study guides."},
                {"role": "user", "content": prompt}
            ],
            max_completion_tokens=max_tokens
        )
        return resp.choices[0].message.content
    except Exception as e:
        logger.exception("OpenAI text generation error:", e)
        return "AI content unavailable."

def openai_json(prompt: str, schema: str, model: str, max_tokens: int = 1500) -> dict:
    models_try = [model]
    if model == "gpt-5-nano":
        models_try.append("gpt-4o-mini")

    for m in models_try:
        try:
            resp = client.chat.completions.create(
                model=m,
                messages=[
                    {"role": "system", "content": "Return JSON only. Follow structure strictly."},
                    {"role": "user", "content": f"Schema: {schema}\n\nTask: {prompt}"}
                ],
                response_format={"type": "json_object"},
                max_completion_tokens=max_tokens
            )
            content = resp.choices[0].message.content
            return content if isinstance(content, (dict, list)) else json.loads(content)

        except Exception:
            logger.warning(f"OpenAI JSON mode failed with {m}, retrying...")
            continue

    return {}

# ============================================================
# Helper to get server LAN IP
# ============================================================

def get_local_ip():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except:
        return "127.0.0.1"

print("🔌 Backend running on: http://" + get_local_ip() + ":8000")
# ============================================================
# HELPER: AUTO-GENERATE RESOURCE LINKS (TEXT + YOUTUBE)
# ============================================================

def fetch_text_links(topic: str) -> list:
    """
    Uses OpenAI to generate 3–5 high-quality text/article resources.
    Returns them as a Python list of strings.
    """
    try:
        prompt = f"""
        Give me 3 to 5 real, high-quality learning resources (articles, documentation, tutorials)
        for the topic: '{topic}'.
        Return ONLY a JSON list of URLs.
        """

        data = openai_json(prompt, '["url"]', model=MODEL_PLANNER)
        if isinstance(data, list):
            return data
        return []
    except Exception:
        return []


def fetch_youtube_links(topic: str) -> list:
    """
    Generates 3–5 YouTube tutorial links related to the topic.
    """
    try:
        prompt = f"""
        Give me 3 to 5 YouTube video tutorial links for the topic: '{topic}'.
        Return only a JSON list of URLs.
        """

        data = openai_json(prompt, '["url"]', model=MODEL_PLANNER)
        if isinstance(data, list):
            return data
        return []
    except Exception:
        return []
# ============================================================
# PART 2 / 3 — STUDENTS • ROADMAP • MINI SESSIONS
# ============================================================

# ---------------- ROUTES ----------------

@app.get("/")
def root():
    return {"message": "Backend is running", "status": "ok"}


# ============================================================
# ADD STUDENT
# ============================================================
@app.post("/add_student")
def add_student(
    student_name: str = Form(...),
    date_of_birth: str = Form(None),
    phone_number: str = Form(None),
    strength: str = Form(None),
    weakness: str = Form(None),
    interest: str = Form(None),
    year_of_studying: str = Form(None),
    course: str = Form(None),
):
    """Creates a new student inside student_profiles."""
    query_db("""
        INSERT INTO student_profiles
        (student_name, date_of_birth, phone_number, strength, weakness, interest, year_of_studying, course)
        VALUES (%s,%s,%s,%s,%s,%s,%s,%s)
    """, (
        student_name, date_of_birth, phone_number, strength,
        weakness, interest, year_of_studying, course
    ))

    student = query_db("""
        SELECT * FROM student_profiles
        ORDER BY id DESC LIMIT 1
    """, one=True)

    return {"message": "Student added", "student": student}


# ============================================================
# LIST STUDENTS
# ============================================================
@app.get("/list_students")
def list_students():
    return query_db("SELECT * FROM student_profiles ORDER BY id ASC")


# ============================================================
# RESET STUDENT (remove all learning data)
# ============================================================
@app.post("/reset_student")
def reset_student(student_id: int = Form(...)):

    query_db("DELETE FROM roadmap WHERE student_id=%s", (student_id,))
    query_db("DELETE FROM mini_sessions WHERE student_id=%s", (student_id,))
    query_db("DELETE FROM sessions WHERE student_id=%s", (student_id,))
    query_db("DELETE FROM quiz_results WHERE student_id=%s", (student_id,))
    query_db("DELETE FROM student_learning_status WHERE student_id=%s", (student_id,))

    return {"message": "Student reset complete"}


# ============================================================
# GENERATE ROADMAP
# ============================================================
@app.post("/generate_roadmap", response_model=RoadmapOut)
def generate_roadmap(student_id: int = Form(...), topic: str = Form(...)):

    prompt = (
        f"Break the topic '{topic}' into a complete roadmap with major subtopics. "
        "Return a JSON array named 'roadmap'."
    )
    schema = '{"roadmap":[{"subtopic":str,"description":str}]}'

    ai_roadmap = openai_json(prompt, schema, model=MODEL_PLANNER).get("roadmap", [])
    if not ai_roadmap:
        ai_roadmap = [{"subtopic": f"{topic} Basics"}]

    # Determine next position
    row = query_db("SELECT MAX(position) AS mx FROM roadmap WHERE student_id=%s", (student_id,), one=True)
    start_position = (row["mx"] + 1) if row and row["mx"] is not None else 1

    # Insert roadmap rows
    conn = get_conn()
    cur = conn.cursor()
    for i, item in enumerate(ai_roadmap):
        cur.execute("""
            INSERT INTO roadmap (student_id, topic, subtopic, resources, position, status, parent_id)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
        """, (
            student_id,
            topic,
            item.get("subtopic", f"{topic} {i+1}"),
            json.dumps(item.get("resources", [])),
            start_position + i,
            "pending",
            None
        ))
    conn.commit()
    conn.close()

    return {"student_id": student_id, "topic": topic, "roadmap": ai_roadmap}


# ============================================================
# ROADMAP LIST
# ============================================================
@app.get("/roadmap_list")
def roadmap_list(student_id: int = Query(...)):
    rows = query_db("""
        SELECT id, topic, subtopic, resources, position, status, parent_id
        FROM roadmap
        WHERE student_id=%s
        ORDER BY position ASC
    """, (student_id,))

    for r in rows:
        try:
            r["resources"] = json.loads(r["resources"]) if r["resources"] else []
        except:
            r["resources"] = []

    return {"student_id": student_id, "roadmap": rows}


# ============================================================
# MINI SESSIONS LIST
# ============================================================
@app.get("/mini_sessions_list")
def mini_sessions_list(student_id: int = Query(...), roadmap_id: Optional[int] = Query(None)):

    if roadmap_id:
        rows = query_db("""
            SELECT * FROM mini_sessions
            WHERE student_id=%s AND roadmap_id=%s
            ORDER BY id ASC
        """, (student_id, roadmap_id))
    else:
        rows = query_db("""
            SELECT * FROM mini_sessions
            WHERE student_id=%s
            ORDER BY id ASC
        """, (student_id,))

    for r in rows:
        try: r["resources"] = json.loads(r["resources"]) if r["resources"] else []
        except: r["resources"] = []
        try: r["videos"] = json.loads(r["videos"]) if r["videos"] else []
        except: r["videos"] = []

    return {"student_id": student_id, "mini_sessions": rows}


# ============================================================
# MINI SESSION DETAIL
# ============================================================
@app.get("/mini_session_detail")
def mini_session_detail(session_id: int = Query(...)):
    row = query_db("""
        SELECT content_json, quiz_json, student_id, mini_session_id
        FROM sessions
        WHERE id=%s
    """, (session_id,), one=True)

    if not row:
        raise HTTPException(status_code=404, detail="Session not found")

    content = json.loads(row["content_json"]) if row["content_json"] else {}
    quiz = json.loads(row["quiz_json"]) if row["quiz_json"] else []

    return {
        "session_id": session_id,
        "mini_session_id": row["mini_session_id"],
        "content": content.get("content", ""),
        "quiz": quiz
    }

# ============================================================
# NEXT MINI SESSION (CHILD-FIRST LOGIC)
# ============================================================

@app.get("/next_mini_session", response_model=MiniSessionOut)
def next_mini_session(student_id: int):
    """
    1) Prioritize child (split) mini sessions
    2) Then pending top-level mini sessions
    3) If none exist → create new mini session under next roadmap topic
    """

    # ------------------------------------------------------------
    # 1) PENDING CHILD MINI SESSIONS (r.parent_id IS NOT NULL)
    # ------------------------------------------------------------
    child_row = query_db("""
        SELECT m.*
        FROM mini_sessions m
        JOIN roadmap r ON r.id = m.roadmap_id
        WHERE m.student_id=%s
          AND m.status='pending'
          AND r.parent_id IS NOT NULL
        ORDER BY r.position ASC, m.id ASC
        LIMIT 1
    """, (student_id,), one=True)

    if child_row:

        # Already generated content?
        if child_row["session_id"]:
            sess = query_db("""
                SELECT content_json, quiz_json
                FROM sessions
                WHERE id=%s
            """, (child_row["session_id"],), one=True)

            content = json.loads(sess["content_json"])["content"]
            quiz = json.loads(sess["quiz_json"])
            resources = json.loads(child_row["resources"]) if child_row["resources"] else []
            videos = json.loads(child_row["videos"]) if child_row["videos"] else []

            parent = query_db("SELECT subtopic FROM roadmap WHERE id=%s",
                              (child_row["roadmap_id"],), one=True)
            parent_name = parent["subtopic"] if parent else ""

            return {
                "mini_session_id": child_row["id"],
                "parent_subtopic": parent_name,
                "mini_subtopic": child_row["mini_title"],
                "content": content,
                "resources": resources,
                "videos": videos,
                "quiz": quiz
            }

        # Content not generated yet → generate now
        return generate_mini_session_content(student_id, child_row)

    # ------------------------------------------------------------
    # 2) PENDING TOP-LEVEL MINI SESSIONS (NO parent_id)
    # ------------------------------------------------------------
    top_row = query_db("""
        SELECT m.*
        FROM mini_sessions m
        JOIN roadmap r ON r.id = m.roadmap_id
        WHERE m.student_id=%s
          AND m.status='pending'
          AND r.parent_id IS NULL
        ORDER BY r.position ASC, m.id ASC
        LIMIT 1
    """, (student_id,), one=True)

    if top_row:
        if top_row["session_id"]:
            sess = query_db("""
                SELECT content_json, quiz_json
                FROM sessions
                WHERE id=%s
            """, (top_row["session_id"],), one=True)

            content = json.loads(sess["content_json"])["content"]
            quiz = json.loads(sess["quiz_json"])
            resources = json.loads(top_row["resources"]) if top_row["resources"] else []
            videos = json.loads(top_row["videos"]) if top_row["videos"] else []

            parent = query_db("SELECT subtopic FROM roadmap WHERE id=%s",
                              (top_row["roadmap_id"],), one=True)
            parent_name = parent["subtopic"] if parent else ""

            return {
                "mini_session_id": top_row["id"],
                "parent_subtopic": parent_name,
                "mini_subtopic": top_row["mini_title"],
                "content": content,
                "resources": resources,
                "videos": videos,
                "quiz": quiz
            }

        return generate_mini_session_content(student_id, top_row)

    # ------------------------------------------------------------
    # 3) NO MINI SESSIONS → CREATE ONE FOR NEXT TOPIC
    # ------------------------------------------------------------
    roadmap_row = query_db("""
        SELECT id, subtopic
        FROM roadmap
        WHERE student_id=%s
          AND status='pending'
          AND parent_id IS NULL
        ORDER BY position ASC
        LIMIT 1
    """, (student_id,), one=True)

    if not roadmap_row:
        return {
            "mini_session_id": 0,
            "parent_subtopic": "",
            "mini_subtopic": "",
            "content": "",
            "resources": [],
            "videos": [],
            "quiz": [],
            "message": "🎉 All roadmap sessions complete!"
        }

    # Create first mini session automatically
    conn = get_conn()
    cur = conn.cursor()

    mini_title = f"{roadmap_row['subtopic']} - Part 1"
    cur.execute("""
        INSERT INTO mini_sessions (roadmap_id, student_id, mini_title,
            estimated_minutes, resources, videos, status)
        VALUES (%s,%s,%s,%s,%s,%s,%s)
    """, (
        roadmap_row["id"], student_id, mini_title,
        50, json.dumps([]), json.dumps([]), "pending"
    ))

    conn.commit()
    conn.close()

    return next_mini_session(student_id)
# ============================================================
# PART 3 / 3 — MINI SESSION CONTENT, COMPLETION, PROGRESS, CHATBOT
# ============================================================


# ============================================================
# HELPER: GENERATE CONTENT + QUIZ FOR A MINI SESSION
# ============================================================

def generate_mini_session_content(student_id: int, ms_row: dict):
    """
    Shared helper for next_mini_session.
    Generates study content + quiz for a pending mini session.
    Saves to DB and returns API response format.
    """

    mini_id = ms_row["id"]
    title = ms_row["mini_title"]

    resources = fetch_text_links(title)
    videos = fetch_youtube_links(title)

    content = openai_text(
        f"Write an 800-1200 word study guide for '{title}'. "
        "Sections: Introduction, Key Concepts, Examples, Exercises.",
        model=MODEL_STUDY,
        max_tokens=2000
    )

    quiz_schema = '{"questions":[{"difficulty":str,"type":str,"question":str,"options":[str],"correct_answer":str,"rationale":str}]}'
    quiz_prompt = (
        f"Using this content:\n\n{content}\n\n"
        "Generate EXACTLY 10 MCQs (5 Easy, 3 Moderate, 2 Hard). "
        "Return JSON strictly following schema."
    )

    quiz = openai_json(quiz_prompt, quiz_schema, model=MODEL_QUIZ).get("questions", [])
    if not quiz:
        quiz = [{
            "difficulty": "Easy",
            "type": "mcq",
            "question": "Fallback sample question",
            "options": ["A", "B", "C", "D"],
            "correct_answer": "A",
            "rationale": "Fallback"
        }]

    conn = get_conn()
    cur = conn.cursor()

    # Save new session
    cur.execute("""
        INSERT INTO sessions (student_id, mini_session_id, content_json, quiz_json)
        VALUES (%s,%s,%s,%s)
    """, (student_id, mini_id, json.dumps({"content": content}), json.dumps(quiz)))

    session_id = cur.lastrowid if hasattr(cur, "lastrowid") else None
    if session_id is None:
        cur.execute("SELECT MAX(id) FROM sessions")
        session_id = cur.fetchone()[0]

    # Update mini session
    cur.execute("""
        UPDATE mini_sessions SET session_id=%s, resources=%s, videos=%s
        WHERE id=%s
    """, (session_id, json.dumps(resources), json.dumps(videos), mini_id))

    conn.commit()
    conn.close()

    parent_row = query_db("SELECT subtopic FROM roadmap WHERE id=%s",
                          (ms_row["roadmap_id"],), one=True)
    parent = parent_row["subtopic"] if parent_row else ""

    return {
        "mini_session_id": mini_id,
        "parent_subtopic": parent,
        "mini_subtopic": title,
        "content": content,
        "resources": resources,
        "videos": videos,
        "quiz": quiz
    }



# ============================================================
# COMPLETE MINI SESSION (QUIZ GRADING + SPLITTING ALGORITHM)
# ============================================================

@app.post("/complete_mini_session")
def complete_mini_session(
    student_id: int = Form(...),
    mini_session_id: int = Form(...),
    quiz_answers: str = Form(...)
):
    """
    Evaluates quiz answers.
    If score < 60% → split roadmap entry into child parts (preserves original logic).
    """

    # -------------------------------
    # Parse answers
    # -------------------------------
    try:
        payload = json.loads(quiz_answers)
    except:
        raise HTTPException(status_code=400, detail="Invalid quiz_answers JSON")

    session_row = query_db("""
        SELECT id, quiz_json
        FROM sessions
        WHERE mini_session_id=%s
    """, (mini_session_id,), one=True)

    if not session_row:
        raise HTTPException(status_code=404, detail="Session not found for this mini session")

    session_id = session_row["id"]
    quiz_list = json.loads(session_row["quiz_json"]) if session_row["quiz_json"] else []

    answers = payload.get("answers", {}) if isinstance(payload, dict) else {}

    total = len(quiz_list)
    correct = 0
    results = []

    for idx, q in enumerate(quiz_list):
        submitted = answers.get(str(idx)) or answers.get(idx)
        is_correct = submitted and submitted.strip().lower() == q["correct_answer"].strip().lower()
        if is_correct:
            correct += 1

        results.append({
            "question": q["question"],
            "your_answer": submitted,
            "correct_answer": q["correct_answer"],
            "difficulty": q.get("difficulty", ""),
            "is_correct": is_correct
        })

        query_db("""
            INSERT INTO quiz_results (student_id, session_id, question, answer, score, difficulty)
            VALUES (%s,%s,%s,%s,%s,%s)
        """, (
            student_id, session_id,
            q["question"], submitted,
            1 if is_correct else 0,
            q.get("difficulty", "")
        ))

    score_pct = int((correct / total) * 100) if total else 0

    # ---------------------------------------------------------
    # PASS CASE
    # ---------------------------------------------------------
    if score_pct >= 60:
        query_db("UPDATE mini_sessions SET status='done' WHERE id=%s", (mini_session_id,))
        roadmap_ref = query_db("SELECT roadmap_id FROM mini_sessions WHERE id=%s",
                               (mini_session_id,), one=True)

        if roadmap_ref:
            query_db("UPDATE roadmap SET status='done' WHERE id=%s", (roadmap_ref["roadmap_id"],))

        return {
            "message": f"✅ Quiz passed ({score_pct}%).",
            "score_pct": score_pct,
            "results": results
        }

    # ---------------------------------------------------------
    # FAIL CASE — SPLIT INTO CHILD ROADMAP ITEMS
    # ---------------------------------------------------------

    parent_data = query_db("""
        SELECT r.id, r.subtopic, r.position, r.topic, r.student_id
        FROM roadmap r
        JOIN mini_sessions m ON m.roadmap_id = r.id
        WHERE m.id=%s
    """, (mini_session_id,), one=True)

    if not parent_data:
        return {
            "message": f"❌ Quiz failed ({score_pct}%). Parent roadmap not found.",
            "score_pct": score_pct,
            "results": results
        }

    parent_id = parent_data["id"]
    parent_subtopic = parent_data["subtopic"]
    topic = parent_data["topic"]
    position = parent_data["position"]
    student = parent_data["student_id"]

    # Mark parent as split
    query_db("UPDATE roadmap SET status='split' WHERE id=%s", (parent_id,))

    # Request 2-part split from AI
    split_schema = '{"sessions":[{"mini_subtopic":str,"description":str}]}'
    split_prompt = (
        f"The student failed on '{parent_subtopic}'. "
        "Split this into exactly 2 simplified focused parts. "
        "Return titles + short descriptions."
    )

    new_parts = openai_json(split_prompt, split_schema, model=DEFAULT_MODEL).get("sessions", [])
    if not new_parts or len(new_parts) < 2:
        new_parts = [
            {"mini_subtopic": f"{parent_subtopic} - Part A", "description": "Review first half"},
            {"mini_subtopic": f"{parent_subtopic} - Part B", "description": "Review second half"}
        ]

    conn = get_conn()
    cur = conn.cursor()

    # Shift subsequent roadmap positions downward
    cur.execute("""
        UPDATE roadmap SET position = position + %s
        WHERE student_id=%s AND position > %s
    """, (len(new_parts), student, position))

    new_ids = []
    new_sessions = []

    for i, part in enumerate(new_parts, start=1):
        new_pos = position + i

        # Insert new child roadmap row
        cur.execute("""
            INSERT INTO roadmap (student_id, topic, subtopic, resources, position, status, parent_id)
            VALUES (%s,%s,%s,%s,%s,%s,%s)
        """, (
            student, topic, part["mini_subtopic"], json.dumps([]),
            new_pos, "pending", parent_id
        ))

        new_rid = None
        try:
            new_rid = cur.lastrowid
        except:
            cur.execute("SELECT MAX(id) FROM roadmap")
            new_rid = cur.fetchone()[0]

        new_ids.append(new_rid)

        # Insert mini session under it
        cur.execute("""
            INSERT INTO mini_sessions (roadmap_id, student_id, mini_title,
                description, estimated_minutes, resources, videos, status)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s)
        """, (
            new_rid, student, part["mini_subtopic"],
            part.get("description", ""), 50,
            json.dumps([]), json.dumps([]), "pending"
        ))

        new_mini_id = None
        try:
            new_mini_id = cur.lastrowid
        except:
            cur.execute("SELECT MAX(id) FROM mini_sessions")
            new_mini_id = cur.fetchone()[0]

        # Generate simplified content
        simple_content = openai_text(
            f"Write a simplified 600-800 word study guide for '{part['mini_subtopic']}'.",
            model=MODEL_STUDY,
            max_tokens=1800
        )

        q_schema = '{"questions":[{"difficulty":str,"type":str,"question":str,"options":[str],"correct_answer":str,"rationale":str}]}'
        q_prompt = (
            f"Using this content:\n\n{simple_content}\n\n"
            "Generate 5 MCQs (3 easy, 2 moderate). Return JSON."
        )
        new_quiz = openai_json(q_prompt, q_schema, model=MODEL_QUIZ).get("questions", [])
        if not new_quiz:
            new_quiz = [{
                "difficulty": "Easy",
                "type": "mcq",
                "question": "Fallback question",
                "options": ["A","B","C","D"],
                "correct_answer": "A",
                "rationale": "Fallback"
            }]

        # Insert the session
        cur.execute("""
            INSERT INTO sessions (student_id, mini_session_id, content_json, quiz_json)
            VALUES (%s,%s,%s,%s)
        """, (
            student, new_mini_id,
            json.dumps({"content": simple_content}),
            json.dumps(new_quiz)
        ))

        new_session_id = None
        try:
            new_session_id = cur.lastrowid
        except:
            cur.execute("SELECT MAX(id) FROM sessions")
            new_session_id = cur.fetchone()[0]

        # Link back into mini_sessions
        cur.execute("""
            UPDATE mini_sessions SET session_id=%s
            WHERE id=%s
        """, (new_session_id, new_mini_id))

        new_sessions.append({
            "roadmap_id": new_rid,
            "mini_session_id": new_mini_id,
            "mini_subtopic": part["mini_subtopic"],
            "content": simple_content,
            "quiz": new_quiz
        })

    conn.commit()
    conn.close()

    updated_roadmap = query_db("""
        SELECT * FROM roadmap
        WHERE student_id=%s
        ORDER BY position ASC
    """, (student,))

    return {
        "message": f"❌ Quiz failed ({score_pct}%). Split into {len(new_parts)} parts.",
        "score_pct": score_pct,
        "results": results,
        "new_roadmap_ids": new_ids,
        "new_sessions": new_sessions,
        "updated_roadmap": updated_roadmap
    }



# ============================================================
# OPEN MINI SESSION (REVISIT)
# ============================================================

@app.get("/open_mini_session")
def open_mini_session(mini_session_id: int = Query(...)):
    ms = query_db("SELECT * FROM mini_sessions WHERE id=%s", (mini_session_id,), one=True)
    if not ms:
        raise HTTPException(status_code=404, detail="Mini session not found")

    if ms["session_id"]:
        sess = query_db("SELECT content_json, quiz_json FROM sessions WHERE id=%s",
                        (ms["session_id"],), one=True)

        return {
            "mini_session_id": mini_session_id,
            "content": json.loads(sess["content_json"])["content"],
            "quiz": json.loads(sess["quiz_json"])
        }

    # Otherwise create fresh on-demand
    return generate_mini_session_content(ms["student_id"], ms)



# ============================================================
# PROGRESS
# ============================================================

@app.get("/progress_roadmap", response_model=ProgressOut)
def progress_roadmap(student_id: int = Query(...)):
    total = query_db("SELECT COUNT(*) AS cnt FROM mini_sessions WHERE student_id=%s",
                     (student_id,), one=True)["cnt"]

    done = query_db("""
        SELECT COUNT(*) AS cnt
        FROM mini_sessions
        WHERE student_id=%s AND status='done'
    """, (student_id,), one=True)["cnt"]

    pct = int((done/total) * 100) if total else 0
    return {
        "student_id": student_id,
        "completed": done,
        "total": total,
        "progress": f"{pct}%"
    }



# ============================================================
# CHATBOT
# ============================================================

@app.post("/chatbot")
def chatbot(message: str = Form(...)):
    try:
        resp = client.chat.completions.create(
            model=DEFAULT_MODEL,
            messages=[
                {"role": "system", "content": "Helpful assistant. Provide complete working code when asked."},
                {"role": "user", "content": message}
            ],
            max_completion_tokens=1200
        )
        return {"reply": resp.choices[0].message.content.strip()}
    except Exception as e:
        logger.exception("Chatbot error")
        return {"reply": f"⚠️ Error: {e}"}



# ============================================================
# HEALTH CHECK
# ============================================================

@app.get("/health")
def health():
    try:
        # attempt a DB connection
        conn = get_conn()
        conn.close()
        db_ok = True
    except:
        db_ok = False

    return {
        "status": "ok",
        "db_connected": db_ok
    }
