# ============================================================
#  FASTAPI AI LEARNING ENGINE — POSTGRESQL VERSION
#  Personalized Roadmaps (Strength • Weakness • Interest)
#  SECTION 1 OF 4
# ============================================================

import os
import json
import socket
import logging
from typing import List, Optional, Dict, Any

from fastapi import FastAPI, Form, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from dotenv import load_dotenv

import psycopg2
import psycopg2.extras

from openai import OpenAI


# ============================================================
#  ENV + LOGGING
# ============================================================

load_dotenv()
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("ai-roadmap")

OPENAI_KEY = os.environ.get("OPENAI_API_KEY")
if not OPENAI_KEY:
    logger.warning("OPENAI_API_KEY missing — AI calls may fail.")

client = OpenAI()  # reads from env automatically


# ============================================================
#  PostgreSQL DATABASE CONFIG
# ============================================================

DB = {
    "dbname": "Smart_curriculum",
    "user": "postgres",
    "password": "Dhana@2007",
    "host": "localhost",
    "port": 5433,
}

def db_conn():
    return psycopg2.connect(**DB)

def query_db(query, params=(), fetchone=False, fetchall=False):
    """Generic PostgreSQL query function."""
    conn = db_conn()
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    cur.execute(query, params)

    result = None
    if fetchone:
        result = cur.fetchone()
    elif fetchall:
        result = cur.fetchall()

    conn.commit()
    cur.close()
    conn.close()
    return result


# ============================================================
#  MODEL SETTINGS
# ============================================================

MODEL_STUDY = os.environ.get("MODEL_STUDY", "gpt-4o")
MODEL_QUIZ = os.environ.get("MODEL_QUIZ", "gpt-4o-mini")
MODEL_PLANNER = os.environ.get("MODEL_PLANNER", "gpt-5-nano")
DEFAULT_MODEL = os.environ.get("DEFAULT_MODEL", MODEL_PLANNER)


# ============================================================
#  FASTAPI APP + CORS
# ============================================================

app = FastAPI(title="AI Roadmap Engine — PostgreSQL Edition")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_origin_regex=".*",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ============================================================
#  UTILS / HELPERS
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

print("🔌 Backend running at: http://" + get_local_ip() + ":8000")


def openai_text(prompt: str, model: str, max_tokens: int = 1500) -> str:
    """Call OpenAI for long text responses."""
    try:
        resp = client.chat.completions.create(
            model=model,
            messages=[
                {"role": "system",
                 "content": "Expert academic author. Produce clear, organized study material."},
                {"role": "user", "content": prompt}
            ],
            max_completion_tokens=max_tokens
        )
        return resp.choices[0].message.content or ""
    except Exception:
        logger.exception("OpenAI text error")
        return "⚠️ AI content unavailable."


def openai_json(prompt: str, schema: str, model: str, max_tokens: int = 1500) -> dict:
    """Force OpenAI to return JSON."""
    models_try = [model]
    if model == "gpt-5-nano":
        models_try.append("gpt-4o-mini")

    for m in models_try:
        try:
            resp = client.chat.completions.create(
                model=m,
                messages=[
                    {"role": "system",
                     "content": "Return ONLY valid JSON following the schema."},
                    {"role": "user", "content": f"Schema: {schema}\n\nTask: {prompt}"}
                ],
                response_format={"type": "json_object"},
                max_completion_tokens=max_tokens
            )
            content = resp.choices[0].message.content
            if isinstance(content, (dict, list)):
                return content
            return json.loads(content)
        except Exception:
            logger.warning(f"OpenAI JSON model failed: {m}")
            continue

    return {}


# ============================================================
#  FETCH GENERAL RESOURCES (Optional)
# ============================================================

def fetch_youtube_links(query: str, max_results: int = 3) -> List[str]:
    try:
        from ddgs import DDGS
        vids = []
        with DDGS() as ddgs:
            for v in ddgs.videos(query, max_results=max_results):
                link = v.get("content") or v.get("url")
                if link:
                    vids.append(link)
        return vids
    except:
        return []


def fetch_text_links(query: str, max_results: int = 8) -> List[str]:
    try:
        from ddgs import DDGS
        links = []
        with DDGS() as ddgs:
            for r in ddgs.text(query, max_results=max_results):
                link = r.get("href") or r.get("url")
                if link:
                    links.append(link)
        return links
    except:
        return []


