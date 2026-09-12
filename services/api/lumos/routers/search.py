# =============================================================================
# LUMOS AI — Search Router
# =============================================================================


from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel

from lumos.routers.auth import UserInDB, get_current_user

router = APIRouter()


class SearchQuery(BaseModel):
    query: str
    filters: dict | None = None
    semantic: bool = True


class SearchResult(BaseModel):
    asset_id: str
    filename: str
    thumbnail_url: str | None = None
    score: float
    metadata: dict = {}


class SearchResponse(BaseModel):
    query: str
    results: list[SearchResult]
    total: int


@router.get("")
async def search_assets(
    q: str = Query("", description="Search query"),
    semantic: bool = Query(True, description="Enable semantic search"),
    current_user: UserInDB = Depends(get_current_user),
):
    """Search assets using natural language or keywords."""
    return SearchResponse(
        query=q,
        results=[],
        total=0,
    )


@router.post("/semantic")
async def semantic_search(
    search: SearchQuery,
    current_user: UserInDB = Depends(get_current_user),
):
    """Semantic search using AI embeddings."""
    return SearchResponse(
        query=search.query,
        results=[],
        total=0,
    )


@router.get("/faces")
async def face_search(
    person_id: str | None = None,
    current_user: UserInDB = Depends(get_current_user),
):
    """Search for images containing specific people."""
    return {"items": [], "total": 0}


@router.get("/similar")
async def similar_images(
    asset_id: str = Query(...),
    current_user: UserInDB = Depends(get_current_user),
):
    """Find visually similar images."""
    return {"items": [], "total": 0}
