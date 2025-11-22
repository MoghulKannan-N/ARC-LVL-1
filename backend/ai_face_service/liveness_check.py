# liveness_check.py — quick liveness (simple blink/head-turn cue) + ArcFace recognition via ONNX
# Writes last_result.json if --write-json path is provided

import os
import sys
import json
import cv2
import time
import pickle
import numpy as np
import onnxruntime as ort
import mediapipe as mp
from collections import deque

ROOT = os.path.dirname(os.path.abspath(__file__))
MODEL_DIR = os.path.join(ROOT, "models", "buffalo_l")
FACE_DB_PATH = os.path.join(ROOT, "face_db.pkl")

# pick an arcface onnx
ARCFACE_ONNX = None
for fname in ["w600k_r50.onnx", "glintr100.onnx", "arcface_r100_v1.onnx"]:
    p = os.path.join(MODEL_DIR, fname)
    if os.path.exists(p):
        ARCFACE_ONNX = p
        break
if ARCFACE_ONNX is None:
    raise FileNotFoundError("ArcFace ONNX model not found in models/buffalo_l")

# thresholds
RECOG_THRESHOLD = 0.45

def l2_normalize(v):
    n = np.linalg.norm(v)
    return v / max(n, 1e-12)

def preprocess_arcface(img_bgr, size=(112,112)):
    img = cv2.resize(img_bgr, size)
    img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB).astype(np.float32)
    img = (img - 127.5) / 128.0
    img = np.transpose(img, (2,0,1))  # CHW
    img = np.expand_dims(img, 0)      # NCHW
    return img

def get_embedding(session, face_bgr):
    x = preprocess_arcface(face_bgr)
    input_name = session.get_inputs()[0].name
    out = session.run(None, {input_name: x})[0][0]
    return l2_normalize(out)

def cosine(a, b):
    return float(np.dot(a, b) / max(np.linalg.norm(a) * np.linalg.norm(b), 1e-12))

def load_face_db():
    if os.path.exists(FACE_DB_PATH):
        with open(FACE_DB_PATH, "rb") as f:
            return pickle.load(f)
    return {}

def find_face_box(img):
    cascade = cv2.CascadeClassifier(cv2.data.haarcascades +
                                    "haarcascade_frontalface_default.xml")
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    faces = cascade.detectMultiScale(gray, scaleFactor=1.2, minNeighbors=5, minSize=(80,80))
    if len(faces) == 0:
        return None
    faces = sorted(faces, key=lambda r: r[2]*r[3], reverse=True)
    (x,y,w,h) = faces[0]
    pad = int(0.1 * max(w,h))
    x0 = max(0, x - pad); y0 = max(0, y - pad)
    x1 = min(img.shape[1], x + w + pad); y1 = min(img.shape[0], y + h + pad)
    return (x0,y0,x1,y1)

def main():
    # output json path
    out_json = None
    args = sys.argv[1:]
    if "--write-json" in args:
        i = args.index("--write-json")
        if i + 1 < len(args):
            out_json = args[i+1]

    # init models
    arc_sess = ort.InferenceSession(ARCFACE_ONNX, providers=["CPUExecutionProvider"])
    db = load_face_db()

    # mediapipe facemesh for a simple head-turn cue as liveness
    mp_mesh = mp.solutions.face_mesh
    mesh = mp_mesh.FaceMesh(max_num_faces=1, refine_landmarks=True,
                            min_detection_confidence=0.6, min_tracking_confidence=0.6)
    history = deque(maxlen=5)

    cap = cv2.VideoCapture(0, cv2.CAP_DSHOW)
    if not cap.isOpened():
        print("❌ Cannot open camera")
        result = {"ok": False, "error": "camera_open_failed"}
        if out_json:
            with open(out_json, "w", encoding="utf-8") as f:
                json.dump(result, f)
        return

    print("👀 Liveness: please slowly turn head LEFT then RIGHT… (ESC to cancel)")

    turned_left = False
    turned_right = False
    yaw_thresh = 0.12

    def estimate_yaw(landmarks, w, h):
        pts = np.array([[p.x*w, p.y*h] for p in landmarks.landmark], dtype=np.float32)
        # simple yaw proxy: nose x minus mid-eye x
        L = np.mean(pts[[33,133], 0])   # left eye x
        R = np.mean(pts[[362,263], 0])  # right eye x
        mid = 0.5*(L+R)
        nose_x = pts[1, 0]
        return (nose_x - mid) / (R - L + 1e-6)

    name_label = "Unknown"
    score_val = 0.0
    recognized = False

    while True:
        ret, frame = cap.read()
        if not ret:
            continue
        frame = cv2.flip(frame, 1)
        h, w = frame.shape[:2]

        # ---- liveness via head turn
        rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        res = mesh.process(rgb)
        if res.multi_face_landmarks:
            lm = res.multi_face_landmarks[0]
            yaw = estimate_yaw(lm, w, h)
            history.append(yaw)
            yaw_s = float(np.mean(history))
            if yaw_s < -yaw_thresh:
                turned_left = True
            if yaw_s > yaw_thresh:
                turned_right = True

        cv2.putText(frame, f"Liveness: left={turned_left} right={turned_right}",
                    (10,30), cv2.FONT_HERSHEY_SIMPLEX, 0.8,
                    (0,255 if (turned_left or turned_right) else 0, 255 if turned_right else 0), 2)

        # When liveness passes, run recognition once
        if (turned_left and turned_right) and not recognized:
            box = find_face_box(frame)
            if box:
                x0,y0,x1,y1 = box
                face = frame[y0:y1, x0:x1].copy()
                emb = get_embedding(arc_sess, face)

                best_name = "Unknown"
                best_score = -1.0
                for k, v in db.items():
                    sc = cosine(emb, v)
                    if sc > best_score:
                        best_score = sc
                        best_name = k
                name_label = best_name if best_score >= RECOG_THRESHOLD else "Unknown"
                score_val = float(best_score)
                recognized = True

        # draw face box
        box = find_face_box(frame)
        if box:
            cv2.rectangle(frame, (box[0],box[1]), (box[2],box[3]), (0,255,0), 2)

        cv2.putText(frame, f"Recognized: {name_label} ({score_val:.2f})",
                    (10,60), cv2.FONT_HERSHEY_SIMPLEX, 0.8,
                    (0,255,0) if recognized else (0,200,255), 2)

        cv2.imshow("Liveness + Recognition (ONNX)", frame)
        key = cv2.waitKey(1) & 0xFF
        if key == 27 or recognized:
            break

    cap.release()
    cv2.destroyAllWindows()

    result = {"recognized": recognized, "name": name_label, "score": score_val}
    if out_json:
        with open(out_json, "w", encoding="utf-8") as f:
            json.dump(result, f, ensure_ascii=False)

if __name__ == "__main__":
    main()
