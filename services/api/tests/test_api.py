# =============================================================================
# LUMOS AI — API Tests
# =============================================================================

import pytest
from httpx import AsyncClient, ASGITransport

from lumos.app import create_app

# Test database
TEST_DATABASE_URL = "sqlite+aiosqlite:///./test.db"

@pytest.fixture
def app():
    """Create test application."""
    return create_app()

@pytest.fixture
async def client(app):
    """Create test client."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        yield client

@pytest.fixture
async def auth_headers(client):
    """Get authentication headers."""
    response = await client.post(
        "/api/v1/auth/login",
        data={"username": "demo@lumos.ai", "password": "demo123"}
    )
    token = response.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}


class TestHealth:
    """Test health check endpoint."""
    
    async def test_health_check(self, client):
        response = await client.get("/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"

    async def test_root(self, client):
        response = await client.get("/")
        assert response.status_code == 200
        assert "LUMOS AI" in response.json()["name"]


class TestAuth:
    """Test authentication endpoints."""
    
    async def test_login_success(self, client):
        response = await client.post(
            "/api/v1/auth/login",
            data={"username": "demo@lumos.ai", "password": "demo123"}
        )
        assert response.status_code == 200
        data = response.json()
        assert "access_token" in data
        assert "refresh_token" in data
        assert data["token_type"] == "bearer"

    async def test_login_failure(self, client):
        response = await client.post(
            "/api/v1/auth/login",
            data={"username": "wrong@lumos.ai", "password": "wrongpass"}
        )
        assert response.status_code == 401

    async def test_get_me(self, client, auth_headers):
        response = await client.get("/api/v1/auth/me", headers=auth_headers)
        assert response.status_code == 200
        data = response.json()
        assert data["email"] == "demo@lumos.ai"


class TestAssets:
    """Test asset endpoints."""
    
    async def test_list_assets(self, client, auth_headers):
        response = await client.get("/api/v1/assets", headers=auth_headers)
        assert response.status_code == 200
        data = response.json()
        assert "items" in data
        assert "total" in data

    async def test_get_asset_not_found(self, client, auth_headers):
        response = await client.get("/api/v1/assets/nonexistent", headers=auth_headers)
        assert response.status_code == 404


class TestAI:
    """Test AI endpoints."""
    
    async def test_ai_health(self, client):
        response = await client.get("/api/v1/ai/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"

    async def test_list_models(self, client, auth_headers):
        response = await client.get("/api/v1/ai/models", headers=auth_headers)
        assert response.status_code == 200
        data = response.json()
        assert len(data["models"]) > 0

    async def test_ai_culling(self, client, auth_headers):
        response = await client.post(
            "/api/v1/ai/cull",
            headers=auth_headers,
            json={"asset_ids": ["asset_001", "asset_002"]}
        )
        assert response.status_code == 200

    async def test_ai_mask(self, client, auth_headers):
        response = await client.post(
            "/api/v1/ai/mask",
            headers=auth_headers,
            json={"asset_id": "asset_001", "mask_type": "subject"}
        )
        assert response.status_code == 200


class TestProjects:
    """Test project endpoints."""
    
    async def test_list_projects(self, client, auth_headers):
        response = await client.get("/api/v1/projects", headers=auth_headers)
        assert response.status_code == 200

    async def test_create_project(self, client, auth_headers):
        response = await client.post(
            "/api/v1/projects",
            headers=auth_headers,
            json={"name": "Test Project", "description": "A test project"}
        )
        assert response.status_code == 200
        data = response.json()
        assert data["name"] == "Test Project"


class TestGalleries:
    """Test gallery endpoints."""
    
    async def test_list_galleries(self, client, auth_headers):
        response = await client.get("/api/v1/galleries", headers=auth_headers)
        assert response.status_code == 200

    async def test_create_gallery(self, client, auth_headers):
        response = await client.post(
            "/api/v1/galleries",
            headers=auth_headers,
            json={"name": "Test Gallery", "asset_ids": []}
        )
        assert response.status_code == 200


class TestBatch:
    """Test batch endpoints."""
    
    async def test_create_batch(self, client, auth_headers):
        response = await client.post(
            "/api/v1/batch",
            headers=auth_headers,
            json={
                "name": "Test Batch",
                "asset_ids": ["asset_001"],
                "operations": [{"type": "exposure", "params": {"stops": 0.5}}]
            }
        )
        assert response.status_code == 200

    async def test_get_batch_status(self, client, auth_headers):
        response = await client.get("/api/v1/batch/batch_new_001", headers=auth_headers)
        assert response.status_code == 200


class TestExport:
    """Test export endpoints."""
    
    async def test_get_export_formats(self, client, auth_headers):
        response = await client.get("/api/v1/export/formats", headers=auth_headers)
        assert response.status_code == 200
        data = response.json()
        assert len(data["formats"]) > 0

    async def test_export_assets(self, client, auth_headers):
        response = await client.post(
            "/api/v1/export",
            headers=auth_headers,
            json={"asset_ids": ["asset_001"], "format": "jpeg", "quality": 90}
        )
        assert response.status_code == 200


class TestSearch:
    """Test search endpoints."""
    
    async def test_search_assets(self, client, auth_headers):
        response = await client.get("/api/v1/search?q=wedding", headers=auth_headers)
        assert response.status_code == 200

    async def test_semantic_search(self, client, auth_headers):
        response = await client.post(
            "/api/v1/search/semantic",
            headers=auth_headers,
            json={"query": "sunset portrait", "semantic": True}
        )
        assert response.status_code == 200
