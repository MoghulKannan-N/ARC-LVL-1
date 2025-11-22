# register.py — capture a few face crops, make ArcFace embeddings with ONNX Runtime, save into face_db.pkl

import os
import sys
import cv2
import time
import pickle
import numpy as np
import onnxruntime as ort


def register_from_frame(name, frame):
    sess = ort.InferenceSession(ARCFACE_ONNX, providers=["CPUExecutionProvider"])

    collected = []
    for _ in range(10):
        box = find_face_box(frame)
        if not box:
            return False, "Face not detected"

        x0,y0,x1,y1 = box
        face = frame[y0:y1, x0:x1]
        emb = get_embedding(sess, face)
        collected.append(emb)

    mean_emb = l2_normalize(np.mean(np.stack(collected), axis=0))

    db = load_face_db()
    db[name] = mean_emb.astype(np.float32)
    save_face_db(db)

    return True, f"Face registered for {name}"

# ---------- Paths ----------
ROOT = os.path.dirname(os.path.abspath(__file__))
MODEL_DIR = os.path.join(ROOT, "models", "buffalo_l")
ARCFACE_ONNX = None

# Try common file names inside buffalo_l pack
for fname in ["w600k_r50.onnx", "glintr100.onnx", "arcface_r100_v1.onnx"]:
    p = os.path.join(MODEL_DIR, fname)
    if os.path.exists(p):
        ARCFACE_ONNX = p
        break

if ARCFACE_ONNX is None:
    raise FileNotFoundError("ArcFace ONNX model not found in models/buffalo_l. "
                            "Place buffalo_l ONNX there (e.g., w600k_r50.onnx).")

FACE_DB_PATH = os.path.join(ROOT, "face_db.pkl")

# ---------- Helpers ----------
def load_face_db():
    if os.path.exists(FACE_DB_PATH):
        with open(FACE_DB_PATH, "rb") as f:
            return pickle.load(f)
    return {}

def save_face_db(db):
    with open(FACE_DB_PATH, "wb") as f:
        pickle.dump(db, f)

def l2_normalize(v):
    n = np.linalg.norm(v)
    return v / max(n, 1e-12)

def preprocess_arcface(img_bgr, size=(112,112)):
    # ArcFace expects RGB, 112x112, float32 normalized roughly to [-1,1]
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

def find_face_box(img):
    # Try a simple Haar-cascade detector as fallback if you don’t have SCRFD ONNX
    # (ships with OpenCV; good enough for capture)
    cascade = cv2.CascadeClassifier(cv2.data.haarcascades +
                                    "haarcascade_frontalface_default.xml")
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    faces = cascade.detectMultiScale(gray, scaleFactor=1.2, minNeighbors=5, minSize=(80,80))
    if len(faces) == 0:
        return None
    # take the largest face
    faces = sorted(faces, key=lambda r: r[2]*r[3], reverse=True)
    (x,y,w,h) = faces[0]
    # add a bit of margin
    pad = int(0.1 * max(w,h))
    x0 = max(0, x - pad); y0 = max(0, y - pad)
    x1 = min(img.shape[1], x + w + pad); y1 = min(img.shape[0], y + h + pad)
    return (x0,y0,x1,y1)

def main():
    # read name from CLI arg: --name John
    name = None
    args = sys.argv[1:]
    if "--name" in args:
        i = args.index("--name")
        if i + 1 < len(args):
            name = args[i+1].strip()

    if not name:
        # fallback to interactive prompt if ran directly
        name = input("Enter new person name: ").strip()

    if not name:
        print("❌ Invalid name")
        return

    # Init ONNX session
    sess = ort.InferenceSession(ARCFACE_ONNX, providers=["CPUExecutionProvider"])

    # Capture multiple views
    cap = cv2.VideoCapture(0, cv2.CAP_DSHOW)
    if not cap.isOpened():
        print("❌ Cannot open camera")
        return

    print(f"📸 Registering face for: {name}")
    print("Look at camera; the app will grab ~10 crops automatically.")
    collected = []
    target_count = 10
    last_saved = 0

    while len(collected) < target_count:
        ret, frame = cap.read()
        if not ret:
            continue
        frame = cv2.flip(frame, 1)

        box = find_face_box(frame)
        if box:
            (x0,y0,x1,y1) = box
            face = frame[y0:y1, x0:x1].copy()
            cv2.rectangle(frame, (x0,y0), (x1,y1), (0,255,0), 2)

            now = time.time()
            # sample roughly 2 per second
            if now - last_saved > 0.5:
                emb = get_embedding(sess, face)
                collected.append(emb)
                last_saved = now

                cv2.putText(frame, f"Captured: {len(collected)}/{target_count}",
                            (10,30), cv2.FONT_HERSHEY_SIMPLEX, 1, (0,255,0), 2)

        cv2.imshow("Register Face", frame)
        if cv2.waitKey(1) & 0xFF == 27:
            break

    cap.release()
    cv2.destroyAllWindows()

    if not collected:
        print("❌ No samples captured")
        return

    # Average embedding
    mean_emb = l2_normalize(np.mean(np.stack(collected, axis=0), axis=0))

    db = load_face_db()
    db[name] = mean_emb.astype(np.float32)
    save_face_db(db)
    print(f"✅ Saved embedding for {name}. Total people in DB: {len(db)}")

if __name__ == "__main__":
    main()
