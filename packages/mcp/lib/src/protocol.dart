import 'dart:convert';

/// JSON-RPC 2.0 — MCP wire format
class McpRequest {
  final String jsonrpc = '2.0';
  final String id;
  final String method;
  final Map<String, dynamic>? params;
  McpRequest({required this.id, required this.method, this.params});
  Map<String, dynamic> toJson() => {'jsonrpc': jsonrpc, 'id': id, 'method': method, if (params != null) 'params': params};
  static McpRequest fromJson(Map<String, dynamic> j) => McpRequest(id: j['id'] as String, method: j['method'] as String, params: j['params'] as Map<String, dynamic>?);
  String encode() => jsonEncode(toJson());
  static McpRequest decode(String s) => fromJson(jsonDecode(s) as Map<String, dynamic>);
}

class McpResponse {
  final String jsonrpc = '2.0';
  final String id;
  final Map<String, dynamic>? result;
  final Map<String, dynamic>? error;
  McpResponse({required this.id, this.result, this.error});
  Map<String, dynamic> toJson() => {'jsonrpc': jsonrpc, 'id': id, if (result != null) 'result': result, if (error != null) 'error': error};
  String encode() => jsonEncode(toJson());
}

class McpNotification {
  final String jsonrpc = '2.0';
  final String method;
  final Map<String, dynamic>? params;
  McpNotification({required this.method, this.params});
  Map<String, dynamic> toJson() => {'jsonrpc': jsonrpc, 'method': method, if (params != null) 'params': params};
}

/// MCP initialize
class InitializeParams {
  final String clientName;
  final String clientVersion;
  final List<String> capabilities;
  InitializeParams({required this.clientName, required this.clientVersion, this.capabilities = const []});
  Map<String, dynamic> toJson() => {'clientInfo': {'name': clientName, 'version': clientVersion}, 'capabilities': {for (var c in capabilities) c: {}}};
}

/// Tool definition
class McpToolDefinition {
  final String name;
  final String description;
  final Map<String, dynamic> inputSchema;
  final List<String> requiredPermissions;
  const McpToolDefinition({required this.name, required this.description, required this.inputSchema, this.requiredPermissions = const ['read']});
  Map<String, dynamic> toJson() => {'name': name, 'description': description, 'inputSchema': inputSchema, 'permissions': requiredPermissions};
}