# ============================================================
#  API RESPONSE MODELS
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


# ============================================================
#  ROOT ROUTE
# ============================================================

@app.get("/")
def root():
    return {"message": "Backend running", "status": "ok"}
# ============================================================
#  SECTION 2 OF 4
#  Student CRUD + Personalized AI Roadmap Generator (PostgreSQL)
# ============================================================


# ------------------------------------------------------------
#  ADD STUDENT (students table only)
#  This DOES NOT touch student_profiles.
#  Your face recognition app uses student_name separately.
# ------------------------------------------------------------
@app.post("/add_student")
def add_student(name: str = Form(...), dept: str = Form(...)):
    query_db("""
        INSERT INTO students (name, dept)
        VALUES (%s, %s)
    """, (name, dept))

    student = query_db("""
        SELECT id, name, dept
        FROM students
        ORDER BY id DESC LIMIT 1
    """, fetchone=True)

    return {
        "message": "Student added",
        "student": {
            "id": student["id"],
            "name": student["name"],
            "dept": student["dept"]
        }
    }


# ------------------------------------------------------------
#  LIST ALL STUDENTS
# ------------------------------------------------------------
@app.get("/list_students")
def list_students():
    rows = query_db("""
        SELECT id, name, dept, points, progress
        FROM students
    """, fetchall=True)
    return rows


# ------------------------------------------------------------
#  RESET A STUDENT'S PROGRESS
# ------------------------------------------------------------
@app.post("/reset_student")
def reset_student(student_id: int = Form(...)):
    query_db("DELETE FROM roadmap WHERE student_id=%s", (student_id,))
    query_db("DELETE FROM mini_sessions WHERE student_id=%s", (student_id,))
    query_db("DELETE FROM sessions WHERE student_id=%s", (student_id,))
    query_db("DELETE FROM quiz_results WHERE student_id=%s", (student_id,))
    query_db("UPDATE students SET points=0, progress=0 WHERE id=%s", (student_id,))

    return {"message": "Student reset complete"}


# ============================================================
#  PERSONALIZED AI ROADMAP GENERATOR (MOST IMPORTANT)
# ============================================================

@app.post("/generate_roadmap", response_model=RoadmapOut)
def generate_roadmap(student_id: int = Form(...), topic: str = Form(...)):
    # ------------------------------------------------------------
    # 1. Fetch student profile from student_profiles (PostgreSQL)
    # ------------------------------------------------------------
    profile = query_db("""
        SELECT strength, weakness, interest
        FROM student_profiles
        WHERE id = %s
    """, (student_id,), fetchone=True)

    strength = profile["strength"] if profile else ""
    weakness = profile["weakness"] if profile else ""
    interest = profile["interest"] if profile else ""

    # ------------------------------------------------------------
    # 2. AI Prompt with PERSONALIZATION
    # ------------------------------------------------------------
    prompt = f"""
    Create a personalized learning roadmap for the topic '{topic}'.

    The student's learning profile:
    • Strengths: {strength}
    • Weaknesses: {weakness}
    • Interests: {interest}

    Requirements:
    - Break the topic into organized subtopics.
    - Make the roadmap easier at the start, and progressively more advanced.
    - Give EXTRA focus to topics that align with WEAKNESSES.
    - Use STRENGTHS to accelerate the learning path.
    - Include INTEREST-based subtopics to improve motivation.
    - Keep descriptions short and clear.

    Output ONLY valid JSON.
    """

    schema = '{"roadmap":[{"subtopic":str,"description":str}]}'

    roadmap_data = openai_json(prompt, schema, model=MODEL_PLANNER).get("roadmap", [])
    if not roadmap_data:
        roadmap_data = [{"subtopic": f"{topic} Basics", "description": "Introduction to fundamentals."}]

    # ------------------------------------------------------------
    # 3. Insert Personalized Roadmap Into PostgreSQL
    # ------------------------------------------------------------
    conn = db_conn()
    cur = conn.cursor()

    cur.execute("SELECT MAX(position) FROM roadmap WHERE student_id=%s", (student_id,))
    mx = cur.fetchone()
    start_pos = (mx[0] + 1) if mx and mx[0] is not None else 1

    for offset, item in enumerate(roadmap_data):
        pos = start_pos + offset
        cur.execute("""
            INSERT INTO roadmap (student_id, topic, subtopic, resources, position, status, parent_id)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
            RETURNING id
        """, (
            student_id,
            topic,
            item["subtopic"],
            json.dumps([]),
            pos,
            "pending",
            None
        ))

    conn.commit()
    cur.close()
    conn.close()

    return {
        "student_id": student_id,
        "topic": topic,
        "roadmap": roadmap_data
    }


