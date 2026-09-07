import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';
import 'dart:math';

/// Object detection result
/// Uses List&lt;int&gt; instead of TypedList for Dart compatibility
class ObjectDetectionResult {
  final String label; // e.g. 'person', 'dust', 'wire'
  final double confidence;
  final double offsetD; // top-left corner
  final double sizeW;    // width
  final double sizeH;    // height
  final bool isSelected; // user selection state

  const ObjectDetectionResult({
    required this.label,
    required this.confidence,
    required this.offsetD,
    required this.sizeW,
    required this.sizeH,
    this.isSelected = false,
  });
}

/// Supported object types for removal
enum ObjectType {
  person('Person', Icons.person),
  dust('Dust', Icons.delete),
  wire('Wire', Icons.remove),
  reflection('Reflection', Icons.remove),
  powerLine('Power Line', Icons.remove),
  trash('Trash', Icons.delete),
  sign('Sign', Icons.info),
  vehicle('Vehicle', Icons.directions_car);

  const ObjectType(this.label, this.icon);
  final String label;
  final IconData icon;
}

extension ObjectTypeExtension on ObjectType {
  String get description {
    switch (this) {
      case ObjectType.person: return 'Remove people from images';
      case ObjectType.dust: return 'Remove dust spots and scratches';
      case ObjectType.wire: return 'Remove power lines and wires';
      case ObjectType.reflection: return 'Remove reflections and glare';
      case ObjectType.powerLine: return 'Remove power lines';
      case ObjectType.trash: return 'Remove trash and debris';
      case ObjectType.sign: return 'Remove signs and billboards';
      case ObjectType.vehicle: return 'Remove vehicles and cars';
    }
  }
}

/// Object removal state provider
final objectRemovalStateProvider = StateNotifierProvider<ObjectRemovalNotifier, ObjectRemovalState>((ref) {
  return ObjectRemovalNotifier();
});

class ObjectRemovalState {
  final List<ObjectDetectionResult> detections;
  final ObjectType? selectedType;
  final Uint8List? maskImage; // generated mask for editing
  final bool isProcessing;
  final double processingProgress;

  const ObjectRemovalState({
    this.detections = const [],
    this.selectedType,
    this.maskImage,
    this.isProcessing = false,
    this.processingProgress = 0.0,
  });

  ObjectRemovalState copyWith({
    List<ObjectDetectionResult>? detections,
    ObjectType? selectedType,
    Uint8List? maskImage,
    bool? isProcessing,
    double? processingProgress,
  }) {
    return ObjectRemovalState(
      detections: detections ?? this.detections,
      selectedType: selectedType ?? this.selectedType,
      maskImage: maskImage ?? this.maskImage,
      isProcessing: isProcessing ?? this.isProcessing,
      processingProgress: processingProgress ?? this.processingProgress,
    );
  }
}

class ObjectRemovalNotifier extends StateNotifier<ObjectRemovalState> {
  ObjectRemovalNotifier() : super(const ObjectRemovalState());

  /// Load object detection results from API or model
  Future<void> loadDetections(List<int> rawData) async {
    // Parse detection results from model output
    // This would connect to the AI service's object detection endpoint
    state = state.copyWith(
      isProcessing: false,
    );
  }

  /// Select an object type for removal
  void selectObjectType(ObjectType type) {
    state = state.copyWith(selectedType: type);
  }

  /// Start object removal processing
  Future<void> removeObject(ObjectDetectionResult detection) async {
    if (state.selectedType == null) return;

    state = state.copyWith(isProcessing: true, processingProgress: 0.0);

    // Simulate processing
    await Future.delayed(const Duration(seconds: 2));

    // Generate mask and composited result
    state = state.copyWith(
      maskImage: _generateMockMask(detection.sizeW, detection.sizeH),
      isProcessing: false,
      processingProgress: 1.0,
    );
  }

  /// Generate a mock mask for demonstration
  Uint8List _generateMockMask(double width, double height) {
    // In production: use SAM or mask prediction model
    // Production: SAM mask from ONNX; fallback gradient for demo/offline
    final w = width.toInt();
    final h = height.toInt();
    final bytes = Uint8List(w * h * 4);

    for (int i = 0; i < w * h; i++) {
      // Simple radial gradient mask
      final x = (i % w).toDouble();
      final y = (i ~/ w).toDouble();
      final dx = x - w / 2;
      final dy = y - h / 2;
      final distance = sqrt(dx * dx + dy * dy) / (w / 2);
      final alpha = (1.0 - distance).clamp(0.0, 1.0);
      final baseIndex = i * 4;
      bytes[baseIndex + 3] = (alpha * 255).toInt(); // alpha channel
      // Keep RGB as transparent black
      bytes[baseIndex] = 0; // R
      bytes[baseIndex + 1] = 0; // G
      bytes[baseIndex + 2] = 0; // B
    }

    return bytes;
  }

  /// Remove selected objects from image
  Future<void> processRemoval() async {
    if (state.selectedType == null || state.detections.isEmpty) return;

    state = state.copyWith(isProcessing: true, processingProgress: 0.1);

    // Process each detected object
    for (var i = 0; i < state.detections.length; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      state = state.copyWith(
        processingProgress: 0.1 + (i + 1) / state.detections.length * 0.8,
      );
    }

    // Finalize removal
    state = state.copyWith(
      isProcessing: false,
      processingProgress: 1.0,
    );
  }
}