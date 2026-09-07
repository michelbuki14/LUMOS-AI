# Plugin Guide

Support plugins for: AI models, camera, RAW formats, export, cloud, color, tools, automation, batch, scripting.

## Types

- **AI**: ONNX/PyTorch/HF — drop into `services/ai/models/` or register via SDK. Never hard-code one provider.
- **RAW**: LibRaw/OpenImageIO extension.
- **Export**: add format/size to `packages/sdk/export`.
- **Cloud**: S3-compatible, optional.
- **Color**: OpenColorIO profiles.

## Example

See `examples/plugin-hello/` — minimal AI + RAW plugin with tests + docs.

## Sandboxing

Plugins run in-process today; sandboxed WASM planned. Validate inputs, no secrets in repo.

## Publishing

PR to `packages/sdk` or own repo + entry in `docs/plugin-registry.md`. Stable SDK guarantees.