# ============================================================
#  ROADMAP VIEW (POSTGRESQL)
# ============================================================

@app.get("/roadmap_list")
def roadmap_list(student_id: int = Query(...)):
    rows = query_db("""
        SELECT id, topic, subtopic, resources, position, status, parent_id
        FROM roadmap
        WHERE student_id=%s
        ORDER BY position ASC
    """, (student_id,), fetchall=True)

    for r in rows:
        try:
            r["resources"] = json.loads(r["resources"]) if r["resources"] else []
        except:
            r["resources"] = []

    return {
        "student_id": student_id,
        "roadmap": rows
    }
# ============================================================
#  SECTION 3 OF 4
#  Mini-session Engine + Adaptive Splitting (PostgreSQL Version)
# ============================================================


# ------------------------------------------------------------
#  LIST MINI-SESSIONS
# ------------------------------------------------------------
@app.get("/mini_sessions_list")
def mini_sessions_list(student_id: int = Query(...), roadmap_id: Optional[int] = Query(None)):
    if roadmap_id:
        rows = query_db("""
            SELECT *
            FROM mini_sessions
            WHERE student_id=%s AND roadmap_id=%s
            ORDER BY id ASC
        """, (student_id, roadmap_id), fetchall=True)
    else:
        rows = query_db("""
            SELECT *
            FROM mini_sessions
            WHERE student_id=%s
            ORDER BY id ASC
        """, (student_id,), fetchall=True)

    for r in rows:
        try:
            r["resources"] = json.loads(r["resources"]) if r["resources"] else []
        except:
            r["resources"] = []

        try:
            r["videos"] = json.loads(r["videos"]) if r["videos"] else []
        except:
            r["videos"] = []

    return {"student_id": student_id, "mini_sessions": rows}


# ------------------------------------------------------------
#  GET MINI-SESSION DETAIL (content + quiz)
# ------------------------------------------------------------
@app.get("/mini_session_detail")
def mini_session_detail(session_id: int = Query(...)):
    row = query_db("""
        SELECT content_json, quiz_json, student_id, mini_session_id
        FROM sessions
        WHERE id=%s
    """, (session_id,), fetchone=True)

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
#  NEXT MINI SESSION (CORE ENGINE)
# ============================================================

@app.get("/next_mini_session", response_model=MiniSessionOut)
def next_mini_session(student_id: int):
    # ------------------------------------------------------------
    # 1) PRIORITIZE CHILD MINI-SESSIONS (when parent was split)
    # ------------------------------------------------------------
    child_pending = query_db("""
        SELECT m.*
        FROM mini_sessions m
        JOIN roadmap r ON m.roadmap_id = r.id
        WHERE m.student_id=%s AND m.status='pending' AND r.parent_id IS NOT NULL
        ORDER BY r.position ASC, m.id ASC
        LIMIT 1
    """, (student_id,), fetchone=True)

    if child_pending:
        return process_pending_session(student_id, child_pending)

    # ------------------------------------------------------------
    # 2) THEN TOP-LEVEL MINI-SESSIONS (parent_id IS NULL)
    # ------------------------------------------------------------
    top_pending = query_db("""
        SELECT m.*
        FROM mini_sessions m
        JOIN roadmap r ON m.roadmap_id = r.id
        WHERE m.student_id=%s AND m.status='pending' AND r.parent_id IS NULL
        ORDER BY r.position ASC, m.id ASC
        LIMIT 1
    """, (student_id,), fetchone=True)

    if top_pending:
        return process_pending_session(student_id, top_pending)

    # ------------------------------------------------------------
    # 3) NO MINI-SESSIONS → CREATE FIRST ONE FOR NEXT ROADMAP ITEM
    # ------------------------------------------------------------
    next_roadmap = query_db("""
        SELECT id, subtopic
        FROM roadmap
        WHERE student_id=%s AND status='pending' AND parent_id IS NULL
        ORDER BY position ASC
        LIMIT 1
    """, (student_id,), fetchone=True)

    if not next_roadmap:
        return {
            "mini_session_id": 0,
            "parent_subtopic": "",
            "mini_subtopic": "",
            "content": "",
            "resources": [],
            "videos": [],
            "quiz": [],
            "message": "🎉 All roadmap sessions completed!"
        }

    # Create a new mini-session → then call next_mini_session() again
    conn = db_conn()
    cur = conn.cursor()

    mini_title = next_roadmap["subtopic"] + " - Part 1"

    cur.execute("""
        INSERT INTO mini_sessions (roadmap_id, student_id, mini_title, description,
                                   estimated_minutes, resources, videos, status)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        RETURNING id
    """, (
        next_roadmap["id"], student_id, mini_title, "",
        50, json.dumps([]), json.dumps([]), "pending"
    ))

    new_id = cur.fetchone()["id"]
    conn.commit()
    cur.close()
    conn.close()

    return next_mini_session(student_id)


