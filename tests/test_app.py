from fastapi.testclient import TestClient
from app import app


client = TestClient(app)


def test_root():
    response = client.get("/")
    assert response.status_code == 200
    assert "message" in response.json()


def test_create_item():
    response = client.post(
        "/items",
        json={"name": "book", "price": 100},
    )
    assert response.status_code == 200
    data = response.json()
    assert data["tax"] == 10.0
