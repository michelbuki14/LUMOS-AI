import 'protocol.dart';
import 'permissions.dart';

/// Base for all MCP tools — modular, permission-aware, replaceable
abstract class McpTool {
  String get name;
  String get description;
  Map<String, dynamic> get inputSchema;
  List<McpPermission> get requiredPermissions;
  Future<Map<String, dynamic>> invoke(Map<String, dynamic> args, PermissionSet perms);

  McpToolDefinition get definition => McpToolDefinition(
    name: name,
    description: description,
    inputSchema: inputSchema,
    requiredPermissions: requiredPermissions.map((e) => e.name).toList(),
  );

  void assertPerms(PermissionSet perms) {
    if (!perms.allowsAll(requiredPermissions)) {
      throw McpPermissionDenied('Tool $name requires $requiredPermissions, granted ${perms.granted}');
    }
  }
}

class McpPermissionDenied implements Exception {
  final String message;
  McpPermissionDenied(this.message);
  @override
  String toString() => 'McpPermissionDenied: $message';
}

// ── Concrete tools — each maps to a LUMOS domain ──

class CatalogTool extends McpTool {
  @override String get name => 'catalog.list';
  @override String get description => 'List catalog assets with filters';
  @override Map<String, dynamic> get inputSchema => {'type':'object','properties':{'query':{'type':'string'},'limit':{'type':'integer'}},'required':[]};
  @override List<McpPermission> get requiredPermissions => [McpPermission.read];
  @override Future<Map<String, dynamic>> invoke(args, perms) async { assertPerms(perms); return {'assets': [], 'query': args['query']}; }
}

class ImageSearchTool extends McpTool {
  @override String get name => 'image.search';
  @override String get description => 'Semantic image search';
  @override Map<String, dynamic> get inputSchema => {'type':'object','properties':{'embedding':{'type':'array'},'k':{'type':'integer'}},'required':['k']};
  @override List<McpPermission> get requiredPermissions => [McpPermission.read];
  @override Future<Map<String, dynamic>> invoke(args, perms) async { assertPerms(perms); return {'results': []}; }
}

class ExifTool extends McpTool {
  @override String get name => 'exif.get';
  @override String get description => 'Read EXIF/XMP/IPTC for asset';
  @override Map<String, dynamic> get inputSchema => {'type':'object','properties':{'assetId':{'type':'string'}},'required':['assetId']};
  @override List<McpPermission> get requiredPermissions => [McpPermission.read];
  @override Future<Map<String, dynamic>> invoke(args, perms) async { assertPerms(perms); return {'exif': {}, 'assetId': args['assetId']}; }
}

class RawTool extends McpTool {
  @override String get name => 'raw.decode';
  @override String get description => 'Decode RAW via LibRaw/OpenImageIO';
  @override Map<String, dynamic> get inputSchema => {'type':'object','properties':{'path':{'type':'string'},'profile':{'type':'string'}},'required':['path']};
  @override List<McpPermission> get requiredPermissions => [McpPermission.read, McpPermission.filesystem];
  @override Future<Map<String, dynamic>> invoke(args, perms) async { assertPerms(perms); return {'decoded': true, 'path': args['path']}; }
}

class BatchTool extends McpTool {
  @override String get name => 'batch.enqueue';
  @override String get description => 'Enqueue batch edit jobs';
  @override Map<String, dynamic> get inputSchema => {'type':'object','properties':{'jobs':{'type':'array'}},'required':['jobs']};
  @override List<McpPermission> get requiredPermissions => [McpPermission.write];
  @override Future<Map<String, dynamic>> invoke(args, perms) async { assertPerms(perms); return {'enqueued': (args['jobs'] as List).length}; }
}

class ColorTool extends McpTool {
  @override String get name => 'color.profile.list';
  @override String get description => 'List ICC/ACES/OpenColorIO profiles';
  @override Map<String, dynamic> get inputSchema => {'type':'object','properties':{},'required':[]};
  @override List<McpPermission> get requiredPermissions => [McpPermission.read];
  @override Future<Map<String, dynamic>> invoke(args, perms) async { assertPerms(perms); return {'profiles': ['sRGB','AdobeRGB','ACEScg']}; }
}

class FaceTool extends McpTool {
  @override String get name => 'ai.face.detect';
  @override String get description => 'Face recognition / detection';
  @override Map<String, dynamic> get inputSchema => {'type':'object','properties':{'assetId':{'type':'string'}},'required':['assetId']};
  @override List<McpPermission> get requiredPermissions => [McpPermission.read];
  @override Future<Map<String, dynamic>> invoke(args, perms) async { assertPerms(perms); return {'faces': []}; }
}

class GalleryTool extends McpTool {
  @override String get name => 'gallery.create';
  @override String get description => 'Create client gallery';
  @override Map<String, dynamic> get inputSchema => {'type':'object','properties':{'title':{'type':'string'},'assetIds':{'type':'array'}},'required':['title']};
  @override List<McpPermission> get requiredPermissions => [McpPermission.write];
  @override Future<Map<String, dynamic>> invoke(args, perms) async { assertPerms(perms); return {'galleryId': 'g_${DateTime.now().millisecondsSinceEpoch}'}; }
}

class CameraTool extends McpTool {
  @override String get name => 'camera.list';
  @override String get description => 'List tethered cameras';
  @override Map<String, dynamic> get inputSchema => {'type':'object','properties':{},'required':[]};
  @override List<McpPermission> get requiredPermissions => [McpPermission.camera];
  @override Future<Map<String, dynamic>> invoke(args, perms) async { assertPerms(perms); return {'cameras': []}; }
}

class TetherTool extends McpTool {
  @override String get name => 'tether.capture';
  @override String get description => 'Trigger tethered capture';
  @override Map<String, dynamic> get inputSchema => {'type':'object','properties':{'cameraId':{'type':'string'}},'required':[]};
  @override List<McpPermission> get requiredPermissions => [McpPermission.camera, McpPermission.write];
  @override Future<Map<String, dynamic>> invoke(args, perms) async { assertPerms(perms); return {'captured': true}; }
}

class PluginTool extends McpTool {
  @override String get name => 'plugin.list';
  @override String get description => 'List installed plugins';
  @override Map<String, dynamic> get inputSchema => {'type':'object','properties':{},'required':[]};
  @override List<McpPermission> get requiredPermissions => [McpPermission.read];
  @override Future<Map<String, dynamic>> invoke(args, perms) async { assertPerms(perms); return {'plugins': []}; }
}
