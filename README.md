# LUMOS AI — The Linux of Professional Photography

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Build](https://github.com/michelbuki14/LUMOS-AI/actions/workflows/ci.yml/badge.svg)](https://github.com/michelbuki14/LUMOS-AI/actions)
[![Discord](https://img.shields.io/discord/123456789?label=Discord&logo=discord)](https://discord.gg/lumos-ai)
[![Docs](https://img.shields.io/badge/docs-available-brightgreen)](docs/)

**The open-source, AI-native operating system for professional photography.**

Free. Open. Extensible. Local-first. Privacy-first. Community-driven.

> Every photographer should own their workflow and their data.

---

## Vision

Become the default platform for professional photographers, studios, universities, AI researchers, camera manufacturers, plugin developers, and enterprise imaging companies.

## Why Open Source?

- **No lock-in** — cloud is always optional, local-first by design
- **Own your data** — catalogs, edits, and AI models stay with you
- **Extensible** — plugins for AI models, RAW formats, export, cloud, color
- **Long-term** — stable APIs, semantic versioning, backward compatibility

## Quick Start

```bash
git clone https://github.com/michelbuki14/LUMOS-AI.git
cd LUMOS-AI
docker compose up          # postgres 5432 + redis 6379 + minio 9000/9001 + api 8000 + ai 8001
```

Then run the desktop app:

```bash
cd apps/desktop
flutter pub get
flutter run -d windows    # or -d macos / -d linux
```

Access points:

- **API** http://localhost:8000 — Docs http://localhost:8000/docs — Health http://localhost:8000/health
- **AI** http://localhost:8001 — Health http://localhost:8001/health
- **MinIO** http://localhost:9001 (`lumos` / `lumos_dev_password`)
- **Desktop** 13 rails: Dashboard, Catalog, Editor (BG/Relight/Remove/Scene/DodgeBurn), AI Cull, Batch, Galleries, Tether, Verticals, Export, Market, Sync, Studio, Settings

`docker compose ps` should show `lumos-postgres`, `lumos-redis`, `lumos-minio`, `lumos-api`, `lumos-ai-service` healthy. `lumos-render` builds with `rust:1.85` + `wgpu`.

## Architecture

```
lumos-ai/
├── apps/desktop/        # Flutter 3.x desktop (Material 3, Riverpod, 13 rails)
├── services/
│   ├── api/             # FastAPI + SQLAlchemy async + PostgreSQL/Redis/MinIO
│   ├── ai/              # ONNX/PyTorch inference (6 models, ONNX-optional, torch=demo fallback)
│   └── render/          # Rust + wgpu (Vulkan/Metal/DX12) 50+ ops
├── packages/sdk/        # Plugin SDK (stable, semver)
├── engine/              # raw / renderer / color / export (Rust)
├── packages/ui/         # shared UI tokens
├── examples/            # plugin + workflow examples
├── docs/                # developer / user / api / sdk / plugin / architecture
├── infra/docker/        # Dockerfiles + compose
├── tests/  benchmarks/  tools/  scripts/
```

Tech: Flutter Desktop · Rust · FastAPI · SQLite (dev) → PostgreSQL (prod) · ONNX Runtime · PyTorch · OpenCV · OpenImageIO · LibRaw · OpenColorIO · Docker · GitHub Actions · Dev Containers.

## Documentation

- [Developer Guide](docs/developer-guide.md) — build, test, contribute
- [User Guide](docs/user-guide.md)
- [API Reference](docs/api-reference.md)
- [SDK Guide](docs/sdk-guide.md) — build plugins
- [Plugin Guide](docs/plugin-guide.md) — AI models, RAW, export, cloud, color, tools
- [Architecture Handbook](docs/architecture.md)
- [Contribution Guide](CONTRIBUTING.md)
- [Governance](GOVERNANCE.md) · [Code of Conduct](CODE_OF_CONDUCT.md) · [Security](SECURITY.md)

## Plugin Architecture

Everything is a plugin:

```
AI models · Camera support · RAW formats · Export formats
Cloud providers · Color profiles · Editing tools · Automation · Batch · Scripting
```

Stable SDK with semantic versioning. Local ONNX, PyTorch, Hugging Face, or user-trained models — all interchangeable.

## Development

```bash
pnpm install           # or flutter pub get / cargo build / pip install -r requirements.txt
flutter analyze        # 0 errors, 0 warnings required
flutter test
docker compose up      # full stack
```

Every commit must compile, pass tests, include docs when behavior changes, and never break public APIs without a migration.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Good first issues, issue templates, PR template, and mentorship available.

```bash
git clone https://github.com/michelbuki14/LUMOS-AI.git
git checkout -b feat/my-feature
# ... code + tests + docs
git push origin feat/my-feature  # open PR
```

## License

[Apache 2.0](LICENSE) — Copyright 2026 LUMOS AI Contributors. Commercial-friendly. See `LICENSE` for third-party compatibility.

## Community

- Discussions: GitHub Discussions
- Discord: https://discord.gg/lumos-ai (placeholder)
- Roadmap: [docs/roadmap.md](docs/roadmap.md)
- Security: see [SECURITY.md](SECURITY.md) — please report privately

---

**Long-term:** v1 stable RAW editor + catalog + AI culling/portrait/batch, v2 tethering + collaboration + mobile + marketplace, v3 distributed rendering + personal models + research APIs.

*Documentation is part of the product.*
