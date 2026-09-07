# =============================================================================
# LUMOS AI — Galleries Router
# =============================================================================

from datetime import datetime

from fastapi import APIRouter, Depends
from pydantic import BaseModel

from lumos.routers.auth import UserInDB, get_current_user

router = APIRouter()


class GalleryCreate(BaseModel):
    name: str
    description: str | None = None
    asset_ids: list[str] = []


class GalleryResponse(BaseModel):
    id: str
    name: str
    status: str = "draft"
    view_count: int = 0
    created_at: datetime


@router.get("")
async def list_galleries(current_user: UserInDB = Depends(get_current_user)):
    """List all galleries."""
    return {"items": []}


@router.post("")
async def create_gallery(
    gallery: GalleryCreate,
    current_user: UserInDB = Depends(get_current_user),
):
    """Create a new client gallery."""
    return {
        "id": "gallery_new_001",
        "name": gallery.name,
        "status": "draft",
        "created_at": datetime.utcnow(),
    }


@router.post("/{gallery_id}/publish")
async def publish_gallery(
    gallery_id: str,
    current_user: UserInDB = Depends(get_current_user),
):
    """Publish a gallery for client access."""
    return {"status": "published", "url": f"/g/{gallery_id}"}


@router.get("/{gallery_id}/stats")
async def gallery_stats(
    gallery_id: str,
    current_user: UserInDB = Depends(get_current_user),
):
    """Get gallery view/download statistics."""
    return {"views": 0, "downloads": 0, "selections": 0}
