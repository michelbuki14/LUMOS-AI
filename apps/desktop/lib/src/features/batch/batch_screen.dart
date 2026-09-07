import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/api_service.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// PROVIDERS & STATE
// ═══════════════════════════════════════════════════════════════════════════════

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

final batchQueueProvider = StateNotifierProvider<BatchQueueNotifier, List<BatchImage>>(
  (ref) => BatchQueueNotifier(),
);

final batchOperationsProvider = StateNotifierProvider<BatchOperationsNotifier, List<BatchOperation>>(
  (ref) => BatchOperationsNotifier(),
);

final batchSettingsProvider = StateNotifierProvider<BatchSettingsNotifier, BatchSettings>(
  (ref) => BatchSettingsNotifier(),
);

final batchJobProvider = StateNotifierProvider<BatchJobNotifier, BatchJobState>(
  (ref) => BatchJobNotifier(ref.read(apiServiceProvider)),
);

final batchHistoryProvider = StateNotifierProvider<BatchHistoryNotifier, List<BatchJobRecord>>(
  (ref) => BatchHistoryNotifier(),
);

// ═══════════════════════════════════════════════════════════════════════════════
// MODELS
// ═══════════════════════════════════════════════════════════════════════════════

enum ImageBatchStatus { pending, processing, completed, failed }

enum BatchRunStatus { idle, running, paused, completed, cancelled }

class BatchImage {
  final String id;
  final String name;
  final String? thumbnailPath;
  ImageBatchStatus status;
  double progress;
  String? error;

  BatchImage({
    required this.id,
    required this.name,
    this.thumbnailPath,
    this.status = ImageBatchStatus.pending,
    this.progress = 0.0,
    this.error,
  });

  BatchImage copyWith({
    String? id,
    String? name,
    String? thumbnailPath,
    ImageBatchStatus? status,
    double? progress,
    String? error,
  }) {
    return BatchImage(
      id: id ?? this.id,
      name: name ?? this.name,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      error: error ?? this.error,
    );
  }
}

enum OperationType {
  exposure,
  contrast,
  whiteBalance,
  sharpening,
  noiseReduction,
  crop,
  resize,
  watermark,
  exportFormat,
  dodgeBurn,
  aiCull,
  aiPortrait,
  aiBackground,
  aiRemoval,
}

extension OperationTypeExtension on OperationType {
  String get displayName {
    switch (this) {
      case OperationType.exposure:
        return 'Exposure';
      case OperationType.contrast:
        return 'Contrast';
      case OperationType.whiteBalance:
        return 'White Balance';
      case OperationType.sharpening:
        return 'Sharpening';
      case OperationType.noiseReduction:
        return 'Noise Reduction';
      case OperationType.crop:
        return 'Crop';
      case OperationType.resize:
        return 'Resize';
      case OperationType.watermark:
        return 'Watermark';
      case OperationType.exportFormat:
        return 'Export Format';
      case OperationType.dodgeBurn:
        return 'Dodge & Burn';
      case OperationType.aiCull:
        return 'AI Cull';
      case OperationType.aiPortrait:
        return 'AI Portrait';
      case OperationType.aiBackground:
        return 'AI Background';
      case OperationType.aiRemoval:
        return 'AI Removal';
    }
  }

  IconData get icon {
    switch (this) {
      case OperationType.exposure:
        return Icons.exposure;
      case OperationType.contrast:
        return Icons.contrast;
      case OperationType.whiteBalance:
        return Icons.wb_sunny;
      case OperationType.sharpening:
        return Icons.auto_fix_high;
      case OperationType.noiseReduction:
        return Icons.grain;
      case OperationType.crop:
        return Icons.crop;
      case OperationType.resize:
        return Icons.aspect_ratio;
      case OperationType.watermark:
        return Icons.water_drop;
      case OperationType.exportFormat:
        return Icons.file_download;
      case OperationType.dodgeBurn:
        return Icons.brush;
      case OperationType.aiCull:
        return Icons.auto_awesome;
      case OperationType.aiPortrait:
        return Icons.face;
      case OperationType.aiBackground:
        return Icons.blur_on;
      case OperationType.aiRemoval:
        return Icons.remove_circle_outline;
    }
  }

  bool get isAi => this == OperationType.aiCull ||
      this == OperationType.aiPortrait ||
      this == OperationType.aiBackground ||
      this == OperationType.aiRemoval;
}

class BatchOperation {
  final String id;
  final OperationType type;
  bool enabled;
  Map<String, dynamic> settings;

  BatchOperation({
    required this.id,
    required this.type,
    this.enabled = true,
    Map<String, dynamic>? settings,
  }) : settings = settings ?? {};

  factory BatchOperation.fromType(OperationType type) {
    return BatchOperation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
    );
  }

  BatchOperation copyWith({bool? enabled, Map<String, dynamic>? settings}) {
    return BatchOperation(
      id: id,
      type: type,
      enabled: enabled ?? this.enabled,
      settings: settings ?? Map.from(this.settings),
    );
  }
}

class BatchSettings {
  final String exportFormat;
  final int quality;
  final bool resizeEnabled;
  final int? resizeWidth;
  final int? resizeHeight;
  final bool resizeMaintainAspect;
  final String namingPattern;
  final String outputFolder;
  final bool watermarkEnabled;
  final String watermarkText;
  final double watermarkOpacity;
  final String watermarkPosition;

  const BatchSettings({
    this.exportFormat = 'JPEG',
    this.quality = 90,
    this.resizeEnabled = false,
    this.resizeWidth,
    this.resizeHeight,
    this.resizeMaintainAspect = true,
    this.namingPattern = '{name}_processed',
    this.outputFolder = '',
    this.watermarkEnabled = false,
    this.watermarkText = '',
    this.watermarkOpacity = 0.5,
    this.watermarkPosition = 'bottom-right',
  });

