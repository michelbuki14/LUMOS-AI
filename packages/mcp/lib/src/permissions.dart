enum McpPermission { read, write, execute, camera, filesystem, network }

class PermissionSet {
  final Set<McpPermission> granted;
  const PermissionSet(this.granted);
  bool allows(McpPermission p) => granted.contains(p);
  bool allowsAll(List<McpPermission> ps) => ps.every(allows);
  static const none = PermissionSet({});
  static const readOnly = PermissionSet({McpPermission.read});
  static const readWrite = PermissionSet({McpPermission.read, McpPermission.write});
  static const full = PermissionSet({McpPermission.read, McpPermission.write, McpPermission.execute, McpPermission.camera, McpPermission.filesystem, McpPermission.network});
}

extension PermParse on String {
  McpPermission toPerm() => McpPermission.values.firstWhere((e) => e.name == this, orElse: () => McpPermission.read);
}
