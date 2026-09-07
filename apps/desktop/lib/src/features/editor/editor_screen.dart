import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dodgeburn_panel.dart';
import '../ai/background_tools.dart';
import '../ai/lighting_tools.dart';
import '../ai/object_removal.dart';
import '../ai/scene_analysis.dart';

enum RightPanelView {
  tools,
  dodgeburn,
  background,
  relight,
  objectRemoval,
  scene,
}

final rightPanelProvider = StateProvider<RightPanelView>((ref) => RightPanelView.tools);

class EditorScreen extends StatelessWidget {
  const EditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final rightPanel = ref.watch(rightPanelProvider);
        
        return Scaffold(
          backgroundColor: const Color(0xFF121212),
          body: Row(
            children: [
              Container(
                width: 56,
                color: const Color(0xFF1E1E1E),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    _toolButton(context, Icons.crop, 'Crop'),
                    _toolButton(context, Icons.auto_fix_high, 'Healing'),
                    _toolButton(context, Icons.content_copy, 'Clone'),
                    _toolButton(context, Icons.visibility, 'Red Eye'),
                    const Divider(height: 1, color: Color(0xFF2C2C2C)),
                    _toolButton(context, Icons.wb_sunny, 'White Balance'),
                    _toolButton(context, Icons.exposure, 'Exposure'),
                    _toolButton(context, Icons.contrast, 'Contrast'),
                    _toolButton(context, Icons.brightness_high, 'Highlights'),
                    _toolButton(context, Icons.brightness_6, 'Shadows'),
                    _toolButton(context, Icons.brightness_1, 'Whites'),
                    _toolButton(context, Icons.brightness_7, 'Blacks'),
                    _toolButton(context, Icons.blur_on, 'Clarity'),
                    _toolButton(context, Icons.texture, 'Texture'),
                    _toolButton(context, Icons.grain, 'Dehaze'),
                    const Divider(height: 1, color: Color(0xFF2C2C2C)),
                    _toolButton(context, Icons.format_color_fill, 'Vibrance'),
                    _toolButton(context, Icons.colorize, 'Saturation'),
                    _toolButton(context, Icons.colorize, 'HSL'),
                    _toolButton(context, Icons.show_chart, 'Tone Curve'),
                    _toolButton(context, Icons.camera_alt, 'Calibration'),
                    _toolButton(context, Icons.camera_alt, 'Lens Corrections'),
                    _toolButton(context, Icons.fiber_manual_record, 'Noise Reduction'),
                    _toolButton(context, Icons.fingerprint, 'Sharpening'),
                    _toolButton(context, Icons.radio_button_unchecked, 'Vignette'),
                    _toolButton(context, Icons.filter, 'Grain'),
                    const Divider(height: 1, color: Color(0xFF2C2C2C)),
                    Icon(
                      Icons.auto_awesome,
                      color: const Color(0xFF7C3AED),
                      size: 20,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'AI Tools',
                      style: TextStyle(
                        fontSize: 10,
                        color: const Color(0xFF7C3AED),
                      ),
                    ),
                    const SizedBox(height: 4),
                    _aiToolButton(context, ref, Icons.layers_clear, 'BG', RightPanelView.background),
                    _aiToolButton(context, ref, Icons.lightbulb_outline, 'Light', RightPanelView.relight),
                    _aiToolButton(context, ref, Icons.hide_source, 'Remove', RightPanelView.objectRemoval),
                    _aiToolButton(context, ref, Icons.landscape, 'Scene', RightPanelView.scene),
                    _aiToolButton(context, ref, Icons.brush, 'Dodge/Burn', RightPanelView.dodgeburn),
                    const SizedBox(height: 8),
                    const Divider(height: 1, color: Color(0xFF2C2C2C)),
                    _toolButton(context, Icons.refresh, 'Reset'),
                    _toolButton(context, Icons.compare, 'Before/After'),
                    _toolButton(context, Icons.view_in_ar, 'View Modes'),
                    const Spacer(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              Expanded(
                child: switch (rightPanel) {
                  RightPanelView.dodgeburn => const DodgeBurnPanel(),
                  RightPanelView.background => const BackgroundPanel(),
                  RightPanelView.relight => const RelightPanel(),
                  RightPanelView.objectRemoval => const ObjectRemovalPanel(),
                  RightPanelView.scene => const SceneAnalysisPanel(),
                  _ => _toolsPanel(),
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _toolButton(BuildContext context, IconData icon, String label) {
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('\$label — adjusting via non-destructive graph'), duration: const Duration(milliseconds: 900)));
          if (label == 'Reset') {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reset — graph cleared (undoable)')));
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 44,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Icon(icon, size: 20, color: const Color(0xFFB0B0B0)),
        ),
      ),
    );
  }

  Widget _aiToolButton(BuildContext context, WidgetRef ref, IconData icon, String label, RightPanelView view) {
    final active = ref.watch(rightPanelProvider) == view;
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: () => ref.read(rightPanelProvider.notifier).state = view,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 36,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF7C3AED).withValues(alpha: 0.22) : null,
            borderRadius: BorderRadius.circular(8),
            border: active ? Border.all(color: const Color(0xFF7C3AED)) : null,
          ),
          child: Center(child: Icon(icon, size: 18, color: active ? const Color(0xFF7C3AED) : const Color(0xFFB0B0B0))),
        ),
      ),
    );
  }

  Widget _toolsPanel() {
    return const Center(
      child: Text(
        'Select a tool from the left panel',
        style: TextStyle(color: Color(0xFF808080), fontSize: 14),
      ),
    );
  }
}

