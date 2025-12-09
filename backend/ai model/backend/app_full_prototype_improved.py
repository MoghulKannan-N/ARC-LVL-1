# backend/app_full_prototype_improved.py
import os
import json
import sqlite3
import socket
import logging
from typing import List, Optional, Dict, Any
from fastapi import FastAPI, Form, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from dotenv import load_dotenv

# OpenAI client (SDK)
from openai import OpenAI

load_dotenv()
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("ai-roadmap")

# CONFIG
DB_FILE = os.environ.get("DB_FILE", "college.db")
OPENAI_KEY = os.environ.get("OPENAI_API_KEY")
if not OPENAI_KEY:
    logger.warning("OPENAI_API_KEY not set in environment (OpenAI calls may fail).")

client = OpenAI()  # reads OPENAI_API_KEY from env

MODEL_STUDY = os.environ.get("MODEL_STUDY", "gpt-4o")
MODEL_QUIZ = os.environ.get("MODEL_QUIZ", "gpt-4o-mini")
MODEL_PLANNER = os.environ.get("MODEL_PLANNER", "gpt-5-nano")
DEFAULT_MODEL = os.environ.get("DEFAULT_MODEL", MODEL_PLANNER)

app = FastAPI(title="AI Roadmap Prototype (DB-backed)")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_origin_regex=".*",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ---------------- DB helpers ----------------
def get_conn():
    conn = sqlite3.connect(DB_FILE, timeout=30)
    conn.row_factory = sqlite3.Row
    return conn

def query_db(query: str, args: tuple = (), one: bool = False):
    conn = get_conn()
    try:
        cur = conn.cursor()
        cur.execute(query, args)
        if query.strip().upper().startswith("SELECT"):
            rows = cur.fetchall()
            results = [dict(r) for r in rows]
            return results[0] if (one and results) else (results if not one else None)
        else:
            conn.commit()
            return None
    finally:
        conn.close()

# ---------------- FIXED ensure_schema() — SAFE DB CREATION ----------------
def ensure_schema():
    conn = get_conn()
    cur = conn.cursor()

    # 1) students table
    cur.execute("""
        CREATE TABLE IF NOT EXISTS students (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            dept TEXT,
            points INTEGER DEFAULT 0,
            progress INTEGER DEFAULT 0
        );
    """)

    # 2) roadmap table (parent_id included from start)
    cur.execute("""
        CREATE TABLE IF NOT EXISTS roadmap (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            student_id INTEGER,
            topic TEXT,
            subtopic TEXT,
            resources TEXT,
            position INTEGER,
            status TEXT DEFAULT 'pending',
            parent_id INTEGER
        );
    """)

    # 3) mini_sessions table
    cur.execute("""
        CREATE TABLE IF NOT EXISTS mini_sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            roadmap_id INTEGER,
            student_id INTEGER,
            mini_title TEXT,
            description TEXT,
            estimated_minutes INTEGER,
            resources TEXT,
            videos TEXT,
            status TEXT DEFAULT 'pending',
            session_id INTEGER
        );
    """)

    # 4) sessions table
    cur.execute("""
        CREATE TABLE IF NOT EXISTS sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            student_id INTEGER,
            mini_session_id INTEGER,
            content_json TEXT,
            quiz_json TEXT
        );
    """)

    # 5) quiz_results table
    cur.execute("""
        CREATE TABLE IF NOT EXISTS quiz_results (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            student_id INTEGER,
            session_id INTEGER,
            question TEXT,
            answer TEXT,
            score INTEGER,
            difficulty TEXT
        );
    """)

    conn.commit()
    conn.close()

ensure_schema()

# ---------------- OpenAI helpers ----------------
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
    except Exception:
        logger.exception("OpenAI text error")
        return "Content unavailable due to AI error."

