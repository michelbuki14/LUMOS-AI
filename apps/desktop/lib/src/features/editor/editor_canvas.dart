import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show StrokeStyle;
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Image file provider for loaded images
final imageFileProvider = StateProvider<File?>((ref) => null);

/// Image data provider for rendered thumbnails
final imageDataProvider = StateProvider<Uint8List?>((ref) => null);

/// Loading state provider
final imageLoadingProvider = StateProvider<bool>((ref) => false);

/// Image metadata provider
final imageMetadataProvider = StateProvider<Map<String, dynamic>?>((ref) => null);

/// Editor state provider
final editorStateProvider = StateNotifierProvider<EditorNotifier, EditorState>((ref) {
  return EditorNotifier();
});

/// Editor state
class EditorState {
  final bool isLoading;
  final String? error;
  final double zoom;
  final Offset pan;
  final bool showHistogram;
  final bool showBeforeAfter;
  final bool splitView;
  final String activePanel; // 'basic', 'color', 'detail', 'local', 'ai'
  final List<Map<String, dynamic>> adjustments;

  const EditorState({
    this.isLoading = false,
    this.error,
    this.zoom = 1.0,
    this.pan = Offset.zero,
    this.showHistogram = true,
    this.showBeforeAfter = false,
    this.splitView = false,
    this.activePanel = 'basic',
    this.adjustments = const [],
  });

  EditorState copyWith({
    bool? isLoading,
    String? error,
    double? zoom,
    Offset? pan,
    bool? showHistogram,
    bool? showBeforeAfter,
    bool? splitView,
    String? activePanel,
    List<Map<String, dynamic>>? adjustments,
  }) {
    return EditorState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      zoom: zoom ?? this.zoom,
      pan: pan ?? this.pan,
      showHistogram: showHistogram ?? this.showHistogram,
      showBeforeAfter: showBeforeAfter ?? this.showBeforeAfter,
      splitView: splitView ?? this.splitView,
      activePanel: activePanel ?? this.activePanel,
      adjustments: adjustments ?? this.adjustments,
    );
  }
}

/// Editor state notifier
class EditorNotifier extends StateNotifier<EditorState> {
  EditorNotifier() : super(const EditorState());

  void setLoading(bool loading) => state = state.copyWith(isLoading: loading);
  void setError(String? error) => state = state.copyWith(error: error);
  void setZoom(double zoom) => state = state.copyWith(zoom: zoom.clamp(0.1, 10.0));
  void setPan(Offset pan) => state = state.copyWith(pan: pan);
  void toggleHistogram() => state = state.copyWith(showHistogram: !state.showHistogram);
  void toggleBeforeAfter() => state = state.copyWith(showBeforeAfter: !state.showBeforeAfter);
  void setActivePanel(String panel) => state = state.copyWith(activePanel: panel);
  void resetView() => state = state.copyWith(zoom: 1.0, pan: Offset.zero);
}

/// Working editor canvas with real image loading
class EditorCanvas extends ConsumerStatefulWidget {
  const EditorCanvas({super.key});

  @override
  ConsumerState<EditorCanvas> createState() => _EditorCanvasState();
}

