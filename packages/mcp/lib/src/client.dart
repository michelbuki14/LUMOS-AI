import 'dart:async';
import 'dart:convert';
import 'protocol.dart';

/// Minimal MCP client — talks to LumosMcpServer over any transport

abstract class McpTransport {
  Future<void> send(String line);
  Stream<String> get incoming;
}

class LumosMcpClient {
  final McpTransport transport;
  int _seq = 0;
  final _pending = <String, Completer<McpResponse>>{};
  late final StreamSubscription<String> _sub;

  LumosMcpClient(this.transport) {
    _sub = transport.incoming.listen((line) {
      try {
        final j = jsonDecode(line) as Map<String, dynamic>;
        final id = j['id'] as String?;
        if (id != null && _pending.containsKey(id)) {
          final resp = McpResponse(id: id, result: j['result'] as Map<String, dynamic>?, error: j['error'] as Map<String, dynamic>?);
          _pending.remove(id)!.complete(resp);
        }
      } catch (_) {}
    });
  }

  Future<McpResponse> _call(String method, [Map<String, dynamic>? params]) {
    final id = '${++_seq}';
    final req = McpRequest(id: id, method: method, params: params);
    final c = Completer<McpResponse>();
    _pending[id] = c;
    transport.send(req.encode());
    return c.future.timeout(const Duration(seconds: 10));
  }

  Future<List<dynamic>> listTools() async {
    final r = await _call('tools/list');
    if (r.error != null) throw Exception(r.error);
    return r.result?['tools'] as List<dynamic>? ?? [];
  }

  Future<Map<String, dynamic>> callTool(String name, Map<String, dynamic> args) async {
    final r = await _call('tools/call', {'name': name, 'arguments': args});
    if (r.error != null) throw Exception(r.error);
    final content = r.result?['content'] as List<dynamic>?;
    if (content != null && content.isNotEmpty) {
      final text = (content.first as Map<String, dynamic>)['text'] as String?;
      if (text != null) return jsonDecode(text) as Map<String, dynamic>;
    }
    return r.result ?? {};
  }

  void dispose() => _sub.cancel();
}
