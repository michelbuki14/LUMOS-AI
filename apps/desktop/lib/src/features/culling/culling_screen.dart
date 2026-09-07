import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Culling screen state
class CullingState {
  final List<CullImage> images;
  final List<CullImage> filteredImages;
  final CullFilter filter;
  final bool isProcessing;
  final String viewMode; // 'grid', 'compare', 'detail'
  final CullImage? selectedImage;
  final double threshold;

  const CullingState({
    this.images = const [],
    this.filteredImages = const [],
    this.filter = CullFilter.all,
    this.isProcessing = false,
    this.viewMode = 'grid',
    this.selectedImage,
    this.threshold = 50.0,
  });

  CullingState copyWith({
    List<CullImage>? images,
    List<CullImage>? filteredImages,
    CullFilter? filter,
    bool? isProcessing,
    String? viewMode,
    CullImage? selectedImage,
    double? threshold,
  }) {
    return CullingState(
      images: images ?? this.images,
      filteredImages: filteredImages ?? this.filteredImages,
      filter: filter ?? this.filter,
      isProcessing: isProcessing ?? this.isProcessing,
      viewMode: viewMode ?? this.viewMode,
      selectedImage: selectedImage ?? this.selectedImage,
      threshold: threshold ?? this.threshold,
    );
  }
}

enum CullFilter { all, pick, reject, unflagged }

class CullImage {
  final String id;
  final String thumbnailUrl;
  final double overallScore;
  final Map<String, double> scores;
  final List<String> flags;
  CullStatus status;

  CullImage({
    required this.id,
    required this.thumbnailUrl,
    required this.overallScore,
    required this.scores,
    required this.flags,
    this.status = CullStatus.unflagged,
  });
}

enum CullStatus { pick, reject, unflagged }

class CullingNotifier extends StateNotifier<CullingState> {
  CullingNotifier() : super(const CullingState());

  void loadImages() {
    state = state.copyWith(isProcessing: true);
    Future.delayed(const Duration(seconds: 1), () {
      final images = List.generate(100, (i) {
        final score = 30 + (i % 70).toDouble();
        return CullImage(
          id: 'cull_$i',
          thumbnailUrl: '',
          overallScore: score,
          scores: {
            'focus': score + (i % 10) - 5,
            'exposure': score + (i % 8) - 4,
            'composition': score + (i % 6) - 3,
            'technical': score + (i % 12) - 6,
            'subject': score + (i % 9) - 4,
          },
          flags: i % 10 == 0 ? ['blurry'] : (i % 15 == 0 ? ['eyes_closed'] : []),
        );
      });
      state = state.copyWith(images: images, filteredImages: images, isProcessing: false);
    });
  }

  void setFilter(CullFilter filter) {
    final filtered = switch (filter) {
      CullFilter.all => state.images,
      CullFilter.pick => state.images.where((i) => i.status == CullStatus.pick).toList(),
      CullFilter.reject => state.images.where((i) => i.status == CullStatus.reject).toList(),
      CullFilter.unflagged => state.images.where((i) => i.status == CullStatus.unflagged).toList(),
    };
    state = state.copyWith(filter: filter, filteredImages: filtered);
  }

  void rateImage(String id, CullStatus status) {
    final images = state.images.map((img) {
      if (img.id == id) img.status = status;
      return img;
    }).toList();
    state = state.copyWith(images: images);
    setFilter(state.filter);
  }

  void setViewMode(String mode) => state = state.copyWith(viewMode: mode);
  void selectImage(CullImage img) => state = state.copyWith(selectedImage: img);
  void setThreshold(double t) => state = state.copyWith(threshold: t);
}

final cullingProvider = StateNotifierProvider<CullingNotifier, CullingState>((ref) {
  return CullingNotifier();
});

class CullingScreen extends ConsumerWidget {
  const CullingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cullingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Culling'),
        actions: [
          IconButton(icon: const Icon(Icons.folder_open), onPressed: () => ref.read(cullingProvider.notifier).loadImages()),
          IconButton(icon: const Icon(Icons.auto_awesome), onPressed: () => ref.read(cullingProvider.notifier).loadImages()),
          IconButton(icon: const Icon(Icons.grid_view), onPressed: () => ref.read(cullingProvider.notifier).setViewMode('grid')),
          IconButton(icon: const Icon(Icons.compare), onPressed: () => ref.read(cullingProvider.notifier).setViewMode('compare')),
        ],
      ),
      body: Column(
        children: [
          // Filter bar
          Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                SegmentedButton<CullFilter>(
                  segments: const [
                    ButtonSegment(value: CullFilter.all, label: Text('All')),
                    ButtonSegment(value: CullFilter.pick, label: Text('Pick')),
                    ButtonSegment(value: CullFilter.reject, label: Text('Reject')),
                    ButtonSegment(value: CullFilter.unflagged, label: Text('Unflagged')),
                  ],
                  selected: {state.filter},
                  onSelectionChanged: (s) => ref.read(cullingProvider.notifier).setFilter(s.first),
                ),
                const Spacer(),
                Text('Threshold: ${state.threshold.toStringAsFixed(0)}'),
                Slider(value: state.threshold, min: 0, max: 100, onChanged: (v) => ref.read(cullingProvider.notifier).setThreshold(v)),
              ],
            ),
          ),
          // Main content
          Expanded(
            child: state.isProcessing
                ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Running AI Culling...')]))
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 200, mainAxisSpacing: 8, crossAxisSpacing: 8),
                    itemCount: state.filteredImages.length,
                    itemBuilder: (context, index) => _buildCullTile(context, ref, state.filteredImages[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCullTile(BuildContext context, WidgetRef ref, CullImage img) {
    return GestureDetector(
      onTap: () => ref.read(cullingProvider.notifier).selectImage(img),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: img.status == CullStatus.pick ? Colors.green : (img.status == CullStatus.reject ? Colors.red : Colors.transparent),
            width: 2,
          ),
          color: Colors.grey.shade900,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Icon(Icons.image, size: 40, color: Colors.grey.shade700),
            Positioned(top: 4, right: 4, child: Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), color: _scoreColor(img.overallScore)), child: Text(img.overallScore.toStringAsFixed(0), style: const TextStyle(color: Colors.white, fontSize: 10)))),
            if (img.flags.isNotEmpty) Positioned(bottom: 4, left: 4, child: Row(children: img.flags.map((f) => const Icon(Icons.warning, color: Colors.orange, size: 12)).toList())),
            Positioned(
              bottom: 4,
              right: 4,
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.thumb_up, color: Colors.green, size: 16), onPressed: () => ref.read(cullingProvider.notifier).rateImage(img.id, CullStatus.pick)),
                  IconButton(icon: const Icon(Icons.thumb_down, color: Colors.red, size: 16), onPressed: () => ref.read(cullingProvider.notifier).rateImage(img.id, CullStatus.reject)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _scoreColor(double s) => s >= 80 ? Colors.green : (s >= 60 ? Colors.orange : Colors.red);
}