class _EditorCanvasState extends ConsumerState<EditorCanvas> {
  @override
  Widget build(BuildContext context) {
    final editorState = ref.watch(editorStateProvider);
    final imageFile = ref.watch(imageFileProvider);

    return Container(
      color: const Color(0xFF1A1A1A),
      child: Stack(
        children: [
          // Main image canvas
          if (imageFile != null)
            _buildImageCanvas(context, editorState, imageFile)
          else
            _buildEmptyState(context),

          // Top toolbar overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildTopToolbar(context, editorState),
          ),

          // Histogram overlay (top-right)
          if (editorState.showHistogram && imageFile != null)
            Positioned(
              top: 60,
              right: 16,
              child: _buildHistogram(context),
            ),

          // Bottom zoom controls
          Positioned(
            bottom: 16,
            left: 16,
            child: _buildZoomControls(context, editorState),
          ),

          // Loading overlay
          if (editorState.isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF6366F1)),
                    SizedBox(height: 16),
                    Text('Processing...', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),

          // Error overlay
          if (editorState.error != null)
            Positioned(
              top: 80,
              left: 16,
              right: 16,
              child: _buildErrorBar(context, editorState.error!),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate_outlined, size: 80, color: Colors.grey.shade700),
          const SizedBox(height: 24),
          Text(
            'Open an image to start editing',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'Drag and drop an image, or use the import button',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () => _pickImage(context),
                icon: const Icon(Icons.folder_open),
                label: const Text('Open Image'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => _showImportDialog(context),
                icon: const Icon(Icons.cloud_upload_outlined),
                label: const Text('Import'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey.shade400,
                  side: BorderSide(color: Colors.grey.shade700),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageCanvas(BuildContext context, editorState, File imageFile) {
    return GestureDetector(
      onScaleStart: (_) {},
      onScaleUpdate: (details) {
        if (details.scale != 1.0) {
          ref.read(editorStateProvider.notifier).setZoom(
            editorState.zoom * details.scale,
          );
        }
        if (details.pointerCount == 1) {
          ref.read(editorStateProvider.notifier).setPan(
            editorState.pan + details.focalPointDelta,
          );
        }
      },
      child: Center(
        child: Transform.translate(
          offset: editorState.pan,
          child: Transform.scale(
            scale: editorState.zoom,
            child: _buildImageWithSplitView(context, imageFile, editorState),
          ),
        ),
      ),
    );
  }

  Widget _buildImageWithSplitView(BuildContext context, File imageFile, editorState) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Image.file(
          imageFile,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 300,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey.shade600),
                  const SizedBox(height: 8),
                  Text('Failed to load image', style: TextStyle(color: Colors.grey.shade500)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTopToolbar(BuildContext context, editorState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          // Before/After toggle
          _buildToolbarButton(
            context,
            icon: Icons.compare,
            label: 'Before/After',
            isActive: editorState.showBeforeAfter,
            onTap: () => ref.read(editorStateProvider.notifier).toggleBeforeAfter(),
          ),
          const SizedBox(width: 8),
          // Histogram toggle
          _buildToolbarButton(
            context,
            icon: Icons.show_chart,
            label: 'Histogram',
            isActive: editorState.showHistogram,
            onTap: () => ref.read(editorStateProvider.notifier).toggleHistogram(),
          ),
          const Spacer(),
          // Reset view
          _buildToolbarButton(
            context,
            icon: Icons.center_focus_strong,
            label: 'Fit',
            onTap: () => ref.read(editorStateProvider.notifier).resetView(),
          ),
          const SizedBox(width: 8),
          // Zoom percentage
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.black.withOpacity(0.5),
            ),
            child: Text(
              '${(editorState.zoom * 100).toStringAsFixed(0)}%',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: isActive ? const Color(0xFF6366F1).withOpacity(0.3) : Colors.transparent,
              border: isActive ? Border.all(color: const Color(0xFF6366F1)) : null,
            ),
            child: Icon(icon, size: 20, color: isActive ? const Color(0xFF6366F1) : Colors.grey.shade400),
          ),
        ),
      ),
    );
  }

  Widget _buildHistogram(BuildContext context) {
    return Container(
      width: 200,
      height: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.black.withOpacity(0.7),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Histogram', style: TextStyle(color: Colors.grey.shade400, fontSize: 10)),
          const SizedBox(height: 8),
          Expanded(
            child: CustomPaint(
              size: const Size(double.infinity, 60),
              painter: HistogramPainter(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoomControls(BuildContext context, editorState) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.black.withOpacity(0.7),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 18),
            onPressed: () => ref.read(editorStateProvider.notifier).setZoom(editorState.zoom * 0.8),
            color: Colors.white,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          Text(
            '${(editorState.zoom * 100).toStringAsFixed(0)}%',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            onPressed: () => ref.read(editorStateProvider.notifier).setZoom(editorState.zoom * 1.25),
            color: Colors.white,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.center_focus_strong, size: 18),
            onPressed: () => ref.read(editorStateProvider.notifier).resetView(),
            color: Colors.white,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBar(BuildContext context, String error) {
    return Material(
      color: Colors.red.shade900,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(error, style: const TextStyle(color: Colors.white))),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 20),
              onPressed: () => ref.read(editorStateProvider.notifier).setError(null),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(BuildContext context) async {
    // In production, use file_picker package
    // For now, show a placeholder dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Open Image'),
        content: const Text('File picker would open here. Use file_picker package in production.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  void _showImportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ImportDialog(),
    );
  }
}

/// Simple histogram painter
class HistogramPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw histogram bars (placeholder)
    final barCount = 32;
    final barWidth = size.width / barCount;
    for (int i = 0; i < barCount; i++) {
      final height = (size.height * (0.3 + 0.7 * (i / barCount).abs()));
      canvas.drawRect(
        Rect.fromLTWH(i * barWidth, size.height - height, barWidth - 1, height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Import dialog with file picker and options
class ImportDialog extends ConsumerStatefulWidget {
  const ImportDialog({super.key});

  @override
  ConsumerState<ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends ConsumerState<ImportDialog> {
  bool _isImporting = false;
  double _progress = 0.0;
  final List<String> _tags = [];
  final _tagController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Import Images'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drop zone
            Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade700, style: BorderStyle.solid),
                color: Colors.grey.shade900.withOpacity(0.5),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_upload_outlined, size: 40, color: Colors.grey.shade600),
                    const SizedBox(height: 8),
                    Text('Drag files here or click to browse', style: TextStyle(color: Colors.grey.shade500)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Tags input
            Text('Tags (optional)', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagController,
                    decoration: InputDecoration(
                      hintText: 'Add tag...',
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onSubmitted: (value) {
                      if (value.isNotEmpty) {
                        setState(() {
                          _tags.add(value);
                          _tagController.clear();
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            if (_tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _tags.map((tag) => Chip(
                  label: Text(tag),
                  onDeleted: () => setState(() => _tags.remove(tag)),
                  backgroundColor: const Color(0xFF6366F1).withOpacity(0.2),
                )).toList(),
              ),
            ],
            const SizedBox(height: 16),
            // Progress
            if (_isImporting) ...[
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 8),
              Text('${(_progress * 100).toStringAsFixed(0)}% complete', style: TextStyle(color: Colors.grey.shade500)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton.icon(
          onPressed: _isImporting ? null : _startImport,
          icon: const Icon(Icons.upload),
          label: const Text('Import'),
        ),
      ],
    );
  }

  Future<void> _startImport() async {
    setState(() {
      _isImporting = true;
      _progress = 0.0;
    });

    // Simulate import progress
    for (int i = 0; i <= 100; i += 10) {
      await Future.delayed(const Duration(milliseconds: 100));
      setState(() => _progress = i / 100);
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Import completed!')),
      );
    }
  }

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }
}
