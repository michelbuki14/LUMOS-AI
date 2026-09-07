import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DodgeBurnState {
  final String mode;
  final double exposure;
  final double brushSize;
  final double flow;
  final bool opacity;

  const DodgeBurnState({
    this.mode = 'dodge',
    this.exposure = 0.3,
    this.brushSize = 100.0,
    this.flow = 0.5,
    this.opacity = true,
  });

  DodgeBurnState copyWith({
    String? mode,
    double? exposure,
    double? brushSize,
    double? flow,
    bool? opacity,
  }) {
    return DodgeBurnState(
      mode: mode ?? this.mode,
      exposure: exposure ?? this.exposure,
      brushSize: brushSize ?? this.brushSize,
      flow: flow ?? this.flow,
      opacity: opacity ?? this.opacity,
    );
  }
}

class DodgeBurnNotifier extends StateNotifier<DodgeBurnState> {
  DodgeBurnNotifier() : super(const DodgeBurnState());

  void setMode(String mode) => state = state.copyWith(mode: mode);
  void setExposure(double v) => state = state.copyWith(exposure: v);
  void setBrushSize(double v) => state = state.copyWith(brushSize: v);
  void setFlow(double v) => state = state.copyWith(flow: v);
  void toggleOpacity() => state = state.copyWith(opacity: !state.opacity);
}

final dodgeBurnProvider = StateNotifierProvider<DodgeBurnNotifier, DodgeBurnState>((ref) {
  return DodgeBurnNotifier();
});

class DodgeBurnPanel extends ConsumerWidget {
  const DodgeBurnPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dodgeBurnProvider);
    final notifier = ref.read(dodgeBurnProvider.notifier);

    return Container(
      color: const Color(0xFF1E1E1E),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _modeChip(context, 'Dodge', Icons.brightness_high, state.mode == 'dodge', () => notifier.setMode('dodge')),
                const SizedBox(width: 8),
                _modeChip(context, 'Burn', Icons.brightness_low, state.mode == 'burn', () => notifier.setMode('burn')),
                const SizedBox(width: 8),
                _modeChip(context, 'Sponge', Icons.format_paint, state.mode == 'sponge', () => notifier.setMode('sponge')),
                const SizedBox(width: 8),
                _modeChip(context, 'Midtones', Icons.widgets, state.mode == 'midtone', () => notifier.setMode('midtone')),
                const SizedBox(width: 8),
                _modeChip(context, 'Highlight', Icons.wb_sunny, state.mode == 'highlight', () => notifier.setMode('highlight')),
                const SizedBox(width: 8),
                _modeChip(context, 'Shadow', Icons.dark_mode, state.mode == 'shadow', () => notifier.setMode('shadow')),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF2C2C2C)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Exposure', style: TextStyle(color: const Color(0xFFB0B0B0), fontSize: 12)),
                    Text(state.exposure.toStringAsFixed(2), style: const TextStyle(color: Color(0xFF7C3AED), fontSize: 12)),
                  ],
                ),
                Slider(
                  value: state.exposure,
                  min: 0.0,
                  max: 1.0,
                  divisions: 100,
                  onChanged: (v) => notifier.setExposure(v),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Brush Size', style: TextStyle(color: const Color(0xFFB0B0B0), fontSize: 12)),
                    Text('${state.brushSize.toStringAsFixed(0)} px', style: const TextStyle(color: Color(0xFF7C3AED), fontSize: 12)),
                  ],
                ),
                Slider(
                  value: state.brushSize,
                  min: 10,
                  max: 500,
                  divisions: 49,
                  onChanged: (v) => notifier.setBrushSize(v),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Flow', style: TextStyle(color: const Color(0xFFB0B0B0), fontSize: 12)),
                    Text(state.flow.toStringAsFixed(2), style: const TextStyle(color: Color(0xFF7C3AED), fontSize: 12)),
                  ],
                ),
                Slider(
                  value: state.flow,
                  min: 0.0,
                  max: 1.0,
                  divisions: 100,
                  onChanged: (v) => notifier.setFlow(v),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF2C2C2C)),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: state.brushSize,
                    height: state.brushSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF7C3AED), width: 2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Brush: ${state.brushSize.toStringAsFixed(0)}px  Flow: ${(state.flow * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(color: Color(0xFF808080), fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFF2C2C2C)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Checkbox(
                  value: state.opacity,
                  onChanged: (_) => notifier.toggleOpacity(),
                  activeColor: const Color(0xFF7C3AED),
                ),
                const Text('Show Overlay', style: TextStyle(color: Color(0xFFB0B0B0), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeChip(BuildContext context, String label, IconData icon, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: selected ? const Color(0xFF7C3AED).withValues(alpha: 0.2) : const Color(0xFF2C2C2C),
          border: Border.all(
            color: selected ? const Color(0xFF7C3AED) : const Color(0xFF3C3C3C),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: selected ? const Color(0xFF7C3AED) : const Color(0xFFB0B0B0)),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 11, color: selected ? const Color(0xFF7C3AED) : const Color(0xFFB0B0B0))),
          ],
        ),
      ),
    );
  }
}
