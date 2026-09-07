import 'package:flutter/material.dart';

enum CullingStatus { pick, reject, unflagged }

enum CullingFlag {
  blurry('Blurry', Icons.blur_on),
  closedEyes('Closed Eyes', Icons.visibility_off),
  duplicate('Duplicate', Icons.filter_vintage),
  exposure('Exposure', Icons.exposure),
  composition('Composition', Icons.camera_alt);

  const CullingFlag(this.label, this.icon);
  final String label;
  final IconData icon;
}

class CullingImage {
  final String id;
  final String path;
  final String thumbnailPath;
  final int starRating;
  final CullingStatus status;
  final List<CullingFlag> flags;
  final AiScore? score;

  CullingImage({
    required this.id,
    required this.path,
    required this.thumbnailPath,
    this.starRating = 0,
    this.status = CullingStatus.unflagged,
    this.flags = const [],
    this.score,
  });
}

class AiScore {
  final double overall;
  final double focus;
  final double exposure;
  final double composition;

  AiScore({
    required this.overall,
    required this.focus,
    required this.exposure,
    required this.composition,
  });
}

enum ViewMode { grid, compare, detail }
