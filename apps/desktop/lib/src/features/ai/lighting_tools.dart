import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Module 4 — AI Relight (local-first, non-destructive)
/// Simulates studio lighting via depth + normals. Cloud optional, local preview first.

enum LightPreset { softbox, butterfly, rembrandt, split, rim, clamshell, natural }

extension LightPresetX on LightPreset {
  String get label => switch(this){
    LightPreset.softbox => 'Softbox',
    LightPreset.butterfly => 'Butterfly',
    LightPreset.rembrandt => 'Rembrandt',
    LightPreset.split => 'Split',
    LightPreset.rim => 'Rim',
    LightPreset.clamshell => 'Clamshell',
    LightPreset.natural => 'Natural',
  };
}

class RelightState {
  final LightPreset preset;
  final double intensity; // 0..100
  final double direction; // 0..360
  final double softness;  // 0..100
  final double warmth;    // -100..100
  final bool isProcessing;
  final double progress;
  const RelightState({
    this.preset = LightPreset.softbox,
    this.intensity = 42,
    this.direction = 28,
    this.softness = 55,
    this.warmth = 0,
    this.isProcessing = false,
    this.progress = 0,
  });
  RelightState copyWith({LightPreset? preset, double? intensity, double? direction, double? softness, double? warmth, bool? isProcessing, double? progress}) =>
    RelightState(preset: preset??this.preset, intensity: intensity??this.intensity, direction: direction??this.direction, softness: softness??this.softness, warmth: warmth??this.warmth, isProcessing: isProcessing??this.isProcessing, progress: progress??this.progress);
}

class RelightNotifier extends StateNotifier<RelightState>{
  RelightNotifier():super(const RelightState());
  void setPreset(LightPreset p)=>state=state.copyWith(preset:p);
  void setIntensity(double v)=>state=state.copyWith(intensity:v);
  void setDirection(double v)=>state=state.copyWith(direction:v);
  void setSoftness(double v)=>state=state.copyWith(softness:v);
  void setWarmth(double v)=>state=state.copyWith(warmth:v);
  Future<void> apply() async{
    state=state.copyWith(isProcessing:true, progress:0.2);
    await Future.delayed(const Duration(milliseconds: 600));
    state=state.copyWith(progress:0.8);
    await Future.delayed(const Duration(milliseconds: 400));
    // prod: POST /api/v1/ai/relight {preset,intensity,direction,softness,warmth} -> LUT + depth composite
    state=state.copyWith(isProcessing:false, progress:1);
  }
  void reset()=>state=const RelightState();
}
final relightProvider = StateNotifierProvider<RelightNotifier, RelightState>((_)=>RelightNotifier());

class RelightPanel extends ConsumerWidget{
  const RelightPanel({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref){
    final s=ref.watch(relightProvider);
    final n=ref.read(relightProvider.notifier);
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text('AI Relight', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8, children: LightPreset.values.map((p)=> ChoiceChip(label: Text(p.label, style: const TextStyle(fontSize: 11)), selected: s.preset==p, onSelected: (_)=> n.setPreset(p))).toList()),
      const SizedBox(height: 16),
      _slider('Intensity', s.intensity, 0, 100, n.setIntensity),
      _slider('Direction', s.direction, 0, 360, n.setDirection),
      _slider('Softness', s.softness, 0, 100, n.setSoftness),
      _slider('Warmth', s.warmth, -100, 100, n.setWarmth),
      const SizedBox(height: 8),
      if(s.isProcessing) LinearProgressIndicator(value: s.progress),
      const SizedBox(height: 8),
      Row(children: [
        FilledButton.icon(onPressed: s.isProcessing?null:n.apply, icon: const Icon(Icons.lightbulb_outline, size:16), label: const Text('Apply')),
        const SizedBox(width:8),
        TextButton(onPressed: n.reset, child: const Text('Reset')),
      ]),
      const SizedBox(height:8),
      const Text('Depth-aware. Preview on GPU (wgpu). Original preserved.', style: TextStyle(fontSize:11, color: Colors.white54)),
    ]);
  }
  Widget _slider(String label, double value, double min, double max, ValueChanged<double> onChanged){
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
      Text('$label ${value.toInt()}', style: const TextStyle(fontSize:12)),
      Slider(value: value, min: min, max: max, onChanged: onChanged),
    ]);
  }
}
