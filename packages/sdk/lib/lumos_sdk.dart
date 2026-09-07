// LUMOS SDK — minimal stable surface
library lumos_sdk;

abstract class RawPlugin {
  String get id;
  String get version;
  Future<dynamic> decode(List<int> bytes);
}
abstract class AiPlugin {
  String get id;
  String get version;
  Future<Map<String, dynamic>> infer(Map<String, dynamic> input);
}
class Registry {
  final raw = _RawRegistry();
  final ai = _AiRegistry();
}
class _RawRegistry {
  final _m = <String, RawPlugin>{};
  void register(RawPlugin p) => _m[p.id] = p;
}
class _AiRegistry {
  final _m = <String, AiPlugin>{};
  void register(AiPlugin p) => _m[p.id] = p;
}
