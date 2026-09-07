import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Module 6 — Vertical Packs (Wedding / Real Estate / Product / etc)
/// Phase 0 ships core only; verticals are presets + ops, not separate apps.
/// Each vertical = curated adjustment graph + batch template + gallery theme.

enum Vertical { wedding, portrait, realEstate, product, food, sports, wildlife }

extension VerticalX on Vertical {
  String get label => switch(this){
    Vertical.wedding => 'Wedding',
    Vertical.portrait => 'Portrait',
    Vertical.realEstate => 'Real Estate',
    Vertical.product => 'Product',
    Vertical.food => 'Food',
    Vertical.sports => 'Sports',
    Vertical.wildlife => 'Wildlife',
  };
  IconData get icon => switch(this){
    Vertical.wedding => Icons.favorite_border,
    Vertical.portrait => Icons.face_retouching_natural,
    Vertical.realEstate => Icons.home_work_outlined,
    Vertical.product => Icons.shopping_bag_outlined,
    Vertical.food => Icons.restaurant,
    Vertical.sports => Icons.sports_soccer,
    Vertical.wildlife => Icons.pets,
  };
  String get blurb => switch(this){
    Vertical.wedding => 'Culling → skin → batch 800 imgs → gallery. ~\$1.05/compute per wedding.',
    Vertical.portrait => 'Face parse → skin/eyes/teeth/hair. Non-destructive layers.',
    Vertical.realEstate => 'Perspective + window pull + sky replace. MLS export.',
    Vertical.product => 'Shadow + reflection + Amazon/Shopify export.',
    Vertical.food => 'Color keep + shine remove.',
    Vertical.sports => 'Action detect + motion grade.',
    Vertical.wildlife => 'Animal detect + species tag.',
  };
  List<String> get presets => switch(this){
    Vertical.wedding => ['Soft & Warm', 'True to Tone', 'B&W Editorial', 'Golden Hour'],
    Vertical.portrait => ['Natural Skin', 'Editorial', 'High Key', 'Dramatic'],
    Vertical.realEstate => ['Bright & Airy', 'Twilight Pull', 'HDR Balanced'],
    Vertical.product => ['Pure White', 'Shadow Soft', 'Reflection Clean'],
    Vertical.food => ['Fresh', 'Warm & Cozy', 'High Contrast'],
    Vertical.sports => ['Vibrant Action', 'Stadium Light', 'Freeze Frame'],
    Vertical.wildlife => ['Natural', 'Feather Detail', 'Safari Warm'],
  };
}

final verticalProvider = StateProvider<Vertical>((_)=> Vertical.portrait);
final verticalPresetProvider = StateProvider<String?>((_)=> null);

class VerticalPacksPanel extends ConsumerWidget{
  const VerticalPacksPanel({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref){
    final v = ref.watch(verticalProvider);
    final preset = ref.watch(verticalPresetProvider);
    return ListView(padding: const EdgeInsets.all(16), children:[
      Text('Vertical Packs', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height:4),
      const Text('Phase 0 = core. Verticals = presets on the same engine.', style: TextStyle(fontSize:11, color: Colors.white54)),
      const SizedBox(height:12),
      Wrap(spacing:8, runSpacing:8, children: Vertical.values.map((e)=> ChoiceChip(
        avatar: Icon(e.icon, size:14), label: Text(e.label, style: const TextStyle(fontSize:12)),
        selected: v==e, onSelected: (_){ ref.read(verticalProvider.notifier).state=e; ref.read(verticalPresetProvider.notifier).state=null; },
      )).toList()),
      const SizedBox(height:16),
      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withValues(alpha:0.06), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
          Row(children:[Icon(v.icon, size:16, color: Colors.white70), const SizedBox(width:6), Text(v.label, style: const TextStyle(fontWeight: FontWeight.w600)), const Spacer(), Text(v.presets.length.toString(), style: const TextStyle(color: Colors.white54, fontSize:11))]),
          const SizedBox(height:6),
          Text(v.blurb, style: const TextStyle(color: Colors.white70, fontSize:12)),
          const SizedBox(height:12),
          Wrap(spacing:8, runSpacing:8, children: v.presets.map((p)=> ChoiceChip(label: Text(p, style: const TextStyle(fontSize:11)), selected: preset==p, onSelected: (_)=> ref.read(verticalPresetProvider.notifier).state=p)).toList()),
        ])),
      const SizedBox(height:12),
      Row(children:[
        FilledButton.icon(onPressed: preset==null? null : (){ ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Applied $preset → ${v.label}'))); }, icon: const Icon(Icons.auto_fix_high, size:16), label: const Text('Apply preset')),
        const SizedBox(width:8),
        OutlinedButton(onPressed: ()=> ref.read(verticalPresetProvider.notifier).state=null, child: const Text('Clear')),
      ]),
      const SizedBox(height:8),
      const Text('Monetize via value (time saved), not GPU seconds. Local-first; cloud optional.', style: TextStyle(fontSize:11, color: Colors.white54)),
    ]);
  }
}