# ------------------------------------------------------------
#  PROCESS A PENDING MINI SESSION (CHILD OR TOP-LEVEL)
# ------------------------------------------------------------

def process_pending_session(student_id: int, pending_ms: dict):
    """Handles existing or new mini sessions with PostgreSQL storage."""

    # ------------------------------------------------------------
    # CASE A: Session already exists → return it
    # ------------------------------------------------------------
    if pending_ms.get("session_id"):
        sess = query_db("""
            SELECT content_json, quiz_json
            FROM sessions WHERE id=%s
        """, (pending_ms["session_id"],), fetchone=True)

        content = json.loads(sess["content_json"])["content"] if sess and sess["content_json"] else ""
        quiz = json.loads(sess["quiz_json"]) if sess and sess["quiz_json"] else []

        resources = json.loads(pending_ms["resources"]) if pending_ms["resources"] else []
        videos = json.loads(pending_ms["videos"]) if pending_ms["videos"] else []

        parent = query_db("""
            SELECT subtopic FROM roadmap WHERE id=%s
        """, (pending_ms["roadmap_id"],), fetchone=True)

        return MiniSessionOut(
            mini_session_id=pending_ms["id"],
            parent_subtopic=parent["subtopic"] if parent else "",
            mini_subtopic=pending_ms["mini_title"],
            content=content,
            resources=resources,
            videos=videos,
            quiz=quiz
        )

    # ------------------------------------------------------------
    # CASE B: No session exists → generate new AI content
    # ------------------------------------------------------------
    mini_id = pending_ms["id"]
    mini_title = pending_ms["mini_title"]

    # Fetch helpful links
    resources = fetch_text_links(mini_title, max_results=8)
    videos = fetch_youtube_links(mini_title, max_results=3)

    # AI Content Generation
    content = openai_text(
        f"Write an 800-1200 word study guide for '{mini_title}'. "
        f"Include: Introduction, Key Concepts, Worked Examples, Exercises.",
        model=MODEL_STUDY, max_tokens=2000
    )

    # AI Quiz Generation
    quiz_prompt = f"""
    Using this content:

    {content}

    Generate EXACTLY 10 multiple-choice questions:
    - 5 Easy
    - 3 Moderate
    - 2 Hard

    Include: difficulty, type='mcq', question, 4 options,
    correct_answer, rationale.
    Return ONLY valid JSON.
    """

    schema_quiz = '{"questions":[{"difficulty":str,"type":str,"question":str,"options":[str],"correct_answer":str,"rationale":str}]}'

    quiz = openai_json(quiz_prompt, schema_quiz, model=MODEL_QUIZ).get("questions", [])
    if not quiz:
        quiz = [{
            "difficulty": "Easy",
            "type": "mcq",
            "question": "Fallback question",
            "options": ["A", "B", "C", "D"],
            "correct_answer": "A",
            "rationale": "Fallback"
        }]

    # Save to PostgreSQL
    conn = db_conn()
    cur = conn.cursor()

    cur.execute("""
        INSERT INTO sessions (student_id, mini_session_id, content_json, quiz_json)
        VALUES (%s, %s, %s, %s)
        RETURNING id
    """, (
        student_id, mini_id,
        json.dumps({"content": content}),
        json.dumps(quiz)
    ))

    session_id = cur.fetchone()["id"]

    cur.execute("""
        UPDATE mini_sessions
        SET session_id=%s, resources=%s, videos=%s
        WHERE id=%s
    """, (
        session_id,
        json.dumps(resources),
        json.dumps(videos),
        mini_id
    ))

    conn.commit()
    cur.close()
    conn.close()

    parent = query_db("""
        SELECT subtopic FROM roadmap WHERE id=%s
    """, (pending_ms["roadmap_id"],), fetchone=True)

    return MiniSessionOut(
        mini_session_id=mini_id,
        parent_subtopic=parent["subtopic"] if parent else "",
        mini_subtopic=mini_title,
        content=content,
        resources=resources,
        videos=videos,
        quiz=quiz
    )
