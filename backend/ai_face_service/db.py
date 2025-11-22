import psycopg2
import psycopg2.extras
import numpy as np

DB_CONFIG = {
    "dbname": "Smart_curriculum",
    "user": "postgres",
    "password": "YOUR_PASSWORD",
    "host": "localhost",
    "port": 5433
}

def get_connection():
    return psycopg2.connect(**DB_CONFIG)

# ===== INSERT EMBEDDING =====
def save_face_embedding(student_name: str, emb: np.ndarray):
    conn = get_connection()
    cur = conn.cursor()

    # Convert numpy → python list
    vector_list = emb.tolist()

    cur.execute("""
        INSERT INTO student_faces (student_name, embedding)
        VALUES (%s, %s)
        ON CONFLICT (student_name)
        DO UPDATE SET embedding = EXCLUDED.embedding;
    """, (student_name, vector_list))

    conn.commit()
    cur.close()
    conn.close()


# ===== LOAD ALL EMBEDDINGS =====
def load_all_embeddings():
    conn = get_connection()
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

    cur.execute("SELECT student_name, embedding FROM student_faces")

    rows = cur.fetchall()
    cur.close()
    conn.close()

    # Convert list → numpy array
    return {row["student_name"]: np.array(row["embedding"], dtype=np.float32) for row in rows}
