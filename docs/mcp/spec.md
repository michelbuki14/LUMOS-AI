# MCP Spec — LUMOS AI

JSON-RPC 2.0 over stdio / HTTP+SSE / WebSocket.

## Methods

- `initialize` → `{serverInfo, capabilities, protocolVersion}`
- `tools/list` → `{tools: ToolDefinition[]}`
- `tools/call` → `{"name": ..., "arguments": {...}}` → `{"content":[{"type":"text","text":json}]}`

## Tools (11 default)

`catalog.list`, `image.search`, `exif.get`, `raw.decode`, `batch.enqueue`, `color.profile.list`, `ai.face.detect`, `gallery.create`, `camera.list`, `tether.capture`, `plugin.list`

Each tool declares `requiredPermissions` (`read`/`write`/`camera`/`filesystem`/`network`). Server checks `PermissionSet` before invoke.

## Transports

- **stdio** for Claude Desktop: `lumon_mcp serve --stdio`
- **HTTP** for web: `POST /mcp` with SSE stream
- **WebSocket** for desktop: `ws://localhost:8000/mcp`

See `packages/mcp` (Dart) and `services/mcp` (Python) — identical tool surface.
