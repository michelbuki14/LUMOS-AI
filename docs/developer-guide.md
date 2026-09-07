# Developer Guide

## Prereqs

Docker 24+, Flutter 3.24+, Rust 1.85+, Python 3.12+, Node 20+, pnpm 9+.

## Quick Dev

```bash
docker compose up -d postgres redis minio
docker compose up -d api ai   # ai runs torch=demo locally; add --build if needed
# render needs rust:1.85 + wgpu, builds ~60s: docker compose build render && docker compose up -d render
cd apps/desktop && flutter pub get && flutter run -d windows
```

Checks: `flutter analyze` → 0 errors, `cargo check`, `pytest`, `dart analyze`, `docker compose ps` healthy.

## Repo Layout

See `README.md` Architecture + `docs/architecture.md`.

## Contributing

See `CONTRIBUTING.md`, `GOVERNANCE.md`, `CODE_OF_CONDUCT.md`.

## Testing

```bash
flutter test
cargo test
pytest services/api/tests services/ai/tests
docker compose up --build # full integration
```

## Docs

Update `docs/` with every behavior change. Run `flutter analyze` before pushing.
