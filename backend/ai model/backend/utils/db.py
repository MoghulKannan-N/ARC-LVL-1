# backend/utils/db.py
import sqlite3
import os

DB_FILE = os.environ.get("DB_FILE", "college.db")

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
            rv = cur.fetchall()
        else:
            conn.commit()
            rv = []
        return (rv[0] if rv else None) if one else rv
    finally:
        conn.close()