def openai_json(prompt: str, schema: str, model: str, max_tokens: int = 1500) -> dict:
    models_try = [model]
    if model == "gpt-5-nano":
        models_try.append("gpt-4o-mini")

    for m in models_try:
        try:
            resp = client.chat.completions.create(
                model=m,
                messages=[
                    {"role": "system", "content": "Planner. Always return valid JSON strictly following schema."},
                    {"role": "user", "content": f"Schema: {schema}\n\nTask: {prompt}"}
                ],
                max_completion_tokens=max_tokens,
                response_format={"type": "json_object"}
            )
            content = resp.choices[0].message.content
            return content if isinstance(content, (dict, list)) else json.loads(content)
        except Exception:
            logger.warning(f"OpenAI JSON failed with model {m}")
            continue

    return {}

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
# ---------------- Helpers for external content ----------------
def fetch_youtube_links(query: str, max_results: int = 3) -> List[str]:
    try:
        from ddgs import DDGS
        vids = []
        with DDGS() as ddgs:
            for v in ddgs.videos(query, max_results=max_results):
                link = v.get("content") or v.get("url")
                if link and link not in vids:
                    vids.append(link)
        return vids
    except Exception:
        logger.debug("DDGS unavailable")
        return []

def fetch_text_links(query: str, max_results: int = 8) -> List[str]:
    try:
        from ddgs import DDGS
        links = []
        with DDGS() as ddgs:
            for r in ddgs.text(query, max_results=max_results):
                link = r.get("href") or r.get("url")
                if link and link not in links:
                    links.append(link)
        return links
    except Exception:
        logger.debug("DDGS unavailable")
        return []

# ---------------- Response Models ----------------
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

# ---------------- Routes ----------------
@app.get("/")
def root():
    return {"message": "Backend is running", "status": "ok"}

@app.post("/add_student")
def add_student(name: str = Form(...), dept: str = Form(...)):
    query_db("INSERT INTO students (name, dept) VALUES (?,?)", (name, dept))
    student = query_db(
        "SELECT id, name, dept FROM students ORDER BY id DESC LIMIT 1",
        one=True
    )
    return {"message": "Student added", "student": student}

@app.get("/list_students")
def list_students():
    return query_db("SELECT id, name, dept, points, progress FROM students")

@app.post("/reset_student")
def reset_student(student_id: int = Form(...)):
    query_db("DELETE FROM roadmap WHERE student_id=?", (student_id,))
    query_db("DELETE FROM mini_sessions WHERE student_id=?", (student_id,))
    query_db("DELETE FROM sessions WHERE student_id=?", (student_id,))
    query_db("DELETE FROM quiz_results WHERE student_id=?", (student_id,))
    query_db("UPDATE students SET points=0, progress=0 WHERE id=?", (student_id,))
    return {"message": "Student reset complete"}

# ---------------- Roadmap Generation ----------------
@app.post("/generate_roadmap", response_model=RoadmapOut)
def generate_roadmap(student_id: int = Form(...), topic: str = Form(...)):
    prompt = (
        f"Break the topic '{topic}' into a complete roadmap with major subtopics."
    )
    schema = '{"roadmap":[{"subtopic":str,"description":str}]}'

    roadmap_data = openai_json(prompt, schema, model=MODEL_PLANNER).get("roadmap", [])
    if not roadmap_data:
        roadmap_data = [{"subtopic": f"{topic} Basics"}]

    conn = get_conn()
    cur = conn.cursor()

    # Determine starting position
    row = query_db(
        "SELECT MAX(position) AS mx FROM roadmap WHERE student_id=?",
        (student_id,),
        one=True
    )
    start_pos = (row["mx"] + 1) if row and row["mx"] is not None else 1

    # Insert roadmap entries
    for offset, item in enumerate(roadmap_data):
        pos = start_pos + offset
        cur.execute("""
            INSERT INTO roadmap (
                student_id, topic, subtopic, resources, position, status, parent_id
            ) VALUES (?, ?, ?, ?, ?, ?, ?)
        """, (
            student_id,
            topic,
            item.get("subtopic", f"{topic} {pos}"),
            json.dumps(item.get("resources", [])),
            pos,
            "pending",
            None
        ))

    conn.commit()
    conn.close()

    return {"student_id": student_id, "topic": topic, "roadmap": roadmap_data}

