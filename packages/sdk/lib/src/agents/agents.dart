import 'dart:async';
import 'dart:collection';

/// Base for all specialized AI agents — shared context, isolated responsibility
abstract class LumosAgent {
  String get id;
  String get displayName;
  String get description;
  List<String> get capabilities;
  Future<Map<String, dynamic>> handle(Map<String, dynamic> task, Map<String, dynamic> sharedContext);
  bool canHandle(Map<String, dynamic> task) => capabilities.contains(task['type']);
}

class AgentContext extends MapBase<String, dynamic> {
  final Map<String, dynamic> _inner;
  AgentContext([Map<String, dynamic>? seed]) : _inner = Map.of(seed ?? {});
  @override
  dynamic operator [](Object? key) => _inner[key];
  @override
  void operator []=(String key, dynamic value) => _inner[key] = value;
  @override
  void clear() => _inner.clear();
  @override
  Iterable<String> get keys => _inner.keys;
  @override
  dynamic remove(Object? key) => _inner.remove(key);
}

class AgentOrchestrator {
  final Map<String, LumosAgent> _agents;
  final AgentContext context;
  AgentOrchestrator(List<LumosAgent> agents, {Map<String, dynamic>? seed})
      : _agents = {for (var a in agents) a.id: a}, context = AgentContext(seed);

  Future<Map<String, dynamic>> dispatch(Map<String, dynamic> task) async {
    final agent = _agents.values.firstWhere(
      (a) => a.canHandle(task),
      orElse: () => throw Exception('No agent for ${task['type']}'),
    );
    final result = await agent.handle(task, context);
    context['lastResult'] = result;
    return result;
  }

  List<String> get agentIds => _agents.keys.toList();
}

// ── Concrete agents (thin, testable — real work delegated to engine/ai) ──

class RawDevelopmentAgent extends LumosAgent {
  @override String get id => 'raw.dev';
  @override String get displayName => 'RAW Development Agent';
  @override String get description => 'Demosaic, highlight recovery, shadow recovery, white balance';
  @override List<String> get capabilities => ['raw.decode', 'raw.develop', 'highlight.recover', 'shadow.recover'];
  @override Future<Map<String, dynamic>> handle(Map<String, dynamic> task, Map<String, dynamic> ctx) async => {'agent': id, 'task': task, 'ev': 0.0};
}

class PortraitRetouchAgent extends LumosAgent {
  @override String get id => 'portrait.retouch';
  @override String get displayName => 'Portrait Retouch Agent';
  @override String get description => 'Skin, eyes, face, frequency separation';
  @override List<String> get capabilities => ['portrait.retouch', 'skin.smooth', 'eye.enhance'];
  @override Future<Map<String, dynamic>> handle(Map<String, dynamic> task, Map<String, dynamic> ctx) async => {'agent': id, 'ok': true};
}

class WeddingWorkflowAgent extends LumosAgent {
  @override String get id => 'wedding.workflow';
  @override String get displayName => 'Wedding Workflow Agent';
  @override String get description => 'Culling → color → batch 800 images';
  @override List<String> get capabilities => ['wedding.cull', 'wedding.batch'];
  @override Future<Map<String, dynamic>> handle(Map<String, dynamic> task, Map<String, dynamic> ctx) async => {'agent': id, 'batch': 800};
}

class ProductAgent extends LumosAgent {
  @override String get id => 'product.photo';
  @override String get displayName => 'Product Photography Agent';
  @override String get description => 'Shadow, reflection, pure white';
  @override List<String> get capabilities => ['product.shadow', 'product.white'];
  @override Future<Map<String, dynamic>> handle(Map<String, dynamic> task, Map<String, dynamic> ctx) async => {'agent': id, 'ok': true};
}

class RealEstateAgent extends LumosAgent {
  @override String get id => 'realestate.agent';
  @override String get displayName => 'Real Estate Agent';
  @override String get description => 'Perspective, window pull, sky replace';
  @override List<String> get capabilities => ['realestate.correct', 'realestate.sky'];
  @override Future<Map<String, dynamic>> handle(Map<String, dynamic> task, Map<String, dynamic> ctx) async => {'agent': id, 'ok': true};
}

class CatalogAgent extends LumosAgent {
  @override String get id => 'catalog.mgmt';
  @override String get displayName => 'Catalog Management Agent';
  @override String get description => 'Ingest, tag, search, DAM';
  @override List<String> get capabilities => ['catalog.ingest', 'catalog.search', 'catalog.tag'];
  @override Future<Map<String, dynamic>> handle(Map<String, dynamic> task, Map<String, dynamic> ctx) async => {'agent': id, 'count': 0};
}

class ExportAgent extends LumosAgent {
  @override String get id => 'export.agent';
  @override String get displayName => 'Export Agent';
  @override String get description => 'JPEG/PNG/TIFF/WebP/AVIF + YouTube/TikTok presets';
  @override List<String> get capabilities => ['export.render', 'export.preset'];
  @override Future<Map<String, dynamic>> handle(Map<String, dynamic> task, Map<String, dynamic> ctx) async => {'agent': id, 'exported': true};
}