# ============================================================
#  SECTION 4 OF 4
#  Quiz Completion • Adaptive Splitting • Progress • Chatbot
# ============================================================


# ------------------------------------------------------------
#  COMPLETE MINI SESSION — GRADE QUIZ + SPLITTING LOGIC
# ------------------------------------------------------------
@app.post("/complete_mini_session")
def complete_mini_session(
    student_id: int = Form(...),
    mini_session_id: int = Form(...),
    quiz_answers: str = Form(...)
):
    # --------------------------------------------
    # Parse quiz answers
    # --------------------------------------------
    try:
        payload = json.loads(quiz_answers)
    except:
        raise HTTPException(status_code=400, detail="Invalid quiz_answers JSON")

    # Fetch stored quiz
    session_row = query_db("""
        SELECT id, quiz_json
        FROM sessions
        WHERE mini_session_id=%s
    """, (mini_session_id,), fetchone=True)

    if not session_row:
        raise HTTPException(status_code=404, detail="No quiz found for this session")

    session_id = session_row["id"]
    quiz_list = json.loads(session_row["quiz_json"]) if session_row["quiz_json"] else []

    # Map answers by index
    answers = payload.get("answers", {})

    total = len(quiz_list)
    correct = 0
    results_detail = []

    # --------------------------------------------
    # Evaluate quiz
    # --------------------------------------------
    for i, q in enumerate(quiz_list):
        submitted = answers.get(str(i), None)
        correct_answer = q.get("correct_answer")

        def norm(x): return (x or "").strip().lower()
        is_correct = norm(submitted) == norm(correct_answer)

        if is_correct:
            correct += 1

        # Save quiz result
        query_db("""
            INSERT INTO quiz_results (student_id, session_id, question, answer, score, difficulty)
            VALUES (%s, %s, %s, %s, %s, %s)
        """, (
            student_id, session_id,
            q.get("question"),
            submitted,
            1 if is_correct else 0,
            q.get("difficulty", "")
        ))

        results_detail.append({
            "index": i,
            "question": q.get("question"),
            "your_answer": submitted,
            "correct_answer": correct_answer,
            "is_correct": is_correct,
            "difficulty": q.get("difficulty")
        })

    score_pct = int((correct / total) * 100) if total else 0

    # ============================================================
    #  FAIL CASE — SPLIT TOPIC INTO PARTS
    # ============================================================
    if score_pct < 60:
        roadmap_row = query_db("""
            SELECT r.id, r.subtopic, r.topic, r.position, r.student_id
            FROM roadmap r
            JOIN mini_sessions m ON r.id = m.roadmap_id
            WHERE m.id=%s
        """, (mini_session_id,), fetchone=True)

        if not roadmap_row:
            return {
                "message": "❌ Quiz failed, but parent topic not found.",
                "score_pct": score_pct,
                "results": results_detail
            }

        parent_id = roadmap_row["id"]
        parent_subtopic = roadmap_row["subtopic"]
        parent_topic = roadmap_row["topic"]
        parent_position = roadmap_row["position"]
        target_student = roadmap_row["student_id"]

        # Mark parent as split
        query_db("UPDATE roadmap SET status='split' WHERE id=%s", (parent_id,))

        # AI request to create split parts
        split_prompt = f"""
        The student failed on: {parent_subtopic}

        Split this topic into 2–4 simplified parts.
        Include short descriptions.
        JSON only.
        """

        schema = '{"sessions":[{"mini_subtopic":str,"description":str}]}'

        new_parts = openai_json(split_prompt, schema, model=DEFAULT_MODEL).get("sessions", [])
        if not new_parts:
            new_parts = [
                {"mini_subtopic": parent_subtopic + " - Part A", "description": "First half"},
                {"mini_subtopic": parent_subtopic + " - Part B", "description": "Second half"}
            ]

        num_new = len(new_parts)

        conn = db_conn()
        cur = conn.cursor()

        # Shift positions (very important)
        cur.execute("""
            UPDATE roadmap
            SET position = position + %s
            WHERE student_id=%s AND position > %s
        """, (num_new, target_student, parent_position))

        conn.commit()

        new_ids = []
        new_sessions = []

        # Generate child roadmap + mini-sessions
        for offset, part in enumerate(new_parts, start=1):
            new_pos = parent_position + offset

            # Insert roadmap child
            cur.execute("""
                INSERT INTO roadmap (student_id, topic, subtopic, resources, position, status, parent_id)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
                RETURNING id
            """, (
                target_student,
                parent_topic,
                part["mini_subtopic"],
                json.dumps([]),
                new_pos,
                "pending",
                parent_id
            ))

            new_rid = cur.fetchone()["id"]
            new_ids.append(new_rid)

            # Insert mini-session
            cur.execute("""
                INSERT INTO mini_sessions (roadmap_id, student_id, mini_title, description,
                                           estimated_minutes, resources, videos, status)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                RETURNING id
            """, (
                new_rid,
                target_student,
                part["mini_subtopic"],
                part.get("description", ""),
                50,
                json.dumps([]),
                json.dumps([]),
                "pending"
            ))

            new_ms_id = cur.fetchone()["id"]

            # AI Generate content
            content = openai_text(
                f"Write a simplified 600-800 word guide for: {part['mini_subtopic']}.",
                model=MODEL_STUDY
            )

            quiz_prompt = f"""
            Use this content:
            {content}

            Generate 5 MCQs:
            3 Easy, 2 Moderate.
            Must include difficulty, question, options, correct_answer, rationale.
            JSON only.
            """

            schema_q = '{"questions":[{"difficulty":str,"type":str,"question":str,"options":[str],"correct_answer":str,"rationale":str}]}'
            quiz = openai_json(quiz_prompt, schema_q, model=MODEL_QUIZ).get("questions", [])

            if not quiz:
                quiz = [{
                    "difficulty": "Easy",
                    "type": "mcq",
                    "question": "Fallback question",
                    "options": ["A", "B", "C", "D"],
                    "correct_answer": "A",
                    "rationale": "Fallback"
                }]

            # Insert new session
            cur.execute("""
                INSERT INTO sessions (student_id, mini_session_id, content_json, quiz_json)
                VALUES (%s, %s, %s, %s)
                RETURNING id
            """, (
                target_student,
                new_ms_id,
                json.dumps({"content": content}),
                json.dumps(quiz)
            ))

            sess_id = cur.fetchone()["id"]

            cur.execute("""
                UPDATE mini_sessions
                SET session_id=%s
                WHERE id=%s
            """, (sess_id, new_ms_id))

            new_sessions.append({
                "mini_session_id": new_ms_id,
                "mini_subtopic": part["mini_subtopic"],
                "content": content,
                "quiz": quiz
            })

        conn.commit()
        cur.close()
        conn.close()

        updated_map = query_db("""
            SELECT *
            FROM roadmap
            WHERE student_id=%s
            ORDER BY position ASC
        """, (target_student,), fetchall=True)

        return {
            "message": f"❌ Failed ({score_pct}%). Topic split into {num_new} parts.",
            "score_pct": score_pct,
            "results": results_detail,
            "new_roadmap_ids": new_ids,
            "new_sessions": new_sessions,
            "updated_roadmap": updated_map
        }

    # ============================================================
    #  PASS CASE
    # ============================================================
    query_db("""
        UPDATE mini_sessions
        SET status='done'
        WHERE id=%s AND student_id=%s
    """, (mini_session_id, student_id))

    # Mark roadmap entry done
    r = query_db("""
        SELECT roadmap_id
        FROM mini_sessions
        WHERE id=%s
    """, (mini_session_id,), fetchone=True)

    if r:
        rid = r["roadmap_id"]

        # Mark DONE
        query_db("UPDATE roadmap SET status='done' WHERE id=%s", (rid,))

        # If it's a child, check siblings
        parent = query_db("""
            SELECT parent_id
            FROM roadmap
            WHERE id=%s
        """, (rid,), fetchone=True)

        if parent and parent["parent_id"]:
            parent_id = parent["parent_id"]

            # Check if siblings are unfinished
            siblings = query_db("""
                SELECT COUNT(*) as cnt
                FROM roadmap
                WHERE parent_id=%s AND status!='done'
            """, (parent_id,), fetchone=True)

            if siblings["cnt"] == 0:
                query_db("UPDATE roadmap SET status='done' WHERE id=%s", (parent_id,))

    return {
        "message": f"✅ Passed ({score_pct}%). Session completed.",
        "score_pct": score_pct,
        "results": results_detail
    }


