# MCP — Model Context Protocol for LUMOS AI

MCP-first, modular, permission-aware, replaceable.

## Tools

Catalog, search, EXIF, color, RAW, batch, face, AI inference, files, plugins, camera, tether, cloud, galleries, assets, projects, automation.

## Spec

JSON-RPC 2.0 over stdio / HTTP+SSE / WebSocket. See `docs/mcp/spec.md`.

```dart
import 'package:lumos_mcp/lumos_mcp.dart';
final server = LumosMcpServer(tools: [CatalogTool(), RawTool()]);
await server.serveStdio();
```

Permissions: every tool declares `requiredPermissions` (read/write, scope). Client requests, server grants per-workspace.

## Tests

`dart test` in `packages/mcp`, `pytest` in `services/mcp`.
