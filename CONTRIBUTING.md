# Contributing to LUMOS AI

Thank you for building the Linux of photography.

## Principles

Transparency, modularity, documentation, maintainability, stable APIs, backward compatibility, open standards. Cloud always optional.

## Getting Started

1. Read [docs/developer-guide.md](docs/developer-guide.md) and [docs/architecture.md](docs/architecture.md)
2. Pick a `good first issue` or open a discussion
3. Fork + branch: `git checkout -b feat/short-name`

## Development Workflow

```bash
git clone https://github.com/michelbuki14/LUMOS-AI.git
cd LUMOS-AI
docker compose up -d postgres redis minio  # infra
# api/ai via docker, or locally: uvicorn lumos.app:app --reload
cd apps/desktop && flutter pub get && flutter run -d windows
```

Every feature must include:

- Architecture overview
- Complete implementation (no stubs left behind)
- Unit + integration tests
- Performance notes
- Documentation + changelog entry

## Quality Bar

- Compile: `flutter analyze` → 0 errors, 0 warnings. `cargo check`, `pytest`.
- Tests: `flutter test`, `pytest`, `cargo test` pass.
- Docs: update `docs/` when behavior changes.
- API: never break public API without `MIGRATION.md` and semver.
- Style: `dart format`, `rustfmt`, `ruff`/`black`. Strong typing, Clean Architecture, SOLID where appropriate.

## Commit & PR

- Conventional commits: `feat:`, `fix:`, `docs:`, `chore:` etc.
- One logical change per commit. Sign your commits if you can.
- PR template: describe architecture, testing, docs, performance, API impact.
- All checks must pass (CI: flutter analyze, cargo check, pytest, docker build).

## Plugin Contributions

See [docs/plugin-guide.md](docs/plugin-guide.md) and [packages/sdk/README.md](packages/sdk/README.md). SDK follows semver — breaking changes require major version + migration guide.

## Community

Be kind, review thoroughly, mentor newcomers. See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md). Report security issues per [SECURITY.md](SECURITY.md), not public issues.

## License

By contributing, you agree your contributions are licensed under [Apache 2.0](LICENSE).
