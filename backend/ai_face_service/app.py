from flask import Flask, request, jsonify
import cv2
import json
import numpy as np
import psycopg2
import psycopg2.extras
from insightface.app import FaceAnalysis

app = Flask(__name__)

# ============================================================
# DATABASE CONFIG
# ============================================================
DB = {
    "dbname": "Smart_curriculum",
    "user": "postgres",
    "password": "Dhana@2007",
    "host": "localhost",
    "port": 5433,
}

def db():
    return psycopg2.connect(**DB)

# ============================================================
# LOAD INSIGHTFACE (ArcFace)
# ============================================================
print("⚙️ Loading ArcFace model...")
app_face = FaceAnalysis(name="buffalo_l")
app_face.prepare(ctx_id=-1, det_size=(640, 640))
print("✅ ArcFace model ready.")

# ============================================================
# HELPERS
# ============================================================
def cosine(a, b):
    """Compute cosine similarity between two embeddings."""
    return float(np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b) + 1e-12))

def read_upload(fs):
    """Read uploaded file as OpenCV image."""
    npimg = np.frombuffer(fs.read(), np.uint8)
    return cv2.imdecode(npimg, cv2.IMREAD_COLOR)

def detect_and_crop_face(img):
    """Detect face and return both cropped image and embedding directly."""
    rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    faces = app_face.get(rgb)
    if not faces:
        print("⚠️ No faces detected in image.")
        return None, None

    face = faces[0]
    x1, y1, x2, y2 = face.bbox.astype(int)
    pad = int(0.1 * (x2 - x1))
    x1, y1 = max(0, x1 - pad), max(0, y1 - pad)
    x2, y2 = min(img.shape[1], x2 + pad), min(img.shape[0], y2 + pad)
    crop = img[y1:y2, x1:x2]
    print(f"🖼️ Cropped region: {crop.shape}")

    emb = face.embedding.astype(np.float32)
    emb /= np.linalg.norm(emb) + 1e-12
    print("✅ Embedding extracted from initial detection.")
    return crop, emb

# ============================================================
# NEW — CHECK IF FACE EMBEDDING EXISTS
# ============================================================
@app.get("/face/exists")
def face_exists():
    name = request.args.get("name")
    if not name:
        return jsonify({"ok": False, "exists": False, "error": "Missing ?name"}), 400

    conn = db()
    cur = conn.cursor()
    cur.execute("SELECT 1 FROM student_faces WHERE student_name = %s", (name,))
    found = cur.fetchone()
    cur.close()
    conn.close()

    return jsonify({"ok": True, "exists": found is not None})


# ============================================================
# ROUTES
# ============================================================

@app.post("/face/register-mobile")
def register_mobile():
    f = request.files.get("file")
    name = request.form.get("name")

    if not f or not name:
        return jsonify({"ok": False, "error": "Missing file or name"}), 400

    img = read_upload(f)
    crop, emb = detect_and_crop_face(img)
    if emb is None:
        return jsonify({"ok": False, "error": "No face detected"}), 400

    conn = db()
    cur = conn.cursor()
    cur.execute(
        """
        INSERT INTO student_faces (student_name, embedding)
        VALUES (%s, %s)
        ON CONFLICT (student_name)
        DO UPDATE SET embedding = EXCLUDED.embedding;
    """,
        (name, json.dumps(emb.tolist())),
    )
    conn.commit()
    cur.close()
    conn.close()

    print(f"🆕 Registered face for {name}")
    return jsonify({"ok": True, "msg": f"Face registered for {name}."})


@app.post("/face/recognize")
def recognize_face():
    target_name = request.args.get("name")

    f = request.files.get("file")
    if not f:
        return jsonify({"ok": False, "error": "Missing file"}), 400

    img = read_upload(f)
    crop, emb = detect_and_crop_face(img)
    if emb is None:
        return jsonify({"ok": True, "recognized": False, "name": None, "score": 0.0})

    conn = db()
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

    # --------------------------------------------------------
    # MODE 1: Targeted recognition (Flutter app)
    # --------------------------------------------------------
    if target_name:
        print(f"🎯 Targeted recognition for: {target_name}")
        cur.execute(
            "SELECT student_name, embedding FROM student_faces WHERE student_name = %s",
            (target_name,),
        )
        row = cur.fetchone()
        cur.close()
        conn.close()

        if not row:
            return jsonify({
                "ok": True,
                "recognized": False,
                "name": None,
                "score": 0.0
            })

        emb_data = row["embedding"]
        if isinstance(emb_data, str):
            dbv = np.array(json.loads(emb_data), dtype=np.float32)
        else:
            dbv = np.array(emb_data, dtype=np.float32)

        score = cosine(emb, dbv)
        recognized = score >= 0.35

        return jsonify({
            "ok": True,
            "recognized": recognized,
            "name": target_name if recognized else None,
            "score": float(score)
        })

    # --------------------------------------------------------
    # MODE 2: Legacy recognition (other websites)
    # --------------------------------------------------------
    cur.execute("SELECT student_name, embedding FROM student_faces")
    rows = cur.fetchall()
    cur.close()
    conn.close()

    if not rows:
        return jsonify({"ok": False, "error": "No registered faces."}), 404

    best_name, best_score = None, -1.0
    for row in rows:
        emb_data = row["embedding"]
        if isinstance(emb_data, str):
            dbv = np.array(json.loads(emb_data), dtype=np.float32)
        else:
            dbv = np.array(emb_data, dtype=np.float32)

        s = cosine(emb, dbv)
        if s > best_score:
            best_name, best_score = row["student_name"], s

    recognized = best_score >= 0.35

    return jsonify({
        "ok": True,
        "recognized": recognized,
        "name": best_name if recognized else None,
        "score": float(best_score)
    })


@app.get("/health")
def health():
    return jsonify({"ok": True})


# ============================================================
# MAIN
# ============================================================
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