# ---------------- DB-read Endpoints ----------------
@app.get("/roadmap_list")
def roadmap_list(student_id: int = Query(...)):
    rows = query_db("""
        SELECT id, topic, subtopic, resources, position, status, parent_id
        FROM roadmap
        WHERE student_id=?
        ORDER BY position ASC
    """, (student_id,))

    # Convert JSON
    for r in rows:
        try:
            r["resources"] = json.loads(r["resources"]) if r.get("resources") else []
        except:
            r["resources"] = []

    return {"student_id": student_id, "roadmap": rows}

@app.get("/mini_sessions_list")
def mini_sessions_list(student_id: int = Query(...), roadmap_id: Optional[int] = Query(None)):
    if roadmap_id:
        rows = query_db("""
            SELECT * FROM mini_sessions
            WHERE student_id=? AND roadmap_id=?
            ORDER BY id ASC
        """, (student_id, roadmap_id))
    else:
        rows = query_db("""
            SELECT * FROM mini_sessions
            WHERE student_id=?
            ORDER BY id ASC
        """, (student_id,))

    for r in rows:
        try: r["resources"] = json.loads(r["resources"]) if r["resources"] else []
        except: r["resources"] = []
        try: r["videos"] = json.loads(r["videos"]) if r["videos"] else []
        except: r["videos"] = []

    return {"student_id": student_id, "mini_sessions": rows}

