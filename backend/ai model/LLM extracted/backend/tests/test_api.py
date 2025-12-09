# backend/tests/test_api.py
import pytest
from fastapi.testclient import TestClient
from app_full_prototype_improved import app

client = TestClient(app)

def test_health():
    resp = client.get("/health")
    assert resp.status_code == 200
    assert "status" in resp.json()

def test_add_student():
    resp = client.post("/add_student", data={"name": "TestUser", "dept": "CSE"})
    assert resp.status_code == 200
    data = resp.json()
    assert data["message"] == "Student added"
    assert "student" in data
