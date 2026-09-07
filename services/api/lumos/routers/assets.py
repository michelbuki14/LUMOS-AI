# =============================================================================
# LUMOS AI — Assets Router
# =============================================================================

from datetime import datetime

from fastapi import APIRouter, Depends, File, HTTPException, Query, UploadFile
from pydantic import BaseModel

from lumos.routers.auth import UserInDB, get_current_user

router = APIRouter()


class AssetResponse(BaseModel):
    id: str
    filename: str
    width: int
    height: int
    format: str
    size_bytes: int
    thumbnail_url: str | None = None
    rating: int = 0
    is_starred: bool = False
    created_at: datetime


class AssetListResponse(BaseModel):
    items: list[AssetResponse]
    total: int
    page: int
    limit: int


@router.get("", response_model=AssetListResponse)
async def list_assets(
    page: int = Query(1, ge=1),
    limit: int = Query(50, ge=1, le=100),
    current_user: UserInDB = Depends(get_current_user),
):
    """List all assets for the current user's workspace."""
    return AssetListResponse(
        items=[],
        total=0,
        page=page,
        limit=limit,
    )


@router.post("/upload")
async def upload_asset(
    file: UploadFile = File(...),
    current_user: UserInDB = Depends(get_current_user),
):
    """Upload a new image asset."""
    return {
        "id": "asset_new_001",
        "filename": file.filename,
        "status": "uploading",
    }


@router.get("/{asset_id}", response_model=AssetResponse)
async def get_asset(
    asset_id: str,
    current_user: UserInDB = Depends(get_current_user),
):
    """Get a specific asset by ID."""
    raise HTTPException(status_code=404, detail="Asset not found")


@router.delete("/{asset_id}")
async def delete_asset(
    asset_id: str,
    current_user: UserInDB = Depends(get_current_user),
):
    """Delete an asset."""
    return {"status": "deleted"}


@router.patch("/{asset_id}")
async def update_asset(
    asset_id: str,
    updates: dict,
    current_user: UserInDB = Depends(get_current_user),
):
    """Update asset metadata (rating, tags, etc.)."""
    return {"status": "updated"}
