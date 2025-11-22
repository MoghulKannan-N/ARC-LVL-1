# app.py
from flask import Flask, request, jsonify, Response
import cv2
import os
import numpy as np
import onnxruntime as ort
import psycopg2
import psycopg2.extras
import json
import random
import mediapipe as mp
from insightface.app import FaceAnalysis

app = Flask(__name__)
ROOT = os.path.dirname(os.path.abspath(__file__))

# ============================================================
# DB CONFIG
# ============================================================
DB = {
    "dbname": "Smart_curriculum",
    "user": "postgres",
    "password": "Dhana@2007",
    "host": "localhost",
    "port": 5433
}

def db():
    return psycopg2.connect(**DB)

# ============================================================
# LOAD ARCFACE / INSIGHTFACE
# ============================================================
MODEL_DIR = os.path.join(ROOT, "models", "buffalo_l")
MODEL_PATH = None
for f in ["w600k_r50.onnx", "glintr100.onnx", "arcface_r100_v1.onnx"]:
    p = os.path.join(MODEL_DIR, f)
    if os.path.exists(p):
        MODEL_PATH = p
        break
if MODEL_PATH is None:
    raise Exception("❌ ArcFace model not found")

# onnx session for classic path
sess = ort.InferenceSession(MODEL_PATH, providers=["CPUExecutionProvider"])

# InsightFace high-level API (detector + embedding)
app_face = FaceAnalysis(name="buffalo_l")
app_face.prepare(ctx_id=-1, det_size=(640, 640))

def preprocess(face):
    img = cv2.resize(face, (112, 112))
    img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB).astype(np.float32)
    img = (img - 127.5) / 128.0
    img = np.transpose(img, (2, 0, 1))
    return np.expand_dims(img, 0)

def get_embedding(face):
    x = preprocess(face)
    y = sess.run(None, {sess.get_inputs()[0].name: x})[0][0]
    y = y / (np.linalg.norm(y) + 1e-12)
    return y.astype(np.float32)

def get_embedding_insight(img_bgr):
    faces = app_face.get(img_bgr)
    if not faces:
        return None
    emb = faces[0].embedding.astype(np.float32)
    emb /= (np.linalg.norm(emb) + 1e-12)
    return emb

def cosine(a, b):
    return float(np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b) + 1e-12))

# ============================================================
# FACE DETECTION (OpenCV Haar as fallback)
# ============================================================
cascade = cv2.CascadeClassifier(cv2.data.haarcascades + "haarcascade_frontalface_default.xml")

def detect_face(frame):
    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
    faces = cascade.detectMultiScale(gray, 1.2, 5, minSize=(80, 80))
    if len(faces) == 0:
        return None
    x, y, w, h = sorted(faces, key=lambda f: f[2] * f[3], reverse=True)[0]
    pad = int(0.15 * w)
    return (max(0, x - pad), max(0, y - pad), min(frame.shape[1], x + w + pad), min(frame.shape[0], y + h + pad))

def detect_and_crop_face(img):
    faces = app_face.get(img)
    if faces:
        x1, y1, x2, y2 = faces[0].bbox.astype(int)
        x1, y1 = max(0, x1), max(0, y1)
        x2, y2 = min(img.shape[1], x2), min(img.shape[0], y2)
        if x2 > x1 and y2 > y1:
            return img[y1:y2, x1:x2]
    # fallback: haar
    box = detect_face(img)
    if box:
        x0, y0, x1, y1 = box
        return img[y0:y1, x0:x1]
    return img

# ============================================================
# UTILS: Read image from upload
# ============================================================
def read_image_from_upload(fs):
    # fs is Werkzeug FileStorage
    data = fs.read()
    npimg = np.frombuffer(data, np.uint8)
    img = cv2.imdecode(npimg, cv2.IMREAD_COLOR)
    return img

# ============================================================
# MEDIAPIPE (Liveness)
# ============================================================
mp_face_mesh = mp.solutions.face_mesh
mp_hands = mp.solutions.hands

ACTIONS = ["turn_head_left", "turn_head_right", "move_eyes_left", "move_eyes_right", "hand_raise"]
HEAD_YAW_THRESHOLD = 0.06
EYE_MOVE_THRESHOLD = 0.03

def mesh_from_image(img):
    h, w = img.shape[:2]
    with mp_face_mesh.FaceMesh(static_image_mode=True, max_num_faces=1, refine_landmarks=True,
                               min_detection_confidence=0.6) as fm:
        rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
        res = fm.process(rgb)
        if not res.multi_face_landmarks:
            return None
        landmarks = res.multi_face_landmarks[0].landmark
        pts = np.array([[p.x * w, p.y * h, p.z * w] for p in landmarks], dtype=np.float32)
        return pts

