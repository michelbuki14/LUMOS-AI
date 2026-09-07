import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Module 5 — Tethering (Phase 7)
/// PTP/USB capture → live view → auto-import → cull → edit graph.
/// Works offline; camera SDK abstraction so we can swap gphoto2 / vendor SDK later.

enum TetherStatus { disconnected, connecting, live, capturing, error }

class TetherState {
  final TetherStatus status;
  final String? cameraModel;
  final String? error;
  final bool autoImport;
  final bool autoCulling;
  final int sessionCount;
  final double liveFps;
  const TetherState({
    this.status = TetherStatus.disconnected,
    this.cameraModel,
    this.error,
    this.autoImport = true,
    this.autoCulling = true,
    this.sessionCount = 0,
    this.liveFps = 0,
  });
  TetherState copyWith({TetherStatus? status, String? cameraModel, String? error, bool? autoImport, bool? autoCulling, int? sessionCount, double? liveFps}) =>
    TetherState(status: status??this.status, cameraModel: cameraModel??this.cameraModel, error: error, autoImport: autoImport??this.autoImport, autoCulling: autoCulling??this.autoCulling, sessionCount: sessionCount??this.sessionCount, liveFps: liveFps??this.liveFps);
}

class TetherNotifier extends StateNotifier<TetherState>{
  TetherNotifier():super(const TetherState());
  Future<void> connect() async{
    state=state.copyWith(status: TetherStatus.connecting, error: null);
    await Future.delayed(const Duration(milliseconds: 800));
    // prod: enumerate PTP devices via libgphoto2 / Canon EDSDK
    final hasCamera = false; // local-first: no camera required to run UI
    if(!hasCamera){
      state=state.copyWith(status: TetherStatus.error, error: 'No camera detected. Connect via USB and set to PTP mode.');
      return;
    }
    state=state.copyWith(status: TetherStatus.live, cameraModel: 'Canon EOS R5', liveFps: 24);
  }
  void disconnect()=> state=const TetherState();
  Future<void> capture() async{
    if(state.status!=TetherStatus.live) return;
    state=state.copyWith(status: TetherStatus.capturing);
    await Future.delayed(const Duration(milliseconds: 350));
    // prod: trigger shutter -> download RAW -> write to catalog -> emit WS event
    state=state.copyWith(status: TetherStatus.live, sessionCount: state.sessionCount+1);
  }
  void toggleAutoImport(bool v)=> state=state.copyWith(autoImport: v);
  void toggleAutoCulling(bool v)=> state=state.copyWith(autoCulling: v);
}
final tetherProvider = StateNotifierProvider<TetherNotifier, TetherState>((_)=>TetherNotifier());

class TetherPanel extends ConsumerWidget{
  const TetherPanel({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref){
    final s=ref.watch(tetherProvider);
    final n=ref.read(tetherProvider.notifier);
    return ListView(padding: const EdgeInsets.all(16), children: [
      Row(children:[
        Icon(s.status==TetherStatus.live? Icons.videocam : Icons.videocam_off, size: 18, color: s.status==TetherStatus.live? Colors.greenAccent : Colors.white54),
        const SizedBox(width:8),
        Text('Tethering', style: Theme.of(context).textTheme.titleMedium),
        const Spacer(),
        Container(padding: const EdgeInsets.symmetric(horizontal:8, vertical:4), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(99)), child: Text(s.status.name.toUpperCase(), style: const TextStyle(fontSize:11))),
      ]),
      const SizedBox(height:12),
      Container(height: 168, decoration: BoxDecoration(color: const Color(0xFF0F0F0F), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
        child: Center(child: Column(mainAxisSize: MainAxisSize.min, children:[
          Icon(s.status==TetherStatus.live? Icons.center_focus_strong : Icons.camera_alt_outlined, size: 36, color: Colors.white24),
          const SizedBox(height:8),
          Text(s.cameraModel ?? (s.status==TetherStatus.live?'Live View ${s.liveFps.toInt()} fps':'No camera'), style: const TextStyle(color: Colors.white60, fontSize:12)),
          if(s.error!=null) Padding(padding: const EdgeInsets.all(12), child: Text(s.error!, style: const TextStyle(color: Colors.orangeAccent, fontSize:11), textAlign: TextAlign.center)),
        ])),
      ),
      const SizedBox(height:12),
      Row(children:[
        FilledButton.icon(onPressed: s.status==TetherStatus.connecting? null : (s.status==TetherStatus.disconnected || s.status==TetherStatus.error ? n.connect : n.capture),
          icon: Icon(s.status==TetherStatus.live? Icons.camera : Icons.link, size:16), label: Text(s.status==TetherStatus.live? 'Capture  (Space)' : 'Connect')),
        const SizedBox(width:8),
        OutlinedButton(onPressed: s.status==TetherStatus.disconnected? null : n.disconnect, child: const Text('Disconnect')),
        const Spacer(),
        Text('${s.sessionCount} shot${s.sessionCount==1?'':'s'}', style: const TextStyle(color: Colors.white54, fontSize:12)),
      ]),
      const SizedBox(height:12),
      SwitchListTile(value: s.autoImport, onChanged: n.toggleAutoImport, title: const Text('Auto-import to catalog', style: TextStyle(fontSize:13)), dense: true),
      SwitchListTile(value: s.autoCulling, onChanged: n.toggleAutoCulling, title: const Text('Auto-cull on import', style: TextStyle(fontSize:13)), dense: true),
      const SizedBox(height:8),
      const Text('USB PTP. RAW + JPEG. Offline-capable session folder. Triggers catalog ingest.', style: TextStyle(fontSize:11, color: Colors.white54)),
    ]);
  }
}
