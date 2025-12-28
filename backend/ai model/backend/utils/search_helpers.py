# backend/utils/search_helpers.py
from ddgs import DDGS
import logging

logger = logging.getLogger("search-helpers")

def fetch_youtube_links(query: str, max_results: int = 3):
    vids = []
    try:
        with DDGS() as ddgs:
            for v in ddgs.videos(query, max_results=max_results):
                link = v.get("content") or v.get("url")
                if link and link not in vids:
                    vids.append(link)
    except Exception:
        logger.exception("Failed to fetch YouTube links")
    return vids

def fetch_text_links(query: str, max_results: int = 8):
    links = []
    try:
        with DDGS() as ddgs:
            for r in ddgs.text(query, max_results=max_results):
                link = r.get("href") or r.get("url")
                if link and link not in links:
                    links.append(link)
    except Exception:
        logger.exception("Failed to fetch text links")
    return links
