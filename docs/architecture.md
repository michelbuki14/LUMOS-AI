# Architecture Handbook

## Principles

Clean Architecture, SOLID, strong typing, local-first, privacy-first, plugin SDK with semver.

## Layers

- **apps/desktop** Flutter + Riverpod + 13 rails, Material 3, local-first SQLite → Postgres sync
- **services/api** FastAPI + SQLAlchemy async + asyncpg + Redis + MinIO (S3)
- **services/ai** FastAPI inference — 6 models (cull, face, skin, scene, SR, denoise), ONNX Runtime + PyTorch optional, torch=demo fallback, Hugging Face interchangeable
- **services/render** Rust + wgpu (Vulkan/Metal/DX12) 50+ ops, OpenColorIO, LittleCMS, non-destructive graph (AdjustmentNode)

## Data

SQLite dev → PostgreSQL prod (JSONB + full-text), S3-compatible, JWT/OAuth.

## Plugin SDK

`packages/sdk` — stable, versioned. Extensions: AI models, RAW formats, export, cloud, color, tools, automation, batch, scripting. See `docs/plugin-guide.md`.

## Infra

Docker, GitHub Actions, Dev Containers. Every commit must compile + pass tests + update docs if behavior changes.
