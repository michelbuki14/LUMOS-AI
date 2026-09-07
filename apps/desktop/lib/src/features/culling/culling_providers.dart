import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'culling_models.dart';

class CullingState {
  final List<CullingImage> images;
  final bool isLoading;
  final String? error;
  final double aiProgress;
  final String? selectedImageId;
  final CullingFilter filter;

  const CullingState({
    this.images = const [],
    this.isLoading = false,
    this.error,
    this.aiProgress = 0.0,
    this.selectedImageId,
    this.filter = CullingFilter.all,
  });

  CullingState copyWith({
    List<CullingImage>? images,
    bool? isLoading,
    String? error,
    double? aiProgress,
    String? selectedImageId,
    CullingFilter? filter,
  }) {
    return CullingState(
      images: images ?? this.images,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      aiProgress: aiProgress ?? this.aiProgress,
      selectedImageId: selectedImageId ?? this.selectedImageId,
      filter: filter ?? this.filter,
    );
  }

  List<CullingImage> get filteredImages {
    switch (filter) {
      case CullingFilter.all:
        return images;
      case CullingFilter.picks:
        return images.where((img) => img.status == CullingStatus.pick).toList();
      case CullingFilter.rejects:
        return images.where((img) => img.status == CullingStatus.reject).toList();
      case CullingFilter.flagged:
        return images.where((img) => img.flags.isNotEmpty).toList();
    }
  }
}

enum CullingFilter { all, picks, rejects, flagged }

class CullingStateNotifier extends StateNotifier<CullingState> {
  CullingStateNotifier() : super(const CullingState());

  void loadImages(List<CullingImage> images) {
    state = state.copyWith(images: images, isLoading: false);
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void setError(String? error) {
    state = state.copyWith(error: error, isLoading: false);
  }

  void setAiProgress(double progress) {
    state = state.copyWith(aiProgress: progress);
  }

  void selectImage(String? imageId) {
    state = state.copyWith(selectedImageId: imageId);
  }

  void setFilter(CullingFilter filter) {
    state = state.copyWith(filter: filter);
  }

  void togglePick(CullingImage image) {
    final updated = state.images.map((img) {
      if (img.id == image.id) {
        return CullingImage(
          id: img.id,
          path: img.path,
          thumbnailPath: img.thumbnailPath,
          starRating: img.starRating,
          status: img.status == CullingStatus.pick
              ? CullingStatus.unflagged
              : CullingStatus.pick,
          flags: img.flags,
          score: img.score,
        );
      }
      return img;
    }).toList();
    state = state.copyWith(images: updated);
  }

  void toggleReject(CullingImage image) {
    final updated = state.images.map((img) {
      if (img.id == image.id) {
        return CullingImage(
          id: img.id,
          path: img.path,
          thumbnailPath: img.thumbnailPath,
          starRating: img.starRating,
          status: img.status == CullingStatus.reject
              ? CullingStatus.unflagged
              : CullingStatus.reject,
          flags: img.flags,
          score: img.score,
        );
      }
      return img;
    }).toList();
    state = state.copyWith(images: updated);
  }

  void runAiCulling() {
    state = state.copyWith(isLoading: true, aiProgress: 0.0);

    Future.delayed(const Duration(milliseconds: 50), () {
      for (var i = 0; i < state.images.length; i++) {
        final img = state.images[i];
        final newScore = AiScore(
          overall: 50.0 + (img.starRating * 5.0) + (img.status.index * 10.0),
          focus: 0.5 + (img.starRating * 0.05),
          exposure: 0.5 + (img.starRating * 0.04),
          composition: 0.5 + (img.starRating * 0.05),
        );
        final updated = state.images.map((img2) {
          if (img2.id == img.id) {
            return CullingImage(
              id: img2.id,
              path: img2.path,
              thumbnailPath: img2.thumbnailPath,
              starRating: img2.starRating,
              status: img2.status,
              flags: img2.flags,
              score: newScore,
            );
          }
          return img2;
        }).toList();
        state = state.copyWith(images: updated);
        state = state.copyWith(aiProgress: (i + 1) / state.images.length);
      }
      state = state.copyWith(isLoading: false, aiProgress: 1.0);
    });
  }
}

final cullingProvider = StateNotifierProvider<CullingStateNotifier, CullingState>((ref) {
  return CullingStateNotifier();
});