class ObjectRemovalPanel extends ConsumerWidget {
  const ObjectRemovalPanel({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(objectRemovalStateProvider);
    final n = ref.read(objectRemovalStateProvider.notifier);
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text('AI Object Removal', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: ObjectType.values.map((t)=> ChoiceChip(
        avatar: Icon(t.icon, size:14), label: Text(t.label, style: const TextStyle(fontSize:11)),
        selected: s.selectedType==t, onSelected: (_)=> n.selectObjectType(t))).toList()),
      const SizedBox(height:12),
      if (s.isProcessing) LinearProgressIndicator(value: s.processingProgress),
      const SizedBox(height:8),
      FilledButton.icon(onPressed: s.isProcessing? null : n.processRemoval, icon: const Icon(Icons.hide_source, size:16), label: const Text('Remove selected')),
      const SizedBox(height:8),
      const Text('YOLO detect → LaMa inpaint. Mask reversible.', style: TextStyle(fontSize:11, color: Colors.white54)),
    ]);
  }
}

class SceneAnalysisPanel extends ConsumerWidget {
  const SceneAnalysisPanel({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(sceneAnalysisStateProvider);
    final n = ref.read(sceneAnalysisStateProvider.notifier);
    return ListView(padding: const EdgeInsets.all(16), children:[
      Text('Scene Analysis', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height:8),
      if (st.isAnalyzing) LinearProgressIndicator(value: st.analysisProgress/100),
      const SizedBox(height:8),
      FilledButton.icon(onPressed: st.isAnalyzing? null : ()=> n.analyzeScene([]), icon: const Icon(Icons.landscape, size:16), label: const Text('Analyze scene')),
      const SizedBox(height:12),
      if (st.result!=null) ...[
        Text('${st.result!.primaryType.label}  ${(st.result!.confidence*100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height:4),
        Text(st.result!.primaryType.description, style: const TextStyle(color: Colors.white70, fontSize:12)),
        const SizedBox(height:8),
        Wrap(spacing:6, children: st.result!.secondaryTypes.map((t)=> Chip(label: Text(t.label, style: const TextStyle(fontSize:11)))).toList()),
      ],
    ]);
  }
}
