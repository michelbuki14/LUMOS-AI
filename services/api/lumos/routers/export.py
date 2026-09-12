# =============================================================================
# LUMOS AI — Export Router
# =============================================================================


from fastapi import APIRouter, Depends
from pydantic import BaseModel

from lumos.routers.auth import UserInDB, get_current_user

router = APIRouter()


class ExportRequest(BaseModel):
    asset_ids: list[str]
    format: str = "jpeg"
    quality: int = 90
    width: int | None = None
    height: int | None = None
    color_space: str = "srigb"
    watermark_enabled: bool = False
    watermark_text: str | None = None


class ExportResponse(BaseModel):
    export_id: str
    status: str
    estimated_time_seconds: int


@router.post("", response_model=ExportResponse)
async def export_assets(
    request: ExportRequest,
    current_user: UserInDB = Depends(get_current_user),
):
    """Export processed images."""
    return ExportResponse(
        export_id="export_new_001",
        status="processing",
        estimated_time_seconds=30,
    )


@router.get("/formats")
async def get_export_formats(current_user: UserInDB = Depends(get_current_user)):
    """Get available export formats and their settings."""
    return {
        "formats": [
            {"id": "jpeg", "name": "JPEG", "extension": ".jpg", "supports_transparency": False},
            {"id": "png", "name": "PNG", "extension": ".png", "supports_transparency": True},
            {"id": "tiff", "name": "TIFF", "extension": ".tiff", "supports_transparency": True},
            {"id": "psd", "name": "PSD", "extension": ".psd", "supports_transparency": True},
            {"id": "webp", "name": "WebP", "extension": ".webp", "supports_transparency": True},
            {"id": "avif", "name": "AVIF", "extension": ".avif", "supports_transparency": True},
        ]
    }


@router.get("/{export_id}/status")
async def get_export_status(
    export_id: str,
    current_user: UserInDB = Depends(get_current_user),
):
    """Check export job status."""
    return {"export_id": export_id, "status": "completed", "files": []}
