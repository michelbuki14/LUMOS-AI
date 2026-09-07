import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Scene type classification
enum SceneType {
  landscape('Landscape'),
  portrait('Portrait'),
  street('Street'),
  night('Night'),
  sunset('Sunset'),
  sunrise('Sunrise'),
  wildlife('Wildlife'),
  sports('Sports'),
  food('Food'),
  product('Product'),
  realEstate('Real Estate'),
  streetPhotography('Street Photography'),
  architecture('Architecture'),
  macro('Macro'),
  underwater('Underwater'),
  abstract('Abstract');

  const SceneType(this.label);
  final String label;
}

extension SceneTypeExtension on SceneType {
  String get description {
    switch (this) {
      case SceneType.landscape: return 'Wide angle views, natural scenes';
      case SceneType.portrait: return 'People, faces, individual subjects';
      case SceneType.street: return 'Urban environments, people in context';
      case SceneType.night: return 'Low light, astrophotography, city lights';
      case SceneType.sunset: return 'Golden hour, warm colors';
      case SceneType.sunrise: return 'Blue hour, cool colors';
      case SceneType.wildlife: return 'Animals, nature, birds';
      case SceneType.sports: return 'Action, movement, athletes';
      case SceneType.food: return 'Meals, dishes, cuisine';
      case SceneType.product: return 'Items, merchandise, objects';
      case SceneType.realEstate: return 'Homes, interiors, exteriors';
      case SceneType.streetPhotography: return 'Candid, urban life, moments';
      case SceneType.architecture: return 'Buildings, structures, forms';
      case SceneType.macro: return 'Close-up, details, small objects';
      case SceneType.underwater: return 'Water photography, marine';
      case SceneType.abstract: return 'Conceptual, minimal, artistic';
    }
  }
}

/// Scene analysis result
class SceneAnalysisResult {
  final SceneType primaryType;
  final double confidence;
  final List<SceneType> secondaryTypes;
  final Map<String, double> attributeScores;
  final bool hasPeople;
  final bool hasSky;
  final bool hasText;

  SceneAnalysisResult({
    required this.primaryType,
    required this.confidence,
    this.secondaryTypes = const [],
    Map<String, double>? attributeScores,
    this.hasPeople = false,
    this.hasSky = false,
    this.hasText = false,
  }) : attributeScores = attributeScores ?? {
          'brightness': 0.5,
          'contrast': 0.4,
          'sharpness': 0.6,
        };
}

/// Scene analysis state provider
final sceneAnalysisStateProvider = StateNotifierProvider<SceneAnalysisNotifier, SceneAnalysisState>((ref) {
  return SceneAnalysisNotifier();
});

class SceneAnalysisState {
  final SceneAnalysisResult? result;
  final bool isAnalyzing;
  final double analysisProgress;

  const SceneAnalysisState({
    this.result,
    this.isAnalyzing = false,
    this.analysisProgress = 0.0,
  });

  SceneAnalysisState copyWith({
    SceneAnalysisResult? result,
    bool? isAnalyzing,
    double? analysisProgress,
  }) {
    return SceneAnalysisState(
      result: result ?? this.result,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      analysisProgress: analysisProgress ?? this.analysisProgress,
    );
  }
}

class SceneAnalysisNotifier extends StateNotifier<SceneAnalysisState> {
  SceneAnalysisNotifier() : super(const SceneAnalysisState());

  /// Analyze a scene from image bytes
  Future<void> analyzeScene(List<int> imageData) async {
    state = state.copyWith(isAnalyzing: true, analysisProgress: 0.0);

    // Simulate progressive analysis
    for (int i = 0; i < 10; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      state = state.copyWith(
        analysisProgress: (i + 1) / 10 * 100.0,
      );
    }

    // Production: ViT classifier via ONNX; deterministic mock for demo/offline
    final primaryIndex = DateTime.now().millisecond % SceneType.values.length;
    final primary = SceneType.values[primaryIndex];
    final secondary = List.generate(
        2, (_) => SceneType.values[(DateTime.now().millisecond + 1) % SceneType.values.length]);

    final result = SceneAnalysisResult(
      primaryType: primary,
      confidence: 0.85 + (DateTime.now().millisecond % 10) / 100,
      secondaryTypes: secondary.where((t) => t != primary).toList(),
      attributeScores: {
        'brightness': 0.5 + (DateTime.now().millisecond % 50) / 100,
        'contrast': 0.4 + (DateTime.now().millisecond % 40) / 100,
        'sharpness': 0.6 + (DateTime.now().millisecond % 30) / 100,
      },
      hasPeople: DateTime.now().millisecond % 5 == 0,
      hasSky: true,
      hasText: false,
    );

    state = state.copyWith(
      result: result,
      isAnalyzing: false,
      analysisProgress: 100.0,
    );
  }
}