@app.get("/mini_session_detail")
def mini_session_detail(session_id: int = Query(...)):
    row = query_db(
        "SELECT content_json, quiz_json, student_id, mini_session_id FROM sessions WHERE id=?",
        (session_id,),
        one=True
    )
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
# ---------------- next_mini_session (prioritize child sessions) ----------------
@app.get("/next_mini_session", response_model=MiniSessionOut)
def next_mini_session(student_id: int):

    # 1) Pending CHILD mini-sessions first
    child_query = """
        SELECT m.*
        FROM mini_sessions m
        JOIN roadmap r ON m.roadmap_id = r.id
        WHERE m.student_id=? AND m.status='pending' AND r.parent_id IS NOT NULL
        ORDER BY r.position ASC, m.id ASC
        LIMIT 1
    """
    conn = get_conn()
    cur = conn.cursor()
    cur.execute(child_query, (student_id,))
    row = cur.fetchone()

    if row:
        pending_ms = dict(row)
        conn.close()

        # If content already generated → return it
        if pending_ms.get("session_id"):
            sess = query_db("SELECT content_json, quiz_json FROM sessions WHERE id=?",
                            (pending_ms["session_id"],), one=True)

            content = json.loads(sess["content_json"])["content"] if sess and sess["content_json"] else ""
            quiz = json.loads(sess["quiz_json"]) if sess and sess["quiz_json"] else []
            resources = json.loads(pending_ms["resources"]) if pending_ms.get("resources") else []
            videos = json.loads(pending_ms["videos"]) if pending_ms.get("videos") else []

            parent = ""
            parent_row = query_db("SELECT subtopic FROM roadmap WHERE id=?",
                                  (pending_ms.get("roadmap_id"),), one=True)
            if parent_row:
                parent = parent_row["subtopic"]

            return {
                "mini_session_id": pending_ms["id"],
                "parent_subtopic": parent,
                "mini_subtopic": pending_ms["mini_title"],
                "content": content,
                "resources": resources,
                "videos": videos,
                "quiz": quiz
            }

        # Otherwise generate content now
        mini_id = pending_ms["id"]
        mini_title = pending_ms["mini_title"]

        resources = fetch_text_links(mini_title)
        videos = fetch_youtube_links(mini_title)

        content = openai_text(
            f"Write an 800-1200 word study guide for '{mini_title}'. "
            "Sections: Intro; Key Concepts; Worked Examples; Exercises.",
            model=MODEL_STUDY, max_tokens=2000
        )

        quiz_schema = '{"questions":[{"difficulty":str,"type":str,"question":str,"options":[str],"correct_answer":str,"rationale":str}]}'
        quiz_prompt = (
            f"Using this content:\n\n{content}\n\n"
            "Generate 10 MCQs (5 Easy, 3 Medium, 2 Hard). Return JSON."
        )
        quiz = openai_json(quiz_prompt, quiz_schema, model=MODEL_QUIZ).get("questions", [])
        if not quiz:
            quiz = [{"difficulty": "Easy", "type": "mcq",
                     "question": "Fallback Q1", "options": ["A", "B", "C", "D"],
                     "correct_answer": "A", "rationale": "Fallback"}]

        conn = get_conn()
        cur = conn.cursor()

        # Insert into sessions
        cur.execute("""
            INSERT INTO sessions (student_id, mini_session_id, content_json, quiz_json)
            VALUES (?, ?, ?, ?)
        """, (student_id, mini_id, json.dumps({"content": content}), json.dumps(quiz)))
        session_id = cur.lastrowid

        # Update mini session
        cur.execute("""
            UPDATE mini_sessions SET session_id=?, resources=?, videos=?
            WHERE id=?
        """, (session_id, json.dumps(resources), json.dumps(videos), mini_id))

        conn.commit()
        conn.close()

        parent = ""
        parent_row = query_db("SELECT subtopic FROM roadmap WHERE id=?",
                              (pending_ms.get("roadmap_id"),), one=True)
        if parent_row:
            parent = parent_row["subtopic"]

        return {
            "mini_session_id": mini_id,
            "parent_subtopic": parent,
            "mini_subtopic": mini_title,
            "content": content,
            "resources": resources,
            "videos": videos,
            "quiz": quiz
        }

    # 2) Pending TOP-LEVEL mini sessions (parent_id IS NULL)
    top_query = """
        SELECT m.*
        FROM mini_sessions m
        JOIN roadmap r ON m.roadmap_id = r.id
        WHERE m.student_id=? AND m.status='pending' AND r.parent_id IS NULL
        ORDER BY r.position ASC, m.id ASC
        LIMIT 1
    """
    conn = get_conn()
    cur = conn.cursor()
    cur.execute(top_query, (student_id,))
    row = cur.fetchone()

    if row:
        pending_ms = dict(row)
        conn.close()

        if pending_ms.get("session_id"):
            sess = query_db("SELECT content_json, quiz_json FROM sessions WHERE id=?",
                            (pending_ms["session_id"],), one=True)

            content = json.loads(sess["content_json"])["content"] if sess and sess["content_json"] else ""
            quiz = json.loads(sess["quiz_json"]) if sess and sess["quiz_json"] else []
            resources = json.loads(pending_ms["resources"]) if pending_ms.get("resources") else []
            videos = json.loads(pending_ms["videos"]) if pending_ms.get("videos") else []

            parent = ""
            parent_row = query_db("SELECT subtopic FROM roadmap WHERE id=?",
                                  (pending_ms.get("roadmap_id"),), one=True)
            if parent_row:
                parent = parent_row["subtopic"]

            return {
                "mini_session_id": pending_ms["id"],
                "parent_subtopic": parent,
                "mini_subtopic": pending_ms["mini_title"],
                "content": content,
                "resources": resources,
                "videos": videos,
                "quiz": quiz
            }

        # Otherwise generate content now (same logic)
        mini_id = pending_ms["id"]
        mini_title = pending_ms["mini_title"]

        resources = fetch_text_links(mini_title)
        videos = fetch_youtube_links(mini_title)

        content = openai_text(
            f"Write an 800-1200 word study guide for '{mini_title}'.",
            model=MODEL_STUDY, max_tokens=2000
        )

        quiz_schema = '{"questions":[{"difficulty":str,"type":str,"question":str,"options":[str],"correct_answer":str,"rationale":str}]}'
        quiz_prompt = f"Using this content:\n\n{content}\n\nGenerate 10 MCQs in JSON."

        quiz = openai_json(quiz_prompt, quiz_schema, model=MODEL_QUIZ).get("questions", [])
        if not quiz:
            quiz = [{"difficulty": "Easy", "type": "mcq",
                     "question": "Fallback Q1", "options": ["A", "B", "C", "D"],
                     "correct_answer": "A", "rationale": "Fallback"}]

        conn = get_conn()
        cur = conn.cursor()
        cur.execute("""
            INSERT INTO sessions (student_id, mini_session_id, content_json, quiz_json)
            VALUES (?, ?, ?, ?)
        """, (student_id, mini_id, json.dumps({"content": content}), json.dumps(quiz)))

        session_id = cur.lastrowid

        cur.execute("""
            UPDATE mini_sessions SET session_id=?, resources=?, videos=?
            WHERE id=?
        """, (session_id, json.dumps(resources), json.dumps(videos), mini_id))

        conn.commit()
        conn.close()

        parent = ""
        parent_row = query_db("SELECT subtopic FROM roadmap WHERE id=?",
                              (pending_ms.get("roadmap_id"),), one=True)
        if parent_row:
            parent = parent_row["subtopic"]

        return {
            "mini_session_id": mini_id,
            "parent_subtopic": parent,
            "mini_subtopic": mini_title,
            "content": content,
            "resources": resources,
            "videos": videos,
            "quiz": quiz
        }

    # 3) No mini sessions → create one for next pending roadmap
    roadmap_row = query_db("""
        SELECT id, subtopic
        FROM roadmap
        WHERE student_id=? AND status='pending' AND parent_id IS NULL
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

    parent_subtopic = roadmap_row["subtopic"]
    roadmap_id = roadmap_row["id"]

    conn = get_conn()
    cur = conn.cursor()

    mini_title = f"{parent_subtopic} - Part 1"
    cur.execute("""
        INSERT INTO mini_sessions (
            roadmap_id, student_id, mini_title, estimated_minutes,
            resources, videos, status
        ) VALUES (?, ?, ?, ?, ?, ?, ?)
    """, (roadmap_id, student_id, mini_title, 50,
          json.dumps([]), json.dumps([]), "pending"))

    mini_id = cur.lastrowid
    conn.commit()
    conn.close()

    return next_mini_session(student_id)

# ---------------- complete_mini_session ----------------
@app.post("/complete_mini_session")
def complete_mini_session(student_id: int = Form(...),
                          mini_session_id: int = Form(...),
                          quiz_answers: str = Form(...)):

    try:
        payload = json.loads(quiz_answers)
    except:
        raise HTTPException(status_code=400, detail="Invalid quiz JSON")

    session_row = query_db("""
        SELECT id, quiz_json
        FROM sessions
        WHERE mini_session_id=?
    """, (mini_session_id,), one=True)

    if not session_row:
        raise HTTPException(status_code=404, detail="Quiz session not found")

    session_id = session_row["id"]
    quiz_list = json.loads(session_row["quiz_json"]) if session_row["quiz_json"] else []

    answers = payload.get("answers", {}) if isinstance(payload, dict) else {}

    total = len(quiz_list)
    correct = 0
    results = []

    for i, q in enumerate(quiz_list):
        submitted = answers.get(str(i)) or answers.get(i)
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
            VALUES (?, ?, ?, ?, ?, ?)
        """, (student_id, session_id, q["question"], submitted, 1 if is_correct else 0, q.get("difficulty", "")))

    score_pct = int((correct / total) * 100) if total > 0 else 0

    # PASS
    if score_pct >= 60:
        query_db("UPDATE mini_sessions SET status='done' WHERE id=?", (mini_session_id,))
        roadmap_row = query_db("SELECT roadmap_id FROM mini_sessions WHERE id=?",
                               (mini_session_id,), one=True)

        if roadmap_row and roadmap_row.get("roadmap_id"):
            query_db("UPDATE roadmap SET status='done' WHERE id=?", (roadmap_row["roadmap_id"],))

        return {
            "message": f"✅ Quiz passed ({score_pct}%).",
            "score_pct": score_pct,
            "results": results
        }

    # FAIL — you already had correct logic; unchanged
    # (kept exactly as your original, only removed broken schema logic)

    return {
        "message": f"❌ Quiz failed ({score_pct}%). Try again.",
        "score_pct": score_pct,
        "results": results
    }

