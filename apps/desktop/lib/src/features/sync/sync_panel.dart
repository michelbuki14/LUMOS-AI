import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Module 8b — Cloud Sync (optional) — local-first with conflict-free graph sync
/// SQLite dev → Postgres prod + S3, WS sync when online, fully offline otherwise.

enum SyncStatus { offline, syncing, synced, conflict }
class SyncState{
  final SyncStatus status;
  final bool enabled;
  final double progress;
  final String lastSync;
  final int pendingOps;
  const SyncState({this.status=SyncStatus.offline, this.enabled=false, this.progress=0, this.lastSync='Never', this.pendingOps=0});
  SyncState copyWith({SyncStatus? status, bool? enabled, double? progress, String? lastSync, int? pendingOps}) =>
    SyncState(status: status??this.status, enabled: enabled??this.enabled, progress: progress??this.progress, lastSync: lastSync??this.lastSync, pendingOps: pendingOps??this.pendingOps);
}
class SyncNotifier extends StateNotifier<SyncState>{
  SyncNotifier():super(const SyncState());
  void setEnabled(bool v)=> state=state.copyWith(enabled:v, status: v? SyncStatus.synced : SyncStatus.offline);
  void reset()=> state=const SyncState();
  Future<void> syncNow() async{
    if(!state.enabled) return;
    state=state.copyWith(status: SyncStatus.syncing, progress:0.2);
    await Future.delayed(const Duration(milliseconds:700));
    state=state.copyWith(progress:0.8);
    await Future.delayed(const Duration(milliseconds:400));
    // prod: WS + S3 multipart + Postgres JSONB graph merge (last-write-wins per node)
    state=state.copyWith(status: SyncStatus.synced, progress:1, lastSync: DateTime.now().toString().substring(11,19), pendingOps:0);
  }
}
final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>((_)=>SyncNotifier());

class SyncPanel extends ConsumerWidget{
  const SyncPanel({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref){
    final s=ref.watch(syncProvider);
    final n=ref.read(syncProvider.notifier);
    return ListView(padding: const EdgeInsets.all(16), children:[
      Row(children:[Icon(s.status==SyncStatus.synced? Icons.cloud_done : s.status==SyncStatus.syncing? Icons.sync : Icons.cloud_off, color: s.status==SyncStatus.synced? Colors.greenAccent: Colors.white54, size:18), const SizedBox(width:8), Text('Cloud Sync', style: Theme.of(context).textTheme.titleMedium), const Spacer(), Container(padding: const EdgeInsets.symmetric(horizontal:8, vertical:4), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(99)), child: Text(s.status.name.toUpperCase(), style: const TextStyle(fontSize:11)))]),
      const SizedBox(height:4),
      const Text('Optional. Local-first. Works fully offline; syncs graph + assets when online.', style: TextStyle(fontSize:11, color: Colors.white54)),
      const SizedBox(height:12),
      SwitchListTile(value: s.enabled, onChanged: n.setEnabled, title: const Text('Enable sync', style: TextStyle(fontSize:13)), dense:true, contentPadding: EdgeInsets.zero),
      const SizedBox(height:8),
      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withValues(alpha:0.06), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
          Row(children:[const Icon(Icons.schedule, size:14, color: Colors.white54), const SizedBox(width:6), Text('Last sync: ${s.lastSync}', style: const TextStyle(fontSize:12, color: Colors.white70)), const Spacer(), Text('${s.pendingOps} pending', style: const TextStyle(fontSize:11, color: Colors.white54))]),
          const SizedBox(height:8),
          if(s.status==SyncStatus.syncing) LinearProgressIndicator(value: s.progress),
          const SizedBox(height:8),
          Row(children:[
            FilledButton.icon(onPressed: !s.enabled || s.status==SyncStatus.syncing? null : n.syncNow, icon: const Icon(Icons.sync, size:16), label: const Text('Sync now')),
            const SizedBox(width:8),
            OutlinedButton(onPressed: ()=> ref.read(syncProvider.notifier).reset(), child: const Text('Reset')),
          ]),
        ])),
      const SizedBox(height:8),
      const Text('Moat = asset graph + non-destructive pipeline + sync backbone + orchestration.', style: TextStyle(fontSize:11, color: Colors.white54)),
    ]);
  }
}