# ------------------------------------------------------------
#  OPEN MINI SESSION (REGENERATE IF LOST)
# ------------------------------------------------------------
@app.get("/open_mini_session")
def open_mini_session(mini_session_id: int = Query(...)):
    ms = query_db("""
        SELECT *
        FROM mini_sessions
        WHERE id=%s
    """, (mini_session_id,), fetchone=True)

    if not ms:
        raise HTTPException(status_code=404, detail="Mini-session not found")

    # If missing → generate content
    if not ms.get("session_id"):
        mini_title = ms["mini_title"]
        resources = fetch_text_links(mini_title)
        videos = fetch_youtube_links(mini_title)

        content = openai_text(
            f"Write a full 800-1200 word study guide for '{mini_title}'.",
            model=MODEL_STUDY
        )

        quiz_prompt = f"""
        Use this content:
        {content}

        Generate 8 MCQs with explanation.
        JSON only.
        """

        schema = '{"questions":[{"difficulty":str,"type":str,"question":str,"options":[str],"correct_answer":str,"rationale":str}]}'
        quiz = openai_json(quiz_prompt, schema, model=MODEL_QUIZ).get("questions", [])

        # Save
        conn = db_conn()
        cur = conn.cursor()

        cur.execute("""
            INSERT INTO sessions (student_id, mini_session_id, content_json, quiz_json)
            VALUES (%s, %s, %s, %s)
            RETURNING id
        """, (
            ms["student_id"],
            mini_session_id,
            json.dumps({"content": content}),
            json.dumps(quiz)
        ))

        sess_id = cur.fetchone()["id"]

        cur.execute("""
            UPDATE mini_sessions
            SET session_id=%s, resources=%s, videos=%s
            WHERE id=%s
        """, (
            sess_id,
            json.dumps(resources),
            json.dumps(videos),
            mini_session_id
        ))

        conn.commit()
        cur.close()
        conn.close()

        return {
            "mini_session_id": mini_session_id,
            "content": content,
            "quiz": quiz
        }

    # Otherwise return stored content
    sess = query_db("""
        SELECT content_json, quiz_json
        FROM sessions
        WHERE id=%s
    """, (ms["session_id"],), fetchone=True)

    return {
        "mini_session_id": mini_session_id,
        "content": json.loads(sess["content_json"])["content"],
        "quiz": json.loads(sess["quiz_json"])
    }


