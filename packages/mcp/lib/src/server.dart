import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'protocol.dart';
import 'tools.dart';
import 'permissions.dart';

/// MCP Server — JSON-RPC 2.0 over stdio / HTTP+SSE / WebSocket
/// Modular, permission-aware, replaceable. One server, many tools.

class LumosMcpServer {
  final Map<String, McpTool> _tools;
  final PermissionSet defaultPermissions;
  LumosMcpServer({required List<McpTool> tools, this.defaultPermissions = PermissionSet.readOnly})
      : _tools = {for (var t in tools) t.name: t};

  List<McpToolDefinition> listTools() => _tools.values.map((t) => t.definition).toList();

  Future<McpResponse> handle(McpRequest req, {PermissionSet? perms}) async {
    final p = perms ?? defaultPermissions;
    try {
      switch (req.method) {
        case 'initialize':
          return McpResponse(id: req.id, result: {
            'serverInfo': {'name': 'lumos-mcp', 'version': '0.1.0'},
            'capabilities': {'tools': {}},
            'protocolVersion': '2024-11-05',
          });
        case 'tools/list':
          return McpResponse(id: req.id, result: {'tools': listTools().map((t) => t.toJson()).toList()});
        case 'tools/call':
          final name = req.params?['name'] as String?;
          final args = req.params?['arguments'] as Map<String, dynamic>? ?? {};
          if (name == null) throw Exception('tools/call requires name');
          final tool = _tools[name];
          if (tool == null) throw Exception('Unknown tool $name');
          final result = await tool.invoke(args, p);
          return McpResponse(id: req.id, result: {'content': [{'type': 'text', 'text': jsonEncode(result)}]});
        default:
          return McpResponse(id: req.id, error: {'code': -32601, 'message': 'Method not found ${req.method}'});
      }
    } catch (e) {
      return McpResponse(id: req.id, error: {'code': -32603, 'message': e.toString()});
    }
  }

  /// Serve over stdio (for Claude Desktop / MCP clients)
  Future<void> serveStdio() async {
    await for (final line in stdin.transform(utf8.decoder).transform(const LineSplitter())) {
      if (line.trim().isEmpty) continue;
      try {
        final req = McpRequest.decode(line);
        final resp = await handle(req);
        stdout.writeln(resp.encode());
      } catch (e) {
        stdout.writeln(jsonEncode({'jsonrpc':'2.0','error':{'code':-32700,'message':e.toString()}}));
      }
    }
  }

  static LumosMcpServer withDefaults() => LumosMcpServer(tools: [
    CatalogTool(), ImageSearchTool(), ExifTool(), RawTool(), BatchTool(),
    ColorTool(), FaceTool(), GalleryTool(), CameraTool(), TetherTool(), PluginTool(),
  ]);
}