# ---------------- open_mini_session ----------------
@app.get("/open_mini_session")
def open_mini_session(mini_session_id: int):
    ms = query_db("SELECT * FROM mini_sessions WHERE id=?", (mini_session_id,), one=True)
    if not ms:
        raise HTTPException(status_code=404, detail="Mini session not found")

    # Already has content
    if ms.get("session_id"):
        sess = query_db("SELECT content_json, quiz_json FROM sessions WHERE id=?",
                        (ms["session_id"],), one=True)
        return {
            "mini_session_id": mini_session_id,
            "content": json.loads(sess["content_json"])["content"],
            "quiz": json.loads(sess["quiz_json"])
        }

    # Otherwise generate fresh
    mini_title = ms["mini_title"]

    content = openai_text(
        f"Write a study guide for '{mini_title}'.",
        model=MODEL_STUDY, max_tokens=2000
    )

    quiz_schema = '{"questions":[{"difficulty":str,"type":str,"question":str,"options":[str],"correct_answer":str,"rationale":str}]}'
    quiz_prompt = f"Generate 8 MCQs for '{mini_title}'. Return JSON."
    quiz = openai_json(quiz_prompt, quiz_schema, model=MODEL_QUIZ).get("questions", [])

    if not quiz:
        quiz = [{"difficulty": "Easy", "type": "mcq",
                 "question": "Fallback", "options": ["A","B","C","D"],
                 "correct_answer": "A", "rationale": "Fallback"}]

    conn = get_conn()
    cur = conn.cursor()
    cur.execute("""
        INSERT INTO sessions (student_id, mini_session_id, content_json, quiz_json)
        VALUES (?, ?, ?, ?)
    """, (ms["student_id"], mini_session_id, json.dumps({"content": content}), json.dumps(quiz)))

    session_id = cur.lastrowid
    cur.execute("UPDATE mini_sessions SET session_id=? WHERE id=?",
                (session_id, mini_session_id))

    conn.commit()
    conn.close()

    return {
        "mini_session_id": mini_session_id,
        "content": content,
        "quiz": quiz
    }

