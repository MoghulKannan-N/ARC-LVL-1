# backend/utils/__init__.py
"""
Utility helpers for DB, AI (OpenAI), and search.
"""
from .db import query_db, get_conn
from .ai_helpers import openai_text, openai_json
from .search_helpers import fetch_youtube_links, fetch_text_links