def estimate_yaw_from_mesh(pts):
    left_eye = np.mean(pts[[33, 133], :2], axis=0)
    right_eye = np.mean(pts[[362, 263], :2], axis=0)
    nose = pts[1, :2]
    eyes_center_x = (left_eye[0] + right_eye[0]) / 2.0
    face_width = np.linalg.norm(right_eye - left_eye) + 1e-6
    return (nose[0] - eyes_center_x) / face_width

def iris_ratio_from_mesh(pts, which="left"):
    try:
        if which == "left":
            eye_idxs = [362,382,381,380,374,373,390,249,263,466,388,387,386,385,384,398]
            iris_idxs = [474,475,476,477]
        else:
            eye_idxs = [33,7,163,144,145,153,154,155,133,173,157,158,159,160,161,246]
            iris_idxs = [469,470,471,472]
        eye_box = pts[eye_idxs][:, :2]
        iris = np.mean(pts[iris_idxs][:, :2], axis=0)
        x_min, x_max = eye_box[:, 0].min(), eye_box[:, 0].max()
        ratio = (iris[0] - x_min) / (x_max - x_min + 1e-6)
        return float(np.clip(ratio, 0.0, 1.0))
    except Exception:
        return 0.5

def hand_present(img):
    with mp_hands.Hands(static_image_mode=True, max_num_hands=1, min_detection_confidence=0.6) as hd:
        rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
        res = hd.process(rgb)
        return res.multi_hand_landmarks is not None

# ============================================================
# CLASSIC ENDPOINTS (unchanged, keep for compatibility)
# These still use the laptop webcam if you ever call them.
# ============================================================
@app.post("/face/capture-frame")
def capture_frame():
    cap = cv2.VideoCapture(0, cv2.CAP_DSHOW)
    ok, frame = cap.read()
    cap.release()
    if not ok:
        return jsonify({"ok": False, "error": "camera_failed"})
    frame = cv2.flip(frame, 1)
    cv2.imwrite(os.path.join(ROOT, "temp_frame.jpg"), frame)
    return jsonify({"ok": True})

@app.post("/face/register-frame")
def register_frame():
    data = request.get_json()
    name = data.get("name")
    if not name:
        return jsonify({"ok": False, "error": "name missing"})

    img_path = os.path.join(ROOT, "temp_frame.jpg")
    if not os.path.exists(img_path):
        return jsonify({"ok": False, "error": "capture first"})

    frame = cv2.imread(img_path)
    crop = detect_and_crop_face(frame)
    emb = get_embedding_insight(crop)
    if emb is None:
        return jsonify({"ok": False, "error": "no face"})

    try:
        conn = db()
        cur = conn.cursor()
        cur.execute("""
            INSERT INTO student_faces (student_name, embedding)
            VALUES (%s, %s)
            ON CONFLICT (student_name)
            DO UPDATE SET embedding = EXCLUDED.embedding;
        """, (name, json.dumps(emb.tolist())))
        conn.commit()
        cur.close()
        conn.close()
        return jsonify({"ok": True, "msg": "saved"})
    except Exception as e:
        return jsonify({"ok": False, "error": str(e)})

@app.post("/face/recognize")
def recognize():
    img_path = os.path.join(ROOT, "temp_frame.jpg")
    if not os.path.exists(img_path):
        return jsonify({"ok": False, "error": "no_frame"})
    frame = cv2.imread(img_path)
    crop = detect_and_crop_face(frame)
    emb = get_embedding_insight(crop)
    if emb is None:
        return jsonify({"ok": True, "recognized": False, "score": 0})

    conn = db()
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    cur.execute("SELECT student_name, embedding FROM student_faces WHERE embedding IS NOT NULL")
    rows = cur.fetchall()
    cur.close()
    conn.close()

    best_score, best_name = -1.0, None
    for row in rows:
        db_vec = np.array(json.loads(row["embedding"]), dtype=np.float32)
        s = cosine(emb, db_vec)
        if s > best_score:
            best_score, best_name = s, row["student_name"]

    if best_score >= 0.45:
        return jsonify({"ok": True, "recognized": True, "name": best_name, "score": best_score})
    return jsonify({"ok": True, "recognized": False, "score": best_score})

# ============================================================
# NEW MOBILE ENDPOINTS (phone camera uploads)
# ============================================================

@app.get("/face/get-actions")
def get_actions():
    # return two random actions for liveness
    return jsonify({"ok": True, "actions": random.sample(ACTIONS, 2)})

