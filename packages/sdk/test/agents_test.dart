import 'package:flutter_test/flutter_test.dart';
import 'package:lumos_sdk/src/agents/agents.dart';

void main() {
  test('orchestrator dispatches to correct agent', () async {
    final orch = AgentOrchestrator([RawDevelopmentAgent(), CatalogAgent()]);
    final res = await orch.dispatch({'type':'raw.decode','path':'a.dng'});
    expect(res['agent'], 'raw.dev');
  });

  test('catalog agent', () async {
    final orch = AgentOrchestrator([CatalogAgent()]);
    final res = await orch.dispatch({'type':'catalog.search','query':'sunset'});
    expect(res['agent'], 'catalog.mgmt');
  });

  test('unknown task throws', () async {
    final orch = AgentOrchestrator([ExportAgent()]);
    expect(() => orch.dispatch({'type':'unknown'}), throwsException);
  });
}
