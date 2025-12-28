# Dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

ENV DB_FILE=/app/college.db

EXPOSE 8000

CMD ["uvicorn", "app_full_prototype_improved:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "1"]