@app.post("/face/register-mobile")
def register_mobile():
    """
    Multipart form:
      - file: selfie image from mobile
      - name: student_name to register
    Saves embedding to PostgreSQL (student_faces.embedding)
    """
    f = request.files.get("file")
    name = request.form.get("name")
    if not f or not name:
        return jsonify({"ok": False, "error": "file or name missing"}), 400

    img = read_image_from_upload(f)
    if img is None:
        return jsonify({"ok": False, "error": "invalid image"}), 400

    crop = detect_and_crop_face(img)
    emb = get_embedding_insight(crop)
    if emb is None:
        return jsonify({"ok": False, "error": "no face"}), 200

    try:
        conn = db()
        cur = conn.cursor()
        cur.execute("""
            INSERT INTO student_faces (student_name, embedding)
            VALUES (%s, %s)
            ON CONFLICT (student_name)
            DO UPDATE SET embedding = EXCLUDED.embedding;
        """, (name, json.dumps(emb.tolist())))
        conn.commit()
        cur.close()
        conn.close()
        return jsonify({"ok": True, "msg": "saved"})
    except Exception as e:
        return jsonify({"ok": False, "error": str(e)}), 200

@app.post("/face/recognize-two-step")
def recognize_two_step():
    """
    Multipart form:
      - file1: selfie BEFORE action
      - file2: selfie AFTER action
      - actions[]: exactly two actions returned previously by /face/get-actions
    Returns: { ok, liveness, recognized, name?, score? }
    """
    f1 = request.files.get("file1")
    f2 = request.files.get("file2")
    actions = request.form.getlist("actions[]")
    if not f1 or not f2 or len(actions) != 2:
        return jsonify({"ok": False, "error": "Need file1, file2, and actions[] length 2"}), 400

    img1 = read_image_from_upload(f1)
    img2 = read_image_from_upload(f2)
    if img1 is None or img2 is None:
        return jsonify({"ok": False, "error": "invalid image(s)"}), 400

    # Landmarks
    mesh1, mesh2 = mesh_from_image(img1), mesh_from_image(img2)
    if mesh1 is None or mesh2 is None:
        # fail liveness, still try recognition
        crop2 = detect_and_crop_face(img2)
        emb = get_embedding_insight(crop2)
        if emb is None:
            return jsonify({"ok": True, "liveness": False, "recognized": False})
        # compare
        conn = db()
        cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
        cur.execute("SELECT student_name, embedding FROM student_faces WHERE embedding IS NOT NULL")
        rows = cur.fetchall()
        cur.close()
        conn.close()
        best_name, best_score = None, -1.0
        for row in rows:
            db_vec = np.array(json.loads(row["embedding"]), dtype=np.float32)
            s = cosine(emb, db_vec)
            if s > best_score:
                best_name, best_score = row["student_name"], s
        rec = best_score >= 0.45
        return jsonify({"ok": True, "liveness": False, "recognized": rec, "name": best_name if rec else None, "score": float(best_score)})

    # Liveness features
    yaw1, yaw2 = estimate_yaw_from_mesh(mesh1), estimate_yaw_from_mesh(mesh2)
    l1, r1 = iris_ratio_from_mesh(mesh1, "left"), iris_ratio_from_mesh(mesh1, "right")
    l2, r2 = iris_ratio_from_mesh(mesh2, "left"), iris_ratio_from_mesh(mesh2, "right")
    hand1, hand2 = hand_present(img1), hand_present(img2)

    def check_action(a):
        if a == "turn_head_left":  return (yaw1 - yaw2) > HEAD_YAW_THRESHOLD
        if a == "turn_head_right": return (yaw2 - yaw1) > HEAD_YAW_THRESHOLD
        if a == "move_eyes_left":  return (l1 - l2) > EYE_MOVE_THRESHOLD and (r1 - r2) > EYE_MOVE_THRESHOLD
        if a == "move_eyes_right": return (l2 - l1) > EYE_MOVE_THRESHOLD and (r2 - r1) > EYE_MOVE_THRESHOLD
        if a == "hand_raise":      return (not hand1) and hand2
        return False

    ok1, ok2 = check_action(actions[0]), check_action(actions[1])
    liveness_ok = ok1 and ok2

    # Recognition on second image
    crop2 = detect_and_crop_face(img2)
    emb = get_embedding_insight(crop2)
    recognized, name, score = False, None, 0.0
    if emb is not None:
        conn = db()
        cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
        cur.execute("SELECT student_name, embedding FROM student_faces WHERE embedding IS NOT NULL")
        rows = cur.fetchall()
        cur.close()
        conn.close()
        best_name, best_score = None, -1.0
        for row in rows:
            db_vec = np.array(json.loads(row["embedding"]), dtype=np.float32)
            s = cosine(emb, db_vec)
            if s > best_score:
                best_name, best_score = row["student_name"], s
        if best_score >= 0.45:
            recognized, name, score = True, best_name, float(best_score)

    return jsonify({
        "ok": True,
        "liveness": bool(liveness_ok),
        "recognized": bool(recognized),
        "name": name,
        "score": float(score)
    })

# ============================================================
@app.get("/health")
def health():
    return jsonify({"ok": True})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
