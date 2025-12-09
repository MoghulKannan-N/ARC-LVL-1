# backend/utils/ai_helpers.py
import os, json, logging
from openai import OpenAI

logger = logging.getLogger("ai-helpers")

OPENAI_KEY = os.environ.get("OPENAI_API_KEY")
if not OPENAI_KEY:
    raise RuntimeError("OPENAI_API_KEY not set")

client = OpenAI(api_key=OPENAI_KEY)

def openai_text(prompt: str, model: str, max_tokens: int = 1500) -> str:
    try:
        resp = client.chat.completions.create(
            model=model,
            messages=[
                {"role": "system", "content": "Expert academic author. Write long, structured study guides."},
                {"role": "user", "content": prompt}
            ],
            max_completion_tokens=max_tokens
        )
        return resp.choices[0].message.content
    except Exception as e:
        logger.exception("OpenAI text error")
        return "Content unavailable."

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
            text = resp.choices[0].message.content
            if isinstance(text, (dict, list)):
                return text
            return json.loads(text)
        except Exception as e:
            logger.warning(f"OpenAI JSON failed with {m}: {e}")
            continue
    return {}
