import 'package:flutter_test/flutter_test.dart';
import 'package:lumos_mcp/lumos_mcp.dart';

void main() {
  test('MCP server lists tools', () async {
    final server = LumosMcpServer.withDefaults();
    final tools = server.listTools();
    expect(tools.length, greaterThan(5));
    expect(tools.map((t) => t.name), contains('catalog.list'));
  });

  test('tools/call requires permissions', () async {
    final server = LumosMcpServer(tools: [BatchTool()], defaultPermissions: PermissionSet.readOnly);
    final req = McpRequest(id: '1', method: 'tools/call', params: {'name': 'batch.enqueue', 'arguments': {'jobs': []}});
    final resp = await server.handle(req);
    expect(resp.error, isNotNull);
    expect(resp.error!['message'], contains('requires'));
  });

  test('initialize handshake', () async {
    final server = LumosMcpServer.withDefaults();
    final req = McpRequest(id: '1', method: 'initialize', params: {'clientInfo': {'name':'test'}});
    final resp = await server.handle(req);
    expect(resp.result?['serverInfo']['name'], 'lumos-mcp');
  });

  test('exif tool', () async {
    final server = LumosMcpServer.withDefaults();
    final req = McpRequest(id: '1', method: 'tools/call', params: {'name':'exif.get','arguments':{'assetId':'a1'}});
    final resp = await server.handle(req);
    expect(resp.error, isNull);
  });
}
