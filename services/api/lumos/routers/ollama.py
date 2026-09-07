from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from lumos.services.ollama import ollama_chat

router = APIRouter(tags=["ollama"])

class ChatRequest(BaseModel):
    prompt: str
    system: str | None = None

@router.post("/chat")
async def chat(req: ChatRequest):
    try:
        text = await ollama_chat(req.prompt, req.system or "You are LUMOS AI, the Linux of photography.")
        return {"model": "qwen:latest", "response": text}
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"Ollama error: {e}")

@router.get("/health")
async def health():
    import os
    import httpx

    url = os.getenv("OLLAMA_URL", "http://host.docker.internal:11434")
    try:
        async with httpx.AsyncClient(timeout=3) as c:
            r = await c.get(f"{url}/api/tags")
            r.raise_for_status()
            return {"status": "ok", "url": url, "models": r.json().get("models", [])[:1]}
    except Exception as e:
        raise HTTPException(status_code=502, detail=str(e))