  BatchSettings copyWith({
    String? exportFormat,
    int? quality,
    bool? resizeEnabled,
    int? resizeWidth,
    int? resizeHeight,
    bool? resizeMaintainAspect,
    String? namingPattern,
    String? outputFolder,
    bool? watermarkEnabled,
    String? watermarkText,
    double? watermarkOpacity,
    String? watermarkPosition,
  }) {
    return BatchSettings(
      exportFormat: exportFormat ?? this.exportFormat,
      quality: quality ?? this.quality,
      resizeEnabled: resizeEnabled ?? this.resizeEnabled,
      resizeWidth: resizeWidth ?? this.resizeWidth,
      resizeHeight: resizeHeight ?? this.resizeHeight,
      resizeMaintainAspect: resizeMaintainAspect ?? this.resizeMaintainAspect,
      namingPattern: namingPattern ?? this.namingPattern,
      outputFolder: outputFolder ?? this.outputFolder,
      watermarkEnabled: watermarkEnabled ?? this.watermarkEnabled,
      watermarkText: watermarkText ?? this.watermarkText,
      watermarkOpacity: watermarkOpacity ?? this.watermarkOpacity,
      watermarkPosition: watermarkPosition ?? this.watermarkPosition,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'export_format': exportFormat.toLowerCase(),
      'quality': quality,
      'resize': resizeEnabled
          ? {
              'width': resizeWidth,
              'height': resizeHeight,
              'maintain_aspect': resizeMaintainAspect,
            }
          : null,
      'naming_pattern': namingPattern,
      'output_folder': outputFolder,
      'watermark': watermarkEnabled
          ? {
              'text': watermarkText,
              'opacity': watermarkOpacity,
              'position': watermarkPosition,
            }
          : null,
    };
  }
}

class BatchJobState {
  final BatchRunStatus status;
  final String? batchId;
  final int processedCount;
  final int totalCount;
  final String? error;
  final DateTime? startedAt;
  final DateTime? completedAt;

  const BatchJobState({
    this.status = BatchRunStatus.idle,
    this.batchId,
    this.processedCount = 0,
    this.totalCount = 0,
    this.error,
    this.startedAt,
    this.completedAt,
  });

  double get overallProgress => totalCount > 0 ? processedCount / totalCount : 0.0;

  BatchJobState copyWith({
    BatchRunStatus? status,
    String? batchId,
    int? processedCount,
    int? totalCount,
    String? error,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return BatchJobState(
      status: status ?? this.status,
      batchId: batchId ?? this.batchId,
      processedCount: processedCount ?? this.processedCount,
      totalCount: totalCount ?? this.totalCount,
      error: error ?? this.error,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

class BatchJobRecord {
  final String id;
  final String name;
  final DateTime createdAt;
  final int imageCount;
  final int operationsCount;
  final BatchRunStatus status;
  final String exportFormat;
  final String outputFolder;

  const BatchJobRecord({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.imageCount,
    required this.operationsCount,
    required this.status,
    required this.exportFormat,
    required this.outputFolder,
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
// NOTIFIERS
// ═══════════════════════════════════════════════════════════════════════════════

class BatchQueueNotifier extends StateNotifier<List<BatchImage>> {
  BatchQueueNotifier() : super([]);

  void addImages(List<BatchImage> images) {
    state = [...state, ...images];
  }

  void removeImage(String id) {
    state = state.where((img) => img.id != id).toList();
  }

  void reorder(int oldIndex, int newIndex) {
    final items = List<BatchImage>.from(state);
    if (newIndex > oldIndex) newIndex--;
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);
    state = items;
  }

  void updateImageStatus(String id, ImageBatchStatus status, {double? progress, String? error}) {
    state = state.map((img) {
      if (img.id == id) {
        return img.copyWith(status: status, progress: progress, error: error);
      }
      return img;
    }).toList();
  }

  void clear() => state = [];
}

class BatchOperationsNotifier extends StateNotifier<List<BatchOperation>> {
  BatchOperationsNotifier() : super([]);

  void addOperation(BatchOperation op) {
    state = [...state, op];
  }

  void removeOperation(String id) {
    state = state.where((op) => op.id != id).toList();
  }

  void reorder(int oldIndex, int newIndex) {
    final items = List<BatchOperation>.from(state);
    if (newIndex > oldIndex) newIndex--;
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);
    state = items;
  }

  void toggleOperation(String id) {
    state = state.map((op) {
      if (op.id == id) return op.copyWith(enabled: !op.enabled);
      return op;
    }).toList();
  }

  void updateSettings(String id, Map<String, dynamic> settings) {
    state = state.map((op) {
      if (op.id == id) return op.copyWith(settings: settings);
      return op;
    }).toList();
  }

  void reset() => state = [];
}

class BatchSettingsNotifier extends StateNotifier<BatchSettings> {
  BatchSettingsNotifier() : super(const BatchSettings());

  void update(BatchSettings settings) => state = settings;
}

class BatchJobNotifier extends StateNotifier<BatchJobState> {
  final ApiService _api;
  Timer? _pollTimer;

  BatchJobNotifier(this._api) : super(const BatchJobState());

  Future<void> runBatch(List<BatchImage> images, List<BatchOperation> operations, BatchSettings settings) async {
    state = BatchJobState(
      status: BatchRunStatus.running,
      totalCount: images.length,
      startedAt: DateTime.now(),
    );

    try {
      final config = {
        'images': images.map((i) => i.id).toList(),
        'operations': operations.where((o) => o.enabled).map((o) => {
          'type': o.type.name,
          'settings': o.settings,
        }).toList(),
        'settings': settings.toMap(),
      };

      final result = await _api.startBatchProcess(config);
      state = state.copyWith(batchId: result['batch_id'] as String?);

      _startPolling(result['batch_id'] as String);
    } catch (e) {
      state = state.copyWith(
        status: BatchRunStatus.idle,
        error: e.toString(),
      );
    }
  }

  void _startPolling(String batchId) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      try {
        final status = await _api.getBatchStatus(batchId);
        final completed = status['processed'] as int? ?? 0;
        final total = status['total'] as int? ?? state.totalCount;

        state = state.copyWith(processedCount: completed);

        if (completed >= total || status['completed'] == true) {
          _pollTimer?.cancel();
          state = state.copyWith(
            status: BatchRunStatus.completed,
            completedAt: DateTime.now(),
          );
        }
      } catch (e) {
        // Continue polling on error
      }
    });
  }

  void pause() {
    _pollTimer?.cancel();
    state = state.copyWith(status: BatchRunStatus.paused);
  }

  void resume() {
    if (state.batchId != null) {
      state = state.copyWith(status: BatchRunStatus.running);
      _startPolling(state.batchId!);
    }
  }

  void cancel() {
    _pollTimer?.cancel();
    state = state.copyWith(
      status: BatchRunStatus.cancelled,
      completedAt: DateTime.now(),
    );
  }

  void reset() {
    _pollTimer?.cancel();
    state = const BatchJobState();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}

class BatchHistoryNotifier extends StateNotifier<List<BatchJobRecord>> {
  BatchHistoryNotifier() : super(_sampleHistory);

  void add(BatchJobRecord record) {
    state = [record, ...state];
  }

  static final List<BatchJobRecord> _sampleHistory = [
    BatchJobRecord(
      id: '1',
      name: 'Wedding Shoot - Gallery Export',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      imageCount: 342,
      operationsCount: 5,
      status: BatchRunStatus.completed,
      exportFormat: 'JPEG',
      outputFolder: '~/Exports/Wedding',
    ),
    BatchJobRecord(
      id: '2',
      name: 'Portrait Retouch Batch',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      imageCount: 86,
      operationsCount: 3,
      status: BatchRunStatus.completed,
      exportFormat: 'PNG',
      outputFolder: '~/Exports/Portraits',
    ),
    BatchJobRecord(
      id: '3',
      name: 'Event Preview Generation',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      imageCount: 1200,
      operationsCount: 2,
      status: BatchRunStatus.completed,
      exportFormat: 'WebP',
      outputFolder: '~/Exports/Events',
    ),
  ];
}

// ═══════════════════════════════════════════════════════════════════════════════
// MAIN SCREEN
// ═══════════════════════════════════════════════════════════════════════════════

class BatchScreen extends ConsumerStatefulWidget {
  const BatchScreen({super.key});

  @override
  ConsumerState<BatchScreen> createState() => _BatchScreenState();
}

class _BatchScreenState extends ConsumerState<BatchScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final queue = ref.watch(batchQueueProvider);
    final jobState = ref.watch(batchJobProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Column(
        children: [
          // ── Top Toolbar ───────────────────────────────────────────────
          _buildToolbar(context),

          // ── Tab Bar ───────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade800),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF6366F1),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey.shade500,
              tabs: const [
                Tab(text: 'Batch Processor'),
                Tab(text: 'Job History'),
              ],
            ),
          ),

          // ── Tab Views ─────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMainView(context, queue, jobState),
                const _JobHistoryView(),
              ],
            ),
          ),

