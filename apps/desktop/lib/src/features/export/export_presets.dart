import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Module 7 — Export & Delivery presets (local-first, original preserved)
/// Covers: JPEG/PNG/TIFF/WebP/AVIF + social/print sizes + watermark + naming.

enum ExportFormat { jpeg, png, tiff, webp, avif, psd }
enum ExportSize { original, print4x6, print5x7, print8x10, a4, a5, instagram, story, tiktok, youtube }

extension ExportFormatX on ExportFormat {
  String get label => name.toUpperCase();
  String get ext => switch(this){
    ExportFormat.jpeg => 'jpg', ExportFormat.png => 'png', ExportFormat.tiff => 'tiff',
    ExportFormat.webp => 'webp', ExportFormat.avif => 'avif', ExportFormat.psd => 'psd',
  };
}
extension ExportSizeX on ExportSize {
  String get label => switch(this){
    ExportSize.original => 'Original', ExportSize.print4x6 => '4×6', ExportSize.print5x7 => '5×7',
    ExportSize.print8x10 => '8×10', ExportSize.a4 => 'A4', ExportSize.a5 => 'A5',
    ExportSize.instagram => 'IG 1080×1080', ExportSize.story => 'Story 1080×1920',
    ExportSize.tiktok => 'TikTok 1080×1920', ExportSize.youtube => 'YT 1920×1080',
  };
}

class ExportState {
  final ExportFormat format;
  final ExportSize size;
  final int quality; // 1..100
  final bool watermark;
  final String naming; // {date}_{seq}_{preset}
  final bool isExporting;
  final double progress;
  const ExportState({this.format=ExportFormat.jpeg, this.size=ExportSize.original, this.quality=92, this.watermark=false, this.naming='{date}_{seq}', this.isExporting=false, this.progress=0});
  ExportState copyWith({ExportFormat? format, ExportSize? size, int? quality, bool? watermark, String? naming, bool? isExporting, double? progress}) =>
    ExportState(format: format??this.format, size: size??this.size, quality: quality??this.quality, watermark: watermark??this.watermark, naming: naming??this.naming, isExporting: isExporting??this.isExporting, progress: progress??this.progress);
}
class ExportNotifier extends StateNotifier<ExportState>{
  ExportNotifier():super(const ExportState());
  void setFormat(ExportFormat f)=> state=state.copyWith(format:f);
  void setSize(ExportSize s)=> state=state.copyWith(size:s);
  void setQuality(int q)=> state=state.copyWith(quality:q);
  void setWatermark(bool v)=> state=state.copyWith(watermark:v);
  void setNaming(String v)=> state=state.copyWith(naming:v);
  Future<void> export() async{
    state=state.copyWith(isExporting:true, progress:0.1);
    await Future.delayed(const Duration(milliseconds:500));
    state=state.copyWith(progress:0.6);
    await Future.delayed(const Duration(milliseconds:600));
    // prod: POST /api/v1/export {format,size,quality,watermark,naming} via Rust LittleCMS/OpenColorIO
    state=state.copyWith(isExporting:false, progress:1);
  }
}
final exportProvider = StateNotifierProvider<ExportNotifier, ExportState>((_)=>ExportNotifier());

class ExportPresetsPanel extends ConsumerWidget{
  const ExportPresetsPanel({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref){
    final s=ref.watch(exportProvider);
    final n=ref.read(exportProvider.notifier);
    return ListView(padding: const EdgeInsets.all(16), children:[
      Text('Export & Delivery', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height:12),
      Text('Format', style: Theme.of(context).textTheme.labelMedium),
      const SizedBox(height:6),
      Wrap(spacing:6, runSpacing:6, children: ExportFormat.values.map((f)=> ChoiceChip(label: Text(f.label, style: const TextStyle(fontSize:11)), selected: s.format==f, onSelected: (_)=> n.setFormat(f))).toList()),
      const SizedBox(height:12),
      Text('Size', style: Theme.of(context).textTheme.labelMedium),
      const SizedBox(height:6),
      Wrap(spacing:6, runSpacing:6, children: ExportSize.values.map((e)=> ChoiceChip(label: Text(e.label, style: const TextStyle(fontSize:11)), selected: s.size==e, onSelected: (_)=> n.setSize(e))).toList()),
      const SizedBox(height:12),
      Text('Quality ${s.quality}', style: const TextStyle(fontSize:12)),
      Slider(value: s.quality.toDouble(), min: 1, max: 100, divisions: 99, label: s.quality.toString(), onChanged: (v)=> n.setQuality(v.round())),
      SwitchListTile(value: s.watermark, onChanged: n.setWatermark, title: const Text('Watermark', style: TextStyle(fontSize:13)), dense:true, contentPadding: EdgeInsets.zero),
      TextField(decoration: const InputDecoration(labelText: 'Naming', hintText: '{date}_{seq}_{preset}', isDense:true, border: OutlineInputBorder()), controller: TextEditingController(text: s.naming), onChanged: n.setNaming),
      const SizedBox(height:12),
      if(s.isExporting) LinearProgressIndicator(value: s.progress),
      const SizedBox(height:8),
      Row(children:[
        FilledButton.icon(onPressed: s.isExporting? null : n.export, icon: const Icon(Icons.upload, size:16), label: const Text('Export')),
        const SizedBox(width:8),
        OutlinedButton(onPressed: ()=> n.setQuality(92), child: const Text('Reset')),
      ]),
      const SizedBox(height:8),
      const Text('Color managed (LittleCMS + OpenColorIO). Original + .lumos graph preserved.', style: TextStyle(fontSize:11, color: Colors.white54)),
    ]);
  }
}