# ---------------- Progress ----------------
@app.get("/progress_roadmap", response_model=ProgressOut)
def progress_roadmap(student_id: int = Query(...)):
    total = query_db("SELECT COUNT(*) AS cnt FROM mini_sessions WHERE student_id=?", (student_id,), one=True)["cnt"]
    done = query_db("SELECT COUNT(*) AS cnt FROM mini_sessions WHERE student_id=? AND status='done'",
                    (student_id,), one=True)["cnt"]
    pct = int((done/total) * 100) if total > 0 else 0
    return {"student_id": student_id, "completed": done, "total": total, "progress": f"{pct}%"}

# ---------------- Chatbot ----------------
@app.post("/chatbot")
def chatbot(message: str = Form(...)):
    try:
        resp = client.chat.completions.create(
            model=DEFAULT_MODEL,
            messages=[
                {"role": "system", "content": "Helpful assistant. Give full working code when asked."},
                {"role": "user", "content": message}
            ],
            max_completion_tokens=1200
        )
        reply = resp.choices[0].message.content
        return {"reply": reply.strip()}
    except Exception as e:
        logger.exception("Chatbot error")
        return {"reply": f"⚠️ Error: {e}"}

# ---------------- Health Check ----------------
@app.get("/health")
def health():
    return {"status": "ok", "db_exists": os.path.exists(DB_FILE)}

