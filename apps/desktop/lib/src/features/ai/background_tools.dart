import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Module 3 — AI Background (remove / replace / generate)
/// Non-destructive: stores mask + bg choice in adjustment graph, reversible.

enum BackgroundMode { remove, replaceColor, replaceImage, generate, blur }

extension BackgroundModeX on BackgroundMode {
  String get label {
    switch (this) {
      case BackgroundMode.remove: return 'Remove';
      case BackgroundMode.replaceColor: return 'Color';
      case BackgroundMode.replaceImage: return 'Image';
      case BackgroundMode.generate: return 'Generate';
      case BackgroundMode.blur: return 'Blur';
    }
  }
  IconData get icon {
    switch (this) {
      case BackgroundMode.remove: return Icons.layers_clear;
      case BackgroundMode.replaceColor: return Icons.palette_outlined;
      case BackgroundMode.replaceImage: return Icons.image_outlined;
      case BackgroundMode.generate: return Icons.auto_awesome;
      case BackgroundMode.blur: return Icons.blur_on;
    }
  }
}

class BackgroundState {
  final BackgroundMode mode;
  final Color bgColor;
  final String? bgImagePath;
  final String prompt;
  final double blurAmount; // 0..100
  final double edgeFeather; // 0..100
  final bool isProcessing;
  final double progress; // 0..1

  const BackgroundState({
    this.mode = BackgroundMode.remove,
    this.bgColor = const Color(0xFFE8E8E8),
    this.bgImagePath,
    this.prompt = '',
    this.blurAmount = 24,
    this.edgeFeather = 12,
    this.isProcessing = false,
    this.progress = 0,
  });

  BackgroundState copyWith({
    BackgroundMode? mode,
    Color? bgColor,
    String? bgImagePath,
    String? prompt,
    double? blurAmount,
    double? edgeFeather,
    bool? isProcessing,
    double? progress,
  }) => BackgroundState(
    mode: mode ?? this.mode,
    bgColor: bgColor ?? this.bgColor,
    bgImagePath: bgImagePath ?? this.bgImagePath,
    prompt: prompt ?? this.prompt,
    blurAmount: blurAmount ?? this.blurAmount,
    edgeFeather: edgeFeather ?? this.edgeFeather,
    isProcessing: isProcessing ?? this.isProcessing,
    progress: progress ?? this.progress,
  );
}

class BackgroundNotifier extends StateNotifier<BackgroundState> {
  BackgroundNotifier() : super(const BackgroundState());
  void setMode(BackgroundMode m) => state = state.copyWith(mode: m);
  void setColor(Color c) => state = state.copyWith(bgColor: c);
  void setPrompt(String p) => state = state.copyWith(prompt: p);
  void setBlur(double v) => state = state.copyWith(blurAmount: v);
  void setFeather(double v) => state = state.copyWith(edgeFeather: v);
  void setImagePath(String? p) => state = BackgroundState(
    mode: state.mode, bgColor: state.bgColor, bgImagePath: p, prompt: state.prompt,
    blurAmount: state.blurAmount, edgeFeather: state.edgeFeather,
    isProcessing: state.isProcessing, progress: state.progress,
  );

  Future<void> apply() async {
    state = state.copyWith(isProcessing: true, progress: 0.15);
    await Future.delayed(const Duration(milliseconds: 400));
    state = state.copyWith(progress: 0.6);
    await Future.delayed(const Duration(milliseconds: 500));
    // In prod: call POST /api/v1/ai/background {mode, prompt, bgColor, blur, feather} -> mask + composite
    state = state.copyWith(isProcessing: false, progress: 1);
  }
  void reset() => state = const BackgroundState();
}

final backgroundProvider = StateNotifierProvider<BackgroundNotifier, BackgroundState>((_) => BackgroundNotifier());

class BackgroundPanel extends ConsumerWidget {
  const BackgroundPanel({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(backgroundProvider);
    final n = ref.read(backgroundProvider.notifier);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Background AI', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        SegmentedButton<BackgroundMode>(
          segments: BackgroundMode.values.map((m) => ButtonSegment(value: m, icon: Icon(m.icon, size: 16), label: Text(m.label, style: const TextStyle(fontSize: 11)))).toList(),
          selected: {s.mode},
          onSelectionChanged: (v) => n.setMode(v.first),
        ),
        const SizedBox(height: 16),
        if (s.mode == BackgroundMode.replaceColor)
          Row(children: [
            const Text('Color  '),
            GestureDetector(
              onTap: () async {
                // simple color picker stub — cycles presets
                final presets = [Colors.white, const Color(0xFFE8E8E8), const Color(0xFF1A1A1A), const Color(0xFF4A90D9), const Color(0xFFD9A441)];
                final idx = presets.indexOf(s.bgColor);
                n.setColor(presets[(idx + 1) % presets.length]);
              },
              child: Container(width: 36, height: 36, decoration: BoxDecoration(color: s.bgColor, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white24))),
            ),
            const SizedBox(width: 8),
            Text('#${s.bgColor.toARGB32().toRadixString(16).padLeft(8,'0').toUpperCase()}', style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ]),
        if (s.mode == BackgroundMode.replaceImage)
          OutlinedButton.icon(onPressed: () => n.setImagePath('/tmp/bg.jpg'), icon: const Icon(Icons.upload, size: 16), label: Text(s.bgImagePath ?? 'Choose image')),
        if (s.mode == BackgroundMode.generate)
          TextField(
            decoration: const InputDecoration(hintText: 'Describe background… e.g. soft studio grey seamless', border: OutlineInputBorder(), isDense: true),
            onChanged: n.setPrompt,
          ),
        if (s.mode == BackgroundMode.blur) ...[
          const SizedBox(height: 8),
          Text('Blur ${s.blurAmount.toInt()}', style: const TextStyle(fontSize: 12)),
          Slider(value: s.blurAmount, min: 0, max: 100, onChanged: n.setBlur),
        ],
        const SizedBox(height: 8),
        Text('Feather ${s.edgeFeather.toInt()}', style: const TextStyle(fontSize: 12)),
        Slider(value: s.edgeFeather, min: 0, max: 64, onChanged: n.setFeather),
        const SizedBox(height: 12),
        if (s.isProcessing) LinearProgressIndicator(value: s.progress),
        const SizedBox(height: 8),
        Row(children: [
          FilledButton.icon(onPressed: s.isProcessing ? null : n.apply, icon: const Icon(Icons.auto_awesome, size: 16), label: const Text('Apply')),
          const SizedBox(width: 8),
          TextButton(onPressed: n.reset, child: const Text('Reset')),
        ]),
        const SizedBox(height: 8),
        const Text('Non-destructive. Stored as mask + params. Reversible via history.', style: TextStyle(fontSize: 11, color: Colors.white54)),
      ],
    );
  }
}
