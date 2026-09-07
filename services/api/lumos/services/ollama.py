"""
LUMOS Ollama — local LLM client (qwen:latest)
Uses http://localhost:11434 when running on host, or http://ollama:11434 in Docker.
"""
import os
import httpx

OLLAMA_URL = os.getenv("OLLAMA_URL", "http://localhost:11434")
OLLAMA_MODEL = os.getenv("OLLAMA_MODEL", "qwen:latest")

async def ollama_chat(prompt: str, system: str = "You are LUMOS AI, the Linux of photography. Be concise, technical, helpful.") -> str:
    async with httpx.AsyncClient(timeout=60) as client:
        r = await client.post(f"{OLLAMA_URL}/api/chat", json={
            "model": OLLAMA_MODEL,
            "messages": [
                {"role": "system", "content": system},
                {"role": "user", "content": prompt},
            ],
            "stream": False,
        })
        r.raise_for_status()
        return r.json()["message"]["content"]

def ollama_chat_sync(prompt: str, system: str = "You are LUMOS AI.") -> str:
    import httpx as _hx
    with _hx.Client(timeout=60) as client:
        r = client.post(f"{OLLAMA_URL}/api/chat", json={
            "model": OLLAMA_MODEL,
            "messages": [{"role": "system", "content": system}, {"role": "user", "content": prompt}],
            "stream": False,
        })
        r.raise_for_status()
        return r.json()["message"]["content"]
