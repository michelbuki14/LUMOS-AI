# API Reference — LUMOS AI

## Backend (8000)

Base: `http://localhost:8000` Docs: `/docs` Health: `/health`

Routers: `auth`, `assets`, `projects`, `galleries`, `ai`, `batch`, `export`, `search` (see `services/api/lumos/routers/`).

Auth: JWT (access 30m, refresh 7d) + OAuth local/offline.

## AI Service (8001)

Base: `http://localhost:8001` Docs: `/docs` Health: `/health` → `{models_loaded, gpu_available}`

Models: `lumos-cull-v1`, `lumos-face-v1`, `lumos-skin-v1`, `lumos-scene-v1`, `lumos-sr-v1`, `lumos-denoise-v1`. Demo fallback when torch missing.

## Render (8002)

Rust + wgpu. Health: `/health`. Non-destructive graph.

## OpenAPI

FastAPI auto-generates `/openapi.json`. SDK generated from it — breaking changes require major version + migration guide.
