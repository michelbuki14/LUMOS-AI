# =============================================================================
# LUMOS AI — Projects Router
# =============================================================================

from datetime import datetime

from fastapi import APIRouter, Depends
from pydantic import BaseModel

from lumos.routers.auth import UserInDB, get_current_user

router = APIRouter()


class ProjectCreate(BaseModel):
    name: str
    description: str | None = None
    project_type: str | None = None


class ProjectResponse(BaseModel):
    id: str
    name: str
    description: str | None = None
    project_type: str | None = None
    status: str = "draft"
    asset_count: int = 0
    created_at: datetime


@router.get("")
async def list_projects(current_user: UserInDB = Depends(get_current_user)):
    """List all projects."""
    return {"items": []}


@router.post("")
async def create_project(
    project: ProjectCreate,
    current_user: UserInDB = Depends(get_current_user),
):
    """Create a new project."""
    return {
        "id": "proj_new_001",
        "name": project.name,
        "status": "draft",
        "created_at": datetime.utcnow(),
    }


@router.get("/{project_id}")
async def get_project(
    project_id: str,
    current_user: UserInDB = Depends(get_current_user),
):
    """Get a specific project."""
    return {"id": project_id, "name": "Sample Project"}


@router.delete("/{project_id}")
async def delete_project(
    project_id: str,
    current_user: UserInDB = Depends(get_current_user),
):
    """Delete a project."""
    return {"status": "deleted"}