          // ── Bottom Progress Panel ─────────────────────────────────────
          if (_tabController.index == 0) _buildBottomPanel(context, jobState),
        ],
      ),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    final jobState = ref.watch(batchJobProvider);
    final isRunning = jobState.status == BatchRunStatus.running;
    final isPaused = jobState.status == BatchRunStatus.paused;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        border: Border(bottom: BorderSide(color: Colors.grey.shade800)),
      ),
      child: Row(
        children: [
          // Select Images
          _ToolbarButton(
            icon: Icons.add_photo_alternate_outlined,
            label: 'Select Images',
            onPressed: () => _showImageSelector(context),
          ),
          const SizedBox(width: 8),

          // Create Template
          _ToolbarButton(
            icon: Icons.dashboard_customize_outlined,
            label: 'Create Template',
            onPressed: () => _showCreateTemplateDialog(context),
          ),
          const SizedBox(width: 8),

          // Run Batch
          _ToolbarButton(
            icon: Icons.play_arrow,
            label: 'Run Batch',
            color: const Color(0xFF10B981),
            onPressed: isRunning ? null : () => _runBatch(),
          ),
          const SizedBox(width: 8),

          const VerticalDivider(width: 24),

          // Pause/Resume
          _ToolbarButton(
            icon: isPaused ? Icons.play_arrow : Icons.pause,
            label: isPaused ? 'Resume' : 'Pause',
            color: const Color(0xFFF59E0B),
            onPressed: (!isRunning && !isPaused) ? null : () {
              if (isPaused) {
                ref.read(batchJobProvider.notifier).resume();
              } else {
                ref.read(batchJobProvider.notifier).pause();
              }
            },
          ),
          const SizedBox(width: 8),

          // Cancel
          _ToolbarButton(
            icon: Icons.stop,
            label: 'Cancel',
            color: const Color(0xFFEF4444),
            onPressed: (!isRunning && !isPaused) ? null : () {
              ref.read(batchJobProvider.notifier).cancel();
            },
          ),

          const Spacer(),

          // Queue count indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${ref.watch(batchQueueProvider).length} images',
              style: TextStyle(color: Colors.grey.shade300, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainView(BuildContext context, List<BatchImage> queue, BatchJobState jobState) {
    return Row(
      children: [
        // ── Left Panel: Image Queue ────────────────────────────────────
        SizedBox(
          width: 280,
          child: _ImageQueuePanel(queue: queue),
        ),
        VerticalDivider(width: 1, color: Colors.grey.shade800),

        // ── Center Panel: Template Editor ──────────────────────────────
        const Expanded(
          flex: 2,
          child: _TemplateEditorPanel(),
        ),
        VerticalDivider(width: 1, color: Colors.grey.shade800),

        // ── Right Panel: Batch Settings ────────────────────────────────
        const SizedBox(
          width: 320,
          child: _BatchSettingsPanel(),
        ),
      ],
    );
  }

  Widget _buildBottomPanel(BuildContext context, BatchJobState jobState) {
    final queue = ref.watch(batchQueueProvider);
    final completedCount = queue.where((i) => i.status == ImageBatchStatus.completed).length;
    final failedCount = queue.where((i) => i.status == ImageBatchStatus.failed).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        border: Border(top: BorderSide(color: Colors.grey.shade800)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Overall progress
          Row(
            children: [
              Text('Progress', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
              const Spacer(),
              Text(
                '$completedCount / ${queue.length} completed',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
              if (failedCount > 0) ...[
                const SizedBox(width: 8),
                Text(
                  '$failedCount failed',
                  style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: jobState.totalCount > 0 ? jobState.overallProgress : 0,
              backgroundColor: Colors.grey.shade800,
              valueColor: AlwaysStoppedAnimation<Color>(
                jobState.status == BatchRunStatus.completed
                    ? const Color(0xFF10B981)
                    : const Color(0xFF6366F1),
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),

          // Time remaining estimate
          if (jobState.status == BatchRunStatus.running && jobState.startedAt != null) ...[
            _buildTimeEstimate(jobState),
          ],

          // Error log (collapsible)
          if (failedCount > 0) ...[
            const SizedBox(height: 8),
            _buildErrorLog(queue),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeEstimate(BatchJobState jobState) {
    final elapsed = DateTime.now().difference(jobState.startedAt!);
    final rate = jobState.processedCount > 0
        ? elapsed.inSeconds / jobState.processedCount
        : 0.0;
    final remaining = rate * (jobState.totalCount - jobState.processedCount);
    final remainingDuration = Duration(seconds: remaining.toInt());

    String timeStr;
    if (remainingDuration.inHours > 0) {
      timeStr = '${remainingDuration.inHours}h ${remainingDuration.inMinutes % 60}m';
    } else if (remainingDuration.inMinutes > 0) {
      timeStr = '${remainingDuration.inMinutes}m ${remainingDuration.inSeconds % 60}s';
    } else {
      timeStr = '${remainingDuration.inSeconds}s';
    }

    return Text(
      'Time remaining: ~$timeStr',
      style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
    );
  }

  Widget _buildErrorLog(List<BatchImage> queue) {
    final failedImages = queue.where((i) => i.status == ImageBatchStatus.failed).toList();
    return ExpansionTile(
      title: Text(
        'Error Log (${failedImages.length})',
        style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12),
      ),
      iconColor: Colors.grey.shade500,
      collapsedIconColor: Colors.grey.shade500,
      children: failedImages.map((img) {
        return ListTile(
          dense: true,
          leading: const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 16),
          title: Text(img.name, style: const TextStyle(fontSize: 11)),
          subtitle: Text(img.error ?? 'Unknown error', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
        );
      }).toList(),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  void _showImageSelector(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _ImageSelectorDialog(),
    );
  }

  void _showCreateTemplateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _CreateTemplateDialog(),
    );
  }

  void _runBatch() {
    final queue = ref.read(batchQueueProvider);
    final operations = ref.read(batchOperationsProvider);
    final settings = ref.read(batchSettingsProvider);

    if (queue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add images to the queue first')),
      );
      return;
    }

    if (operations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one operation')),
      );
      return;
    }

    ref.read(batchJobProvider.notifier).runBatch(queue, operations, settings);

    // Reset image statuses
    for (final img in queue) {
      ref.read(batchQueueProvider.notifier).updateImageStatus(img.id, ImageBatchStatus.pending);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// IMAGE SELECTOR DIALOG
// ═══════════════════════════════════════════════════════════════════════════════

class _ImageSelectorDialog extends ConsumerWidget {
  const _ImageSelectorDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Simulated catalog items
    final catalogItems = List.generate(20, (i) => 'catalog_image_${i + 1}');
    final selectedItems = <String>{};

    return StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text('Select Images from Catalog'),
          content: SizedBox(
            width: 600,
            height: 400,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: catalogItems.length,
              itemBuilder: (context, index) {
                final id = catalogItems[index];
                final isSelected = selectedItems.contains(id);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        selectedItems.remove(id);
                      } else {
                        selectedItems.add(id);
                      }
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected
                          ? Border.all(color: const Color(0xFF6366F1), width: 2)
                          : null,
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Icon(Icons.image, size: 40, color: Colors.grey.shade600),
                        if (isSelected)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Color(0xFF6366F1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check, size: 12, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final images = selectedItems.map((id) => BatchImage(
                  id: id,
                  name: '$id.jpg',
                )).toList();
                ref.read(batchQueueProvider.notifier).addImages(images);
                Navigator.pop(context);
              },
              child: Text('Add ${selectedItems.length} Images'),
            ),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CREATE TEMPLATE DIALOG
// ═══════════════════════════════════════════════════════════════════════════════

class _CreateTemplateDialog extends ConsumerWidget {
  const _CreateTemplateDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();

    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      title: const Text('Create Batch Template'),
      content: SizedBox(
        width: 400,
        child: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'Template Name',
            hintText: 'e.g., Wedding Export',
            filled: true,
            fillColor: Colors.grey.shade900,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            // Add default operations
            final ops = [
              BatchOperation.fromType(OperationType.exposure),
              BatchOperation.fromType(OperationType.whiteBalance),
              BatchOperation.fromType(OperationType.sharpening),
              BatchOperation.fromType(OperationType.exportFormat),
            ];
            ref.read(batchOperationsProvider.notifier).reset();
            for (final op in ops) {
              ref.read(batchOperationsProvider.notifier).addOperation(op);
            }
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Template "${nameController.text}" created')),
            );
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TOOLBAR BUTTON
// ═══════════════════════════════════════════════════════════════════════════════

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color? color;

  const _ToolbarButton({
    required this.icon,
    required this.label,
    this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: onPressed == null ? Colors.grey.shade900 : (color?.withOpacity(0.1) ?? Colors.grey.shade800),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: onPressed == null ? Colors.grey.shade800 : (color ?? Colors.grey.shade700),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: onPressed == null ? Colors.grey.shade600 : (color ?? Colors.grey.shade300),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: onPressed == null ? Colors.grey.shade600 : (color ?? Colors.grey.shade300),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// IMAGE QUEUE PANEL
// ═══════════════════════════════════════════════════════════════════════════════

class _ImageQueuePanel extends ConsumerWidget {
  final List<BatchImage> queue;

  const _ImageQueuePanel({required this.queue});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: const Color(0xFF111827),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade800)),
            ),
            child: Row(
              children: [
                Icon(Icons.photo_library_outlined, size: 16, color: Colors.grey.shade400),
                const SizedBox(width: 8),
                Text(
                  'Queue',
                  style: TextStyle(color: Colors.grey.shade300, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                if (queue.isNotEmpty)
                  TextButton(
                    onPressed: () => ref.read(batchQueueProvider.notifier).clear(),
                    child: Text('Clear', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                  ),
              ],
            ),
          ),

          // List
          Expanded(
            child: queue.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.photo_library_outlined, size: 40, color: Colors.grey.shade700),
                        const SizedBox(height: 8),
                        Text('No images', style: TextStyle(color: Colors.grey.shade600)),
                        const SizedBox(height: 4),
                        Text('Click "Select Images" to add', style: TextStyle(color: Colors.grey.shade700, fontSize: 11)),
                      ],
                    ),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: queue.length,
                    onReorder: (oldIndex, newIndex) {
                      ref.read(batchQueueProvider.notifier).reorder(oldIndex, newIndex);
                    },
                    itemBuilder: (context, index) {
                      final image = queue[index];
                      return _QueueImageTile(
                        key: ValueKey(image.id),
                        image: image,
                        index: index,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _QueueImageTile extends ConsumerWidget {
  final BatchImage image;
  final int index;

  const _QueueImageTile({super.key, required this.image, required this.index});

  Color _statusColor() {
    switch (image.status) {
      case ImageBatchStatus.pending:
        return Colors.grey;
      case ImageBatchStatus.processing:
        return const Color(0xFF6366F1);
      case ImageBatchStatus.completed:
        return const Color(0xFF10B981);
      case ImageBatchStatus.failed:
        return const Color(0xFFEF4444);
    }
  }

  IconData _statusIcon() {
    switch (image.status) {
      case ImageBatchStatus.pending:
        return Icons.schedule;
      case ImageBatchStatus.processing:
        return Icons.sync;
      case ImageBatchStatus.completed:
        return Icons.check_circle;
      case ImageBatchStatus.failed:
        return Icons.error;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: image.status == ImageBatchStatus.processing
              ? const Color(0xFF6366F1).withOpacity(0.5)
              : Colors.transparent,
        ),
      ),
      child: ListTile(
        dense: true,
        leading: Stack(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(Icons.image, size: 20, color: Colors.grey.shade600),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: _statusColor(),
                  shape: BoxShape.circle,
                ),
                child: Icon(_statusIcon(), size: 8, color: Colors.white),
              ),
            ),
          ],
        ),
        title: Text(
          image.name,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: image.status == ImageBatchStatus.processing
            ? LinearProgressIndicator(
                value: image.progress,
                backgroundColor: Colors.grey.shade800,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                minHeight: 2,
              )
            : Text(
                image.status.name,
                style: TextStyle(fontSize: 10, color: _statusColor()),
              ),
        trailing: IconButton(
          icon: Icon(Icons.close, size: 14, color: Colors.grey.shade500),
          onPressed: () => ref.read(batchQueueProvider.notifier).removeImage(image.id),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TEMPLATE EDITOR PANEL
// ═══════════════════════════════════════════════════════════════════════════════

class _TemplateEditorPanel extends ConsumerWidget {
  const _TemplateEditorPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final operations = ref.watch(batchOperationsProvider);

    return Container(
      color: const Color(0xFF111827),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade800)),
            ),
            child: Row(
              children: [
                Icon(Icons.tune, size: 16, color: Colors.grey.shade400),
                const SizedBox(width: 8),
                Text(
                  'Operations',
                  style: TextStyle(color: Colors.grey.shade300, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                PopupMenuButton<OperationType>(
                  icon: Icon(Icons.add, size: 18, color: Colors.grey.shade400),
                  tooltip: 'Add Operation',
                  onSelected: (type) {
                    ref.read(batchOperationsProvider.notifier).addOperation(
                      BatchOperation.fromType(type),
                    );
                  },
                  itemBuilder: (context) {
                    final standardOps = OperationType.values.where((o) => !o.isAi).toList();
                    final aiOps = OperationType.values.where((o) => o.isAi).toList();

                    return [
                      const PopupMenuItem<OperationType>(
                        enabled: false,
                        child: Text('Standard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                      ...standardOps.map((op) => PopupMenuItem(
                        value: op,
                        child: Row(
                          children: [
                            Icon(op.icon, size: 16),
                            const SizedBox(width: 8),
                            Text(op.displayName, style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      )),
                      const PopupMenuDivider(),
                      const PopupMenuItem<OperationType>(
                        enabled: false,
                        child: Text('AI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                      ...aiOps.map((op) => PopupMenuItem(
                        value: op,
                        child: Row(
                          children: [
                            Icon(op.icon, size: 16, color: const Color(0xFF8B5CF6)),
                            const SizedBox(width: 8),
                            Text(op.displayName, style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      )),
                    ];
                  },
                ),
              ],
            ),
          ),

          // Operations List
          Expanded(
            child: operations.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.tune, size: 40, color: Colors.grey.shade700),
                        const SizedBox(height: 8),
                        Text('No operations', style: TextStyle(color: Colors.grey.shade600)),
                        const SizedBox(height: 4),
                        Text('Click + to add operations', style: TextStyle(color: Colors.grey.shade700, fontSize: 11)),
                      ],
                    ),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: operations.length,
                    onReorder: (oldIndex, newIndex) {
                      ref.read(batchOperationsProvider.notifier).reorder(oldIndex, newIndex);
                    },
                    itemBuilder: (context, index) {
                      final operation = operations[index];
                      return _OperationTile(
                        key: ValueKey(operation.id),
                        operation: operation,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _OperationTile extends ConsumerStatefulWidget {
  final BatchOperation operation;

  const _OperationTile({super.key, required this.operation});

  @override
  ConsumerState<_OperationTile> createState() => _OperationTileState();
}

class _OperationTileState extends ConsumerState<_OperationTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      color: const Color(0xFF1E293B),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: widget.operation.type.isAi
              ? const Color(0xFF8B5CF6).withOpacity(0.3)
              : Colors.grey.shade800,
        ),
      ),
      child: Column(
        children: [
          ListTile(
            dense: true,
            leading: Icon(
              widget.operation.type.icon,
              size: 18,
              color: widget.operation.type.isAi
                  ? const Color(0xFF8B5CF6)
                  : const Color(0xFF6366F1),
            ),
            title: Text(
              widget.operation.type.displayName,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Enable/Disable
                Switch(
                  value: widget.operation.enabled,
                  onChanged: (_) => ref.read(batchOperationsProvider.notifier).toggleOperation(widget.operation.id),
                  activeColor: const Color(0xFF6366F1),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                // Expand
                IconButton(
                  icon: Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 16,
                    color: Colors.grey.shade500,
                  ),
                  onPressed: () => setState(() => _expanded = !_expanded),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                ),
                // Remove
                IconButton(
                  icon: Icon(Icons.close, size: 14, color: Colors.grey.shade500),
                  onPressed: () => ref.read(batchOperationsProvider.notifier).removeOperation(widget.operation.id),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                ),
              ],
            ),
          ),
          if (_expanded) _buildSettings(),
        ],
      ),
    );
  }

  Widget _buildSettings() {
    switch (widget.operation.type) {
      case OperationType.exposure:
        return _buildExposureSettings();
      case OperationType.contrast:
        return _buildContrastSettings();
      case OperationType.whiteBalance:
        return _buildWhiteBalanceSettings();
      case OperationType.sharpening:
        return _buildSharpeningSettings();
      case OperationType.noiseReduction:
        return _buildNoiseReductionSettings();
      case OperationType.crop:
        return _buildCropSettings();
      case OperationType.resize:
        return _buildResizeSettings();
      case OperationType.watermark:
        return _buildWatermarkSettings();
      case OperationType.exportFormat:
        return _buildExportFormatSettings();
      case OperationType.dodgeBurn:
        return _buildDodgeBurnSettings();
      case OperationType.aiCull:
        return _buildAiCullSettings();
      case OperationType.aiPortrait:
        return _buildAiPortraitSettings();
      case OperationType.aiBackground:
        return _buildAiBackgroundSettings();
      case OperationType.aiRemoval:
        return _buildAiRemovalSettings();
    }
  }

  Widget _buildExposureSettings() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          _buildSlider('Exposure', -2.0, 2.0, 0.0, Icons.exposure),
          _buildSlider('Highlights', -1.0, 1.0, 0.0, Icons.brightness_6),
          _buildSlider('Shadows', -1.0, 1.0, 0.0, Icons.brightness_4),
        ],
      ),
    );
  }

  Widget _buildContrastSettings() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          _buildSlider('Contrast', -100.0, 100.0, 0.0, Icons.contrast),
          _buildSlider('Clarity', -100.0, 100.0, 0.0, Icons.auto_fix_high),
          _buildSlider('Dehaze', -100.0, 100.0, 0.0, Icons.foggy),
        ],
      ),
    );
  }

  Widget _buildWhiteBalanceSettings() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          _buildSlider('Temperature', -100.0, 100.0, 0.0, Icons.thermostat),
          _buildSlider('Tint', -100.0, 100.0, 0.0, Icons.tune),
          Row(
            children: [
              Checkbox(value: false, onChanged: (_) {}, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
              const Text('Auto White Balance', style: TextStyle(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSharpeningSettings() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          _buildSlider('Amount', 0.0, 150.0, 0.0, Icons.auto_fix_high),
          _buildSlider('Radius', 0.5, 3.0, 1.0, Icons.radio_button_unchecked),
          _buildSlider('Detail', 0.0, 100.0, 25.0, Icons.details),
          _buildSlider('Masking', 0.0, 100.0, 0.0, Icons.filter_alt),
        ],
      ),
    );
  }

  Widget _buildNoiseReductionSettings() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          _buildSlider('Luminance', 0.0, 100.0, 0.0, Icons.grain),
          _buildSlider('Color', 0.0, 100.0, 25.0, Icons.palette),
          _buildSlider('Detail', 0.0, 100.0, 50.0, Icons.details),
        ],
      ),
    );
  }

  Widget _buildCropSettings() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          _buildNumberField('X', '0'),
          _buildNumberField('Y', '0'),
          _buildNumberField('Width', '1920'),
          _buildNumberField('Height', '1080'),
          Row(
            children: [
              Checkbox(value: true, onChanged: (_) {}, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
              const Text('Constrain to aspect ratio', style: TextStyle(fontSize: 12)),
            ],
          ),
          _buildDropdown('Aspect Ratio', ['16:9', '4:3', '1:1', '3:2', 'Custom']),
        ],
      ),
    );
  }

  Widget _buildResizeSettings() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          _buildNumberField('Width', '1920'),
          _buildNumberField('Height', '1080'),
          Row(
            children: [
              Checkbox(value: true, onChanged: (_) {}, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
              const Text('Maintain aspect ratio', style: TextStyle(fontSize: 12)),
            ],
          ),
          _buildDropdown('Unit', ['Pixels', 'Percent', 'Inches', 'CM']),
        ],
      ),
    );
  }

  Widget _buildWatermarkSettings() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          _buildTextField('Watermark Text', '© Your Name'),
          _buildSlider('Opacity', 0.0, 1.0, 0.5, Icons.opacity),
          _buildDropdown('Position', ['Top Left', 'Top Right', 'Bottom Left', 'Bottom Right', 'Center']),
          _buildSlider('Scale', 1.0, 20.0, 5.0, Icons.format_size),
        ],
      ),
    );
  }

  Widget _buildExportFormatSettings() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          _buildDropdown('Format', ['JPEG', 'PNG', 'TIFF', 'WebP', 'AVIF']),
          _buildSlider('Quality', 1, 100, 90, Icons.high_quality),
          Row(
            children: [
              Checkbox(value: false, onChanged: (_) {}, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
              const Text('Embed color profile', style: TextStyle(fontSize: 12)),
            ],
          ),
          _buildDropdown('Color Space', ['sRGB', 'Adobe RGB', 'ProPhoto RGB']),
        ],
      ),
    );
  }

  Widget _buildDodgeBurnSettings() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          _buildSlider('Dodge Amount', 0.0, 100.0, 0.0, Icons.brightness_5),
          _buildSlider('Burn Amount', 0.0, 100.0, 0.0, Icons.brightness_7),
          _buildDropdown('Range', ['Shadows', 'Midtones', 'Highlights']),
          _buildSlider('Brush Size', 1.0, 500.0, 50.0, Icons.brush),
        ],
      ),
    );
  }

  Widget _buildAiCullSettings() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          _buildDropdown('Cull Criteria', ['Duplicates', 'Blurry', 'Closed Eyes', 'All']),
          _buildSlider('Sensitivity', 0.0, 1.0, 0.5, Icons.tune),
          Row(
            children: [
              Checkbox(value: true, onChanged: (_) {}, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
              const Text('Auto-delete rejected', style: TextStyle(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAiPortraitSettings() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          _buildSlider('Skin Smoothing', 0.0, 100.0, 0.0, Icons.face),
          _buildSlider('Eye Enhancement', 0.0, 100.0, 0.0, Icons.visibility),
          _buildSlider('Teeth Whitening', 0.0, 100.0, 0.0, Icons.sentiment_satisfied),
          _buildDropdown('Face Detection Speed', ['Fast', 'Balanced', 'Accurate']),
        ],
      ),
    );
  }

  Widget _buildAiBackgroundSettings() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          _buildDropdown('Effect', ['Blur', 'Replace', 'Remove', 'Color']),
          _buildDropdown('Blur Type', ['Gaussian', 'Lens', 'Motion', 'Box']),
          _buildSlider('Intensity', 0.0, 100.0, 50.0, Icons.tune),
          _buildDropdown('Background Color', ['Black', 'White', 'Green', 'Custom...']),
        ],
      ),
    );
  }

  Widget _buildAiRemovalSettings() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          _buildDropdown('Removal Type', ['Object', 'Person', 'Text', 'Background']),
          _buildDropdown('Fill Method', ['AI Generate', 'Clone Stamp', 'Content-Aware', 'Solid Color']),
          _buildSlider('Edge Refinement', 0.0, 100.0, 50.0, Icons.auto_fix_high),
        ],
      ),
    );
  }

  Widget _buildSlider(String label, double min, double max, double value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
          ),
          Expanded(
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: (v) {},
              activeColor: const Color(0xFF6366F1),
              inactiveColor: Colors.grey.shade700,
            ),
          ),
          SizedBox(
            width: 36,
            child: Text(value.toStringAsFixed(1), style: const TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: TextField(
              controller: TextEditingController(text: value),
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                filled: true,
                fillColor: Colors.grey.shade900,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: Colors.grey.shade700),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: TextEditingController(text: value),
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                filled: true,
                fillColor: Colors.grey.shade900,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: Colors.grey.shade700),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> options) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: options.first,
              isDense: true,
              isExpanded: true,
              style: const TextStyle(fontSize: 11, color: Colors.white),
              dropdownColor: const Color(0xFF1E293B),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                filled: true,
                fillColor: Colors.grey.shade900,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: Colors.grey.shade700),
                ),
              ),
              items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
              onChanged: (_) {},
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// BATCH SETTINGS PANEL
// ═══════════════════════════════════════════════════════════════════════════════