# ------------------------------------------------------------
#  ROADMAP PROGRESS
# ------------------------------------------------------------
@app.get("/progress_roadmap", response_model=ProgressOut)
def progress_roadmap(student_id: int = Query(...)):
    total = query_db("""
        SELECT COUNT(*) as cnt
        FROM mini_sessions
        WHERE student_id=%s
    """, (student_id,), fetchone=True)["cnt"]

    done = query_db("""
        SELECT COUNT(*) as cnt
        FROM mini_sessions
        WHERE student_id=%s AND status='done'
    """, (student_id,), fetchone=True)["cnt"]

    pct = int((done / total) * 100) if total > 0 else 0

    return {
        "student_id": student_id,
        "completed": done,
        "total": total,
        "progress": f"{pct}%"
    }


# ------------------------------------------------------------
#  CHATBOT ENDPOINT
# ------------------------------------------------------------
@app.post("/chatbot")
def chatbot(message: str = Form(...)):
    try:
        resp = client.chat.completions.create(
            model=DEFAULT_MODEL,
            messages=[
                {"role": "system",
                 "content": "You are a helpful assistant. Provide clear answers and working code."},
                {"role": "user", "content": message}
            ],
            max_completion_tokens=600
        )

        reply = resp.choices[0].message.content or ""
        return {"reply": reply}
    except Exception as e:
        return {"reply": f"⚠️ Error: {str(e)}"}


# ------------------------------------------------------------
#  HEALTH CHECK
# ------------------------------------------------------------
@app.get("/health")
def health():
    return {"status": "ok", "db": "postgresql_connected"}
