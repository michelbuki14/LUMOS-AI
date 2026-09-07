# =============================================================================
# LUMOS AI — AI Service Tests
# =============================================================================

import pytest
from httpx import AsyncClient, ASGITransport

from lumos.ai.app import app


@pytest.fixture
async def client():
    """Create test client."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        yield client


class TestHealth:
    """Test health check endpoint."""
    
    async def test_health_check(self, client):
        response = await client.get("/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"
        assert "models_loaded" in data


class TestModels:
    """Test model endpoints."""
    
    async def test_list_models(self, client):
        response = await client.get("/models")
        assert response.status_code == 200
        data = response.json()
        assert "models" in data
        assert len(data["models"]) > 0

    async def test_model_info(self, client):
        response = await client.get("/models")
        data = response.json()
        model = data["models"][0]
        assert "id" in model
        assert "name" in model
        assert "status" in model


class TestInference:
    """Test inference endpoints."""
    
    async def test_predict(self, client):
        response = await client.post(
            "/predict",
            json={
                "model_id": "lumos-cull-v1",
                "inputs": {"image": "base64_encoded_image"},
                "parameters": {"threshold": 0.5}
            }
        )
        assert response.status_code == 200
        data = response.json()
        assert data["model_id"] == "lumos-cull-v1"
        assert "outputs" in data
        assert "processing_time_ms" in data

    async def test_batch_predict(self, client):
        response = await client.post(
            "/batch_predict",
            json=[
                {
                    "model_id": "lumos-cull-v1",
                    "inputs": {"image": "image_1"},
                    "parameters": {}
                },
                {
                    "model_id": "lumos-face-v1",
                    "inputs": {"image": "image_2"},
                    "parameters": {}
                }
            ]
        )
        assert response.status_code == 200
        data = response.json()
        assert "results" in data
        assert len(data["results"]) == 2