class _BatchSettingsPanel extends ConsumerWidget {
  const _BatchSettingsPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(batchSettingsProvider);

    return Container(
      color: const Color(0xFF111827),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.settings, size: 16, color: Colors.grey.shade400),
              const SizedBox(width: 8),
              Text(
                'Batch Settings',
                style: TextStyle(color: Colors.grey.shade300, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Export Format
          _SettingsSection(
            title: 'Export',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDropdown(
                  'Format',
                  ['JPEG', 'PNG', 'TIFF', 'WebP', 'AVIF'],
                  settings.exportFormat,
                  (v) => ref.read(batchSettingsProvider.notifier).update(
                    settings.copyWith(exportFormat: v),
                  ),
                ),
                const SizedBox(height: 12),
                _buildSlider(
                  'Quality',
                  settings.quality.toDouble(),
                  1, 100,
                  (v) => ref.read(batchSettingsProvider.notifier).update(
                    settings.copyWith(quality: v.toInt()),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Resize
          _SettingsSection(
            title: 'Resize',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  value: settings.resizeEnabled,
                  onChanged: (v) => ref.read(batchSettingsProvider.notifier).update(
                    settings.copyWith(resizeEnabled: v),
                  ),
                  title: const Text('Enable resize', style: TextStyle(fontSize: 12)),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  activeColor: const Color(0xFF6366F1),
                ),
                if (settings.resizeEnabled) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildNumberInput(
                          'Width',
                          settings.resizeWidth?.toString() ?? '',
                          (v) => ref.read(batchSettingsProvider.notifier).update(
                            settings.copyWith(resizeWidth: int.tryParse(v)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildNumberInput(
                          'Height',
                          settings.resizeHeight?.toString() ?? '',
                          (v) => ref.read(batchSettingsProvider.notifier).update(
                            settings.copyWith(resizeHeight: int.tryParse(v)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  CheckboxListTile(
                    value: settings.resizeMaintainAspect,
                    onChanged: (v) => ref.read(batchSettingsProvider.notifier).update(
                      settings.copyWith(resizeMaintainAspect: v ?? true),
                    ),
                    title: const Text('Maintain aspect ratio', style: TextStyle(fontSize: 11)),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    activeColor: const Color(0xFF6366F1),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Naming Convention
          _SettingsSection(
            title: 'Naming Convention',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: TextEditingController(text: settings.namingPattern),
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    hintText: '{name}_processed',
                    hintStyle: TextStyle(color: Colors.grey.shade600),
                    filled: true,
                    fillColor: Colors.grey.shade900,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade700),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  onChanged: (v) => ref.read(batchSettingsProvider.notifier).update(
                    settings.copyWith(namingPattern: v),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    _nameTag('{name}'),
                    _nameTag('{index}'),
                    _nameTag('{date}'),
                    _nameTag('{time}'),
                    _nameTag('{ext}'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Output Folder
          _SettingsSection(
            title: 'Output Folder',
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade700),
                    ),
                    child: Text(
                      settings.outputFolder.isEmpty ? 'Select folder...' : settings.outputFolder,
                      style: TextStyle(
                        fontSize: 12,
                        color: settings.outputFolder.isEmpty ? Colors.grey.shade600 : Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.folder_open, size: 18, color: Colors.grey.shade400),
                  onPressed: () {
                    // Would open folder picker
                    ref.read(batchSettingsProvider.notifier).update(
                      settings.copyWith(outputFolder: '/home/user/Exports/Batch'),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Watermark
          _SettingsSection(
            title: 'Watermark',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  value: settings.watermarkEnabled,
                  onChanged: (v) => ref.read(batchSettingsProvider.notifier).update(
                    settings.copyWith(watermarkEnabled: v),
                  ),
                  title: const Text('Enable watermark', style: TextStyle(fontSize: 12)),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  activeColor: const Color(0xFF6366F1),
                ),
                if (settings.watermarkEnabled) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: TextEditingController(text: settings.watermarkText),
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      labelText: 'Watermark text',
                      labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                      filled: true,
                      fillColor: Colors.grey.shade900,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade700),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    onChanged: (v) => ref.read(batchSettingsProvider.notifier).update(
                      settings.copyWith(watermarkText: v),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDropdown(
                    'Position',
                    ['top-left', 'top-right', 'bottom-left', 'bottom-right', 'center'],
                    settings.watermarkPosition,
                    (v) => ref.read(batchSettingsProvider.notifier).update(
                      settings.copyWith(watermarkPosition: v),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSlider(
                    'Opacity',
                    settings.watermarkOpacity,
                    0.0, 1.0,
                    (v) => ref.read(batchSettingsProvider.notifier).update(
                      settings.copyWith(watermarkOpacity: v),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _nameTag(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(tag, style: const TextStyle(fontSize: 10, fontFamily: 'monospace')),
    );
  }

  Widget _buildDropdown(String label, List<String> options, String value, ValueChanged<String> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: options.contains(value) ? value : options.first,
          isDense: true,
          style: const TextStyle(fontSize: 12, color: Colors.white),
          dropdownColor: const Color(0xFF1E293B),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade900,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade700),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: options.map((o) => DropdownMenuItem(value: o, child: Text(o, style: const TextStyle(fontSize: 12)))).toList(),
          onChanged: (v) => onChanged(v!),
        ),
      ],
    );
  }

  Widget _buildSlider(String label, double value, double min, double max, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
            Text(value.toStringAsFixed(1), style: const TextStyle(fontSize: 11)),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          onChanged: onChanged,
          activeColor: const Color(0xFF6366F1),
          inactiveColor: Colors.grey.shade700,
        ),
      ],
    );
  }

  Widget _buildNumberInput(String label, String value, ValueChanged<String> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
        const SizedBox(height: 4),
        TextField(
          controller: TextEditingController(text: value),
          style: const TextStyle(fontSize: 12),
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade900,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade700),
            ),
            contentPadding: const EdgeInsets.all(8),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _SettingsSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade300,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// JOB HISTORY VIEW
// ═══════════════════════════════════════════════════════════════════════════════

class _JobHistoryView extends ConsumerWidget {
  const _JobHistoryView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(batchHistoryProvider);

    return Container(
      color: const Color(0xFF111827),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade800)),
            ),
            child: Row(
              children: [
                Icon(Icons.history, size: 16, color: Colors.grey.shade400),
                const SizedBox(width: 8),
                Text(
                  'Job History',
                  style: TextStyle(color: Colors.grey.shade300, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFF1E293B),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text('Name', style: _headerStyle())),
                Expanded(flex: 2, child: Text('Date', style: _headerStyle())),
                Expanded(child: Text('Images', style: _headerStyle())),
                Expanded(child: Text('Operations', style: _headerStyle())),
                Expanded(child: Text('Format', style: _headerStyle())),
                Expanded(flex: 2, child: Text('Output', style: _headerStyle())),
                Expanded(child: Text('Status', style: _headerStyle())),
              ],
            ),
          ),

          // List
          Expanded(
            child: ListView.builder(
              itemCount: history.length,
              itemBuilder: (context, index) {
                final job = history[index];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey.shade800)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          job.name,
                          style: const TextStyle(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          _formatDate(job.createdAt),
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${job.imageCount}',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${job.operationsCount}',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          job.exportFormat,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          job.outputFolder,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        child: _buildStatusChip(job.status),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _headerStyle() {
    return TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: Colors.grey.shade500,
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${date.month}/${date.day}';
  }

  Widget _buildStatusChip(BatchRunStatus status) {
    Color color;
    String label;
    switch (status) {
      case BatchRunStatus.completed:
        color = const Color(0xFF10B981);
        label = 'Done';
        break;
      case BatchRunStatus.running:
        color = const Color(0xFF6366F1);
        label = 'Running';
        break;
      case BatchRunStatus.paused:
        color = const Color(0xFFF59E0B);
        label = 'Paused';
        break;
      case BatchRunStatus.cancelled:
        color = Colors.grey;
        label = 'Cancelled';
        break;
      case BatchRunStatus.idle:
        color = Colors.grey;
        label = 'Idle';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500),
        textAlign: TextAlign.center,
      ),
    );
  }
}
