import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;

import '../../core/services/api_service.dart';

// ─── Data Models ───────────────────────────────────────────────────────────────

enum GalleryStatus { draft, published, expired, closed }

enum DownloadSetting { fullRes, webRes, disabled }

class GalleryImage {
  final String id;
  final String url;
  final String thumbnailUrl;
  final String name;
  final bool isSelectedByClient;
  final int selectionCount;

  const GalleryImage({
    required this.id,
    required this.url,
    required this.thumbnailUrl,
    required this.name,
    this.isSelectedByClient = false,
    this.selectionCount = 0,
  });
}

class Gallery {
  final String id;
  final String name;
  final String? description;
  final GalleryStatus status;
  final List<GalleryImage> images;
  final int viewCount;
  final int downloadCount;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final bool passwordProtected;
  final String? password;
  final DownloadSetting downloadSetting;
  final bool printEnabled;
  final List<String> enabledPrintProducts;
  final Color themeColor;
  final String? emailTemplate;
  final String shareLink;

  const Gallery({
    required this.id,
    required this.name,
    this.description,
    required this.status,
    required this.images,
    this.viewCount = 0,
    this.downloadCount = 0,
    required this.createdAt,
    this.expiresAt,
    this.passwordProtected = false,
    this.password,
    this.downloadSetting = DownloadSetting.webRes,
    this.printEnabled = false,
    this.enabledPrintProducts = const [],
    this.themeColor = const Color(0xFF6366F1),
    this.emailTemplate,
    this.shareLink = '',
  });

  Gallery copyWith({
    String? name,
    String? description,
    GalleryStatus? status,
    List<GalleryImage>? images,
    int? viewCount,
    int? downloadCount,
    DateTime? expiresAt,
    bool? passwordProtected,
    String? password,
    DownloadSetting? downloadSetting,
    bool? printEnabled,
    List<String>? enabledPrintProducts,
    Color? themeColor,
    String? emailTemplate,
    String? shareLink,
  }) {
    return Gallery(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      status: status ?? this.status,
      images: images ?? this.images,
      viewCount: viewCount ?? this.viewCount,
      downloadCount: downloadCount ?? this.downloadCount,
      createdAt: createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      passwordProtected: passwordProtected ?? this.passwordProtected,
      password: password ?? this.password,
      downloadSetting: downloadSetting ?? this.downloadSetting,
      printEnabled: printEnabled ?? this.printEnabled,
      enabledPrintProducts: enabledPrintProducts ?? this.enabledPrintProducts,
      themeColor: themeColor ?? this.themeColor,
      emailTemplate: emailTemplate ?? this.emailTemplate,
      shareLink: shareLink ?? this.shareLink,
    );
  }

  int get imageCount => images.length;
  int get selectedCount => images.where((i) => i.isSelectedByClient).length;
}

class AnalyticsData {
  final List<TimeSeriesPoint> views;
  final List<TimeSeriesPoint> downloads;
  final List<TimeSeriesPoint> selections;
  final List<ClientComment> comments;
  final List<GalleryImage> mostSelected;

  const AnalyticsData({
    required this.views,
    required this.downloads,
    required this.selections,
    required this.comments,
    required this.mostSelected,
  });
}

class TimeSeriesPoint {
  final DateTime date;
  final int value;
  const TimeSeriesPoint({required this.date, required this.value});
}

class ClientComment {
  final String id;
  final String author;
  final String text;
  final DateTime createdAt;
  final String? imageId;

  const ClientComment({
    required this.id,
    required this.author,
    required this.text,
    required this.createdAt,
    this.imageId,
  });
}

// ─── Sample Data ──────────────────────────────────────────────────────────────

List<Gallery> _generateSampleGalleries() {
  final random = math.Random(42);
  final now = DateTime.now();

  return List.generate(8, (index) {
    final statuses = GalleryStatus.values;
    final status = statuses[index % statuses.length];
    final imageCount = 12 + random.nextInt(40);

    return Gallery(
      id: 'gallery_${index + 1}',
      name: [
        'Sarah & Michael Wedding',
        'Johnson Family Portraits',
        'Corporate Headshots Q3',
        'Sunset Beach Session',
        'Studio Fashion Shoot',
        'Product Launch Event',
        'Engagement Photos',
        'Newborn Session',
      ][index],
      description: 'Professional photography gallery for client review and selection.',
      status: status,
      images: List.generate(imageCount, (imgIndex) => GalleryImage(
        id: 'img_${index}_$imgIndex',
        url: 'https://picsum.photos/seed/${index * 100 + imgIndex}/1200/800',
        thumbnailUrl: 'https://picsum.photos/seed/${index * 100 + imgIndex}/300/200',
        name: 'Image ${imgIndex + 1}',
        isSelectedByClient: random.nextDouble() > 0.6,
        selectionCount: random.nextInt(5),
      )),
      viewCount: 15 + random.nextInt(200),
      downloadCount: random.nextInt(50),
      createdAt: now.subtract(Duration(days: random.nextInt(30))),
      expiresAt: status == GalleryStatus.published
          ? now.add(Duration(days: 30 + random.nextInt(60)))
          : null,
      passwordProtected: index % 3 == 0,
      downloadSetting: DownloadSetting.values[index % 3],
      printEnabled: index % 2 == 0,
      enabledPrintProducts: ['Canvas', 'Metal Print', 'Fine Art'],
      themeColor: [
        Color(0xFF6366F1),
        Color(0xFF8B5CF6),
        Color(0xFFEC4899),
        Color(0xFF10B981),
      ][index % 4],
      emailTemplate: 'Dear client,\n\nYour gallery is ready for viewing. Click the link below to access your photos...',
      shareLink: 'https://gallery.lumos.ai/g/${1000 + index}',
    );
  });
}

AnalyticsData _generateSampleAnalytics() {
  final now = DateTime.now();
  final random = math.Random(99);

  return AnalyticsData(
    views: List.generate(30, (i) => TimeSeriesPoint(
      date: now.subtract(Duration(days: 29 - i)),
      value: 5 + random.nextInt(50),
    )),
    downloads: List.generate(30, (i) => TimeSeriesPoint(
      date: now.subtract(Duration(days: 29 - i)),
      value: random.nextInt(20),
    )),
    selections: List.generate(30, (i) => TimeSeriesPoint(
      date: now.subtract(Duration(days: 29 - i)),
      value: 10 + random.nextInt(40),
    )),
    comments: [
      ClientComment(
        id: 'c1',
        author: 'Sarah',
        text: 'Love the sunset shots! Can we get those in black and white too?',
        createdAt: now.subtract(const Duration(hours: 5)),
        imageId: 'img_0_3',
      ),
      ClientComment(
        id: 'c2',
        author: 'Michael',
        text: 'Perfect! The whole gallery looks amazing.',
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      ClientComment(
        id: 'c3',
        author: 'Sarah',
        text: 'Please send the full resolution files for #5, #12, and #18.',
        createdAt: now.subtract(const Duration(minutes: 30)),
      ),
    ],
    mostSelected: [],
  );
}

// ─── Providers ────────────────────────────────────────────────────────────────

final galleriesProvider = StateNotifierProvider<GalleriesNotifier, AsyncValue<List<Gallery>>>((ref) {
  return GalleriesNotifier();
});

final selectedGalleryIdProvider = StateProvider<String?>((ref) => null);

final searchQueryProvider = StateProvider<String>((ref) => '');

final statusFilterProvider = StateProvider<GalleryStatus?>((ref) => null);

final proofingModeProvider = StateProvider<bool>((ref) => false);

final selectedImagesProvider = StateProvider<Set<String>>((ref) => {});

final galleryAnalyticsProvider = StateProvider<AnalyticsData?>((ref) => null);

final editingGalleryProvider = StateProvider<bool>((ref) => false);

class GalleriesNotifier extends StateNotifier<AsyncValue<List<Gallery>>> {
  GalleriesNotifier() : super(const AsyncValue.loading()) {
    _loadGalleries();
  }

  Future<void> _loadGalleries() async {
    try {
      // Try API first
      final apiGalleries = await ApiService().getGalleries();
      if (apiGalleries.isNotEmpty) {
        state = AsyncValue.data(apiGalleries.map((g) => _mapApiGallery(g)).toList());
      } else {
        // Use sample data for development
        state = AsyncValue.data(_generateSampleGalleries());
      }
    } catch (e) {
      // Fall back to sample data
      state = AsyncValue.data(_generateSampleGalleries());
    }
  }

  Gallery _mapApiGallery(Map<String, dynamic> data) {
    return Gallery(
      id: data['id'] ?? '',
      name: data['name'] ?? 'Untitled',
      description: data['description'],
      status: GalleryStatus.values.firstWhere(
        (s) => s.name == (data['status'] ?? 'draft'),
        orElse: () => GalleryStatus.draft,
      ),
      images: (data['images'] as List<dynamic>?)?.map((img) => GalleryImage(
        id: img['id'] ?? '',
        url: img['url'] ?? '',
        thumbnailUrl: img['thumbnail_url'] ?? img['url'] ?? '',
        name: img['name'] ?? '',
        isSelectedByClient: img['is_selected'] ?? false,
        selectionCount: img['selection_count'] ?? 0,
      )).toList() ?? [],
      viewCount: data['view_count'] ?? 0,
      downloadCount: data['download_count'] ?? 0,
      createdAt: DateTime.tryParse(data['created_at'] ?? '') ?? DateTime.now(),
      expiresAt: data['expires_at'] != null ? DateTime.tryParse(data['expires_at']) : null,
      passwordProtected: data['password_protected'] ?? false,
      downloadSetting: DownloadSetting.values.firstWhere(
        (d) => d.name == (data['download_setting'] ?? 'webRes'),
        orElse: () => DownloadSetting.webRes,
      ),
      printEnabled: data['print_enabled'] ?? false,
      themeColor: Color(data['theme_color'] ?? 0xFF6366F1),
      emailTemplate: data['email_template'],
      shareLink: data['share_link'] ?? '',
    );
  }

  Future<void> createGallery(String name) async {
    final current = state.value ?? [];
    final newGallery = Gallery(
      id: 'gallery_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      status: GalleryStatus.draft,
      images: [],
      createdAt: DateTime.now(),
    );

    try {
      await ApiService().createGallery(name, []);
      state = AsyncValue.data([newGallery, ...current]);
    } catch (e) {
      state = AsyncValue.data([newGallery, ...current]);
    }
  }

  Future<void> duplicateGallery(String id) async {
    final current = state.value ?? [];
    final original = current.firstWhere((g) => g.id == id, orElse: () => current.first);
    final dup = Gallery(
      id: 'gallery_${DateTime.now().millisecondsSinceEpoch}',
      name: '${original.name} (Copy)',
      description: original.description,
      status: GalleryStatus.draft,
      images: original.images,
      createdAt: DateTime.now(),
    );

    try {
      await ApiService().duplicateGallery(id);
    } catch (_) {}

    state = AsyncValue.data([dup, ...current]);
  }

  Future<void> deleteGallery(String id) async {
    final current = state.value ?? [];
    try {
      await ApiService().deleteGallery(id);
    } catch (_) {}
    state = AsyncValue.data(current.where((g) => g.id != id).toList());
  }

  Future<void> closeGallery(String id) async {
    final current = state.value ?? [];
    try {
      await ApiService().closeGallery(id);
    } catch (_) {}
    state = AsyncValue.data(current.map((g) =>
      g.id == id ? g.copyWith(status: GalleryStatus.closed) : g
    ).toList());
  }

  Future<void> updateGallery(String id, Gallery updated) async {
    final current = state.value ?? [];
    try {
      await ApiService().updateGallery(id, {
        'name': updated.name,
        'description': updated.description,
        'status': updated.status.name,
        'expires_at': updated.expiresAt?.toIso8601String(),
        'password_protected': updated.passwordProtected,
        'password': updated.password,
        'download_setting': updated.downloadSetting.name,
        'print_enabled': updated.printEnabled,
        'theme_color': updated.themeColor.toARGB32(),
        'email_template': updated.emailTemplate,
      });
    } catch (_) {}
    state = AsyncValue.data(current.map((g) => g.id == id ? updated : g).toList());
  }

  void refresh() => _loadGalleries();
}

// ─── Main Screen ──────────────────────────────────────────────────────────────

class GalleriesScreen extends ConsumerStatefulWidget {
  const GalleriesScreen({super.key});

  @override
  ConsumerState<GalleriesScreen> createState() => _GalleriesScreenState();
}

class _GalleriesScreenState extends ConsumerState<GalleriesScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedGalleryId = ref.watch(selectedGalleryIdProvider);

    return Scaffold(
      body: selectedGalleryId == null
          ? _buildListView(context)
          : _buildDetailView(context, selectedGalleryId),
    );
  }

  // ─── List View ─────────────────────────────────────────────────────────────

  Widget _buildListView(BuildContext context) {
    final galleriesAsync = ref.watch(galleriesProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final statusFilter = ref.watch(statusFilterProvider);

    return Column(
      children: [
        _buildToolbar(context, searchQuery, statusFilter),
        Expanded(
          child: galleriesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
            data: (galleries) {
              var filtered = galleries.where((g) {
                final matchesSearch = searchQuery.isEmpty ||
                    g.name.toLowerCase().contains(searchQuery.toLowerCase());
                final matchesStatus = statusFilter == null || g.status == statusFilter;
                return matchesSearch && matchesStatus;
              }).toList();

              if (filtered.isEmpty) {
                return _buildEmptyState(context);
              }

              return _buildGalleryGrid(context, filtered);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar(BuildContext context, String searchQuery, GalleryStatus? statusFilter) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        border: Border(bottom: BorderSide(color: Colors.grey.shade800)),
      ),
      child: Row(
        children: [
          // New Gallery Button
          FilledButton.icon(
            onPressed: () => _showCreateGalleryDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('New Gallery'),
          ),
          const SizedBox(width: 16),
          // Search Field
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 40,
              child: TextField(
                controller: _searchController,
                onChanged: (value) => ref.read(searchQueryProvider.notifier).state = value,
                decoration: InputDecoration(
                  hintText: 'Search galleries...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(searchQueryProvider.notifier).state = '';
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade700),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade700),
                  ),
                  isDense: true,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Status Filter
          _buildStatusFilter(context, statusFilter),
          const SizedBox(width: 16),
          // Refresh
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(galleriesProvider.notifier).refresh(),
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter(BuildContext context, GalleryStatus? statusFilter) {
    return PopupMenuButton<GalleryStatus?>(
      tooltip: 'Filter by status',
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.filter_list,
            color: statusFilter != null
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade400,
          ),
          if (statusFilter != null)
            Container(
              margin: const EdgeInsets.only(left: 4),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
      onSelected: (value) => ref.read(statusFilterProvider.notifier).state = value,
      itemBuilder: (context) => [
        const PopupMenuItem(value: null, child: Text('All Statuses')),
        ...GalleryStatus.values.map((s) => PopupMenuItem(
          value: s,
          child: Row(
            children: [
              _StatusBadge(status: s, compact: true),
              const SizedBox(width: 8),
              Text(_statusLabel(s)),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library_outlined, size: 72, color: Colors.grey.shade600),
          const SizedBox(height: 16),
          Text(
            'No Galleries Yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first gallery to share with clients',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _showCreateGalleryDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Create Gallery'),
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryGrid(BuildContext context, List<Gallery> galleries) {
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 340,
        mainAxisExtent: 260,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: galleries.length,
      itemBuilder: (context, index) {
        return _GalleryCard(gallery: galleries[index]);
      },
    );
  }

  void _showCreateGalleryDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Gallery'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Gallery Name',
            hintText: 'e.g., Johnson Wedding',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              ref.read(galleriesProvider.notifier).createGallery(value.trim());
              Navigator.of(context).pop();
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref.read(galleriesProvider.notifier).createGallery(controller.text.trim());
                Navigator.of(context).pop();
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  // ─── Detail View ───────────────────────────────────────────────────────────

  Widget _buildDetailView(BuildContext context, String galleryId) {
    final galleriesAsync = ref.watch(galleriesProvider);
    final proofingMode = ref.watch(proofingModeProvider);

    return galleriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (galleries) {
        final gallery = galleries.firstWhere(
          (g) => g.id == galleryId,
          orElse: () => galleries.first,
        );

        // Analytics (available for detail view)
        ref.watch(galleryAnalyticsProvider);

        return Row(
          children: [
            // Main content area
            Expanded(
              child: Column(
                children: [
                  _buildDetailToolbar(context, gallery),
                  Expanded(
                    child: proofingMode
                        ? _buildProofingView(context, gallery)
                        : _buildGalleryImageView(context, gallery),
                  ),
                ],
              ),
            ),
            // Right panel
            if (!proofingMode)
              SizedBox(
                width: 360,
                child: _buildEditorPanel(context, gallery),
              ),
          ],
        );
      },
    );
  }

  Widget _buildDetailToolbar(BuildContext context, Gallery gallery) {
    final selectedImages = ref.watch(selectedImagesProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        border: Border(bottom: BorderSide(color: Colors.grey.shade800)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              ref.read(selectedGalleryIdProvider.notifier).state = null;
              ref.read(proofingModeProvider.notifier).state = false;
              ref.read(selectedImagesProvider.notifier).state = {};
              ref.read(editingGalleryProvider.notifier).state = false;
              ref.read(galleryAnalyticsProvider.notifier).state = null;
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gallery.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    _StatusBadge(status: gallery.status),
                    const SizedBox(width: 12),
                    Text(
                      '${gallery.imageCount} images',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                    ),
                    if (gallery.selectedCount > 0) ...[
                      const SizedBox(width: 12),
                      Text(
                        '${gallery.selectedCount} selected',
                        style: const TextStyle(color: Colors.greenAccent, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Proofing mode toggle
          Tooltip(
            message: 'Toggle proofing mode',
            child: Switch(
              value: ref.watch(proofingModeProvider),
              onChanged: (v) => ref.read(proofingModeProvider.notifier).state = v,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'Proofing',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          ),
          const SizedBox(width: 12),
          // Download selected
          FilledButton.icon(
            onPressed: selectedImages.isEmpty
                ? null
                : () => _downloadSelected(context, gallery, selectedImages.toList()),
            icon: const Icon(Icons.download),
            label: Text('Download${selectedImages.isNotEmpty ? ' (${selectedImages.length})' : ''}'),
          ),
          const SizedBox(width: 8),
          // Share
          OutlinedButton.icon(
            onPressed: () => _showShareDialog(context, gallery),
            icon: const Icon(Icons.share),
            label: const Text('Share'),
          ),
          const SizedBox(width: 8),
          // Analytics
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () => _showAnalyticsDialog(context, gallery),
            tooltip: 'Analytics',
          ),
          const SizedBox(width: 8),
          // More options
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) => _handleGalleryAction(context, gallery, value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Edit Settings'),
                contentPadding: EdgeInsets.zero,
              )),
              const PopupMenuItem(value: 'duplicate', child: ListTile(
                leading: Icon(Icons.copy),
                title: Text('Duplicate'),
                contentPadding: EdgeInsets.zero,
              )),
              const PopupMenuItem(value: 'close', child: ListTile(
                leading: Icon(Icons.archive_outlined),
                title: Text('Close Gallery'),
                contentPadding: EdgeInsets.zero,
              )),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'delete', child: ListTile(
                leading: Icon(Icons.delete_outline, color: Colors.red),
                title: Text('Delete', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryImageView(BuildContext context, Gallery gallery) {
    if (gallery.images.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_outlined, size: 64, color: Colors.grey.shade600),
            const SizedBox(height: 16),
            Text(
              'No images in this gallery',
              style: TextStyle(color: Colors.grey.shade400),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gallery action'))),
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Add Images'),
            ),
          ],
        ),
      );
    }

    final selectedImages = ref.watch(selectedImagesProvider);

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 280,
        mainAxisExtent: 220,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: gallery.images.length,
      itemBuilder: (context, index) {
        final image = gallery.images[index];
        final isSelected = selectedImages.contains(image.id);
        final isClientSelected = image.isSelectedByClient;

        return GestureDetector(
          onTap: () {
            final current = {...selectedImages};
            if (isSelected) {
              current.remove(image.id);
            } else {
              current.add(image.id);
            }
            ref.read(selectedImagesProvider.notifier).state = current;
          },
          child: Stack(
            children: [
              // Thumbnail
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isClientSelected
                        ? Colors.greenAccent
                        : isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.shade800,
                    width: isClientSelected ? 3 : (isSelected ? 2 : 1),
                  ),
                  boxShadow: isClientSelected
                      ? [BoxShadow(color: Colors.greenAccent.withValues(alpha: 0.3), blurRadius: 8)]
                      : null,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: Stack(
                    children: [
                      Image.network(
                        image.thumbnailUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey.shade800,
                          child: Icon(Icons.image, color: Colors.grey.shade600, size: 40),
                        ),
                      ),
                      // Gradient overlay
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [Colors.black87, Colors.transparent],
                            ),
                          ),
                          child: Text(
                            image.name,
                            style: const TextStyle(fontSize: 11, color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Client selection indicator
              if (isClientSelected)
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.greenAccent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, size: 12, color: Colors.black),
                  ),
                ),
              // Download/selection checkbox
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isSelected ? Colors.transparent : Colors.white54,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
              ),
              // Selection count badge
              if (image.selectionCount > 0)
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${image.selectionCount}',
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProofingView(BuildContext context, Gallery gallery) {
    return Container(
      color: Color(0xFF1A1A2E),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade700),
              ),
              child: Column(
                children: [
                  Icon(Icons.visibility_outlined, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Proofing Mode',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This is how your client sees the gallery',
                    style: TextStyle(color: Colors.grey.shade400),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '${gallery.selectedCount} client selections',
                      style: const TextStyle(color: Colors.greenAccent, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Show client-selected images
            if (gallery.selectedCount > 0)
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: gallery.images.where((i) => i.isSelectedByClient).length,
                  itemBuilder: (context, index) {
                    final selectedImgs = gallery.images.where((i) => i.isSelectedByClient).toList();
                    final img = selectedImgs[index];
                    return Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.greenAccent, width: 2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          img.thumbnailUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey.shade800,
                            child: const Icon(Icons.image, color: Colors.grey),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Editor Panel ───────────────────────────────────────────────────────────

  Widget _buildEditorPanel(BuildContext context, Gallery gallery) {
    final isEditing = ref.watch(editingGalleryProvider);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        border: Border(left: BorderSide(color: Colors.grey.shade800)),
      ),
      child: Column(
        children: [
          // Panel header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade800)),
            ),
            child: Row(
              children: [
                Icon(Icons.tune, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Gallery Settings',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    ref.read(editingGalleryProvider.notifier).state = !isEditing;
                  },
                  icon: Icon(isEditing ? Icons.check : Icons.edit, size: 16),
                  label: Text(isEditing ? 'Done' : 'Edit'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildSettingsContent(context, gallery, isEditing),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsContent(BuildContext context, Gallery gallery, bool isEditing) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Name
        _buildSettingLabel(context, 'Name'),
        const SizedBox(height: 4),
        TextFormField(
          initialValue: gallery.name,
          enabled: isEditing,
          decoration: _inputDecoration(context),
          onChanged: (value) {
            ref.read(galleriesProvider.notifier).updateGallery(
              gallery.id,
              gallery.copyWith(name: value),
            );
          },
        ),
        const SizedBox(height: 16),

        // Description
        _buildSettingLabel(context, 'Description'),
        const SizedBox(height: 4),
        TextFormField(
          initialValue: gallery.description,
          enabled: isEditing,
          maxLines: 3,
          decoration: _inputDecoration(context),
          onChanged: (value) {
            ref.read(galleriesProvider.notifier).updateGallery(
              gallery.id,
              gallery.copyWith(description: value),
            );
          },
        ),
        const SizedBox(height: 16),

        // Expiration Date
        _buildSettingLabel(context, 'Expiration Date'),
        const SizedBox(height: 4),
        InkWell(
          onTap: isEditing ? () => _pickExpirationDate(context, gallery) : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade700),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade400),
                const SizedBox(width: 8),
                Text(
                  gallery.expiresAt != null
                      ? '${gallery.expiresAt!.year}-${gallery.expiresAt!.month.toString().padLeft(2, '0')}-${gallery.expiresAt!.day.toString().padLeft(2, '0')}'
                      : 'No expiration',
                  style: TextStyle(
                    color: gallery.expiresAt != null ? Colors.white : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Password Protection
        SwitchListTile(
          title: const Text('Password Protection'),
          subtitle: const Text('Require password to access'),
          value: gallery.passwordProtected,
          onChanged: isEditing ? (value) {
            ref.read(galleriesProvider.notifier).updateGallery(
              gallery.id,
              gallery.copyWith(passwordProtected: value),
            );
          } : null,
          contentPadding: EdgeInsets.zero,
        ),
        if (gallery.passwordProtected && isEditing) ...[
          const SizedBox(height: 4),
          TextFormField(
            initialValue: gallery.password,
            decoration: _inputDecoration(context).copyWith(
              hintText: 'Enter password',
              prefixIcon: const Icon(Icons.lock, size: 18),
            ),
            onChanged: (value) {
              ref.read(galleriesProvider.notifier).updateGallery(
                gallery.id,
                gallery.copyWith(password: value),
              );
            },
          ),
        ],
        const SizedBox(height: 16),

        // Download Settings
        _buildSettingLabel(context, 'Download Setting'),
        const SizedBox(height: 4),
        DropdownButtonFormField<DownloadSetting>(
          initialValue: gallery.downloadSetting,
          isExpanded: true,
          decoration: _inputDecoration(context),
          items: DownloadSetting.values.map((s) => DropdownMenuItem(
            value: s,
            child: Text(_downloadSettingLabel(s)),
          )).toList(),
          onChanged: isEditing ? (value) {
            if (value != null) {
              ref.read(galleriesProvider.notifier).updateGallery(
                gallery.id,
                gallery.copyWith(downloadSetting: value),
              );
            }
          } : null,
        ),
        const SizedBox(height: 16),

        // Print Settings
        SwitchListTile(
          title: const Text('Print Orders Enabled'),
          subtitle: const Text('Allow clients to order prints'),
          value: gallery.printEnabled,
          onChanged: isEditing ? (value) {
            ref.read(galleriesProvider.notifier).updateGallery(
              gallery.id,
              gallery.copyWith(printEnabled: value),
            );
          } : null,
          contentPadding: EdgeInsets.zero,
        ),
        if (gallery.printEnabled && isEditing) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['Canvas', 'Metal Print', 'Fine Art', 'Acrylic', 'Wood', 'Poster']
                .map((product) => FilterChip(
                  label: Text(product, style: const TextStyle(fontSize: 12)),
                  selected: gallery.enabledPrintProducts.contains(product),
                  onSelected: (selected) {
                    final products = [...gallery.enabledPrintProducts];
                    if (selected) {
                      products.add(product);
                    } else {
                      products.remove(product);
                    }
                    ref.read(galleriesProvider.notifier).updateGallery(
                      gallery.id,
                      gallery.copyWith(enabledPrintProducts: products),
                    );
                  },
                ))
                .toList(),
          ),
        ],
        const SizedBox(height: 16),

        // Theme Color
        _buildSettingLabel(context, 'Theme Color'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            Color(0xFF6366F1),
            Color(0xFF8B5CF6),
            Color(0xFFEC4899),
            Color(0xFF10B981),
            Color(0xFFF59E0B),
            Color(0xFFEF4444),
            Color(0xFF3B82F6),
            Color(0xFF6B7280),
          ].map((color) => GestureDetector(
            onTap: isEditing ? () {
              ref.read(galleriesProvider.notifier).updateGallery(
                gallery.id,
                gallery.copyWith(themeColor: color),
              );
            } : null,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: gallery.themeColor == color ? Colors.white : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
          )).toList(),
        ),
        const SizedBox(height: 16),

        // Email Template
        _buildSettingLabel(context, 'Delivery Email Template'),
        const SizedBox(height: 4),
        TextFormField(
          initialValue: gallery.emailTemplate,
          enabled: isEditing,
          maxLines: 5,
          decoration: _inputDecoration(context).copyWith(
            hintText: 'Enter email template for gallery delivery...',
          ),
          onChanged: (value) {
            ref.read(galleriesProvider.notifier).updateGallery(
              gallery.id,
              gallery.copyWith(emailTemplate: value),
            );
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  InputDecoration _inputDecoration(BuildContext context) {
    return InputDecoration(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade700),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade700),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
      ),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }

  Widget _buildSettingLabel(BuildContext context, String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Colors.grey.shade400,
      ),
    );
  }

  // ─── Share Dialog ───────────────────────────────────────────────────────────

  void _showShareDialog(BuildContext context, Gallery gallery) {
    showDialog(
      context: context,
      builder: (context) => _ShareDialog(gallery: gallery),
    );
  }

  void _showAnalyticsDialog(BuildContext context, Gallery gallery) {
    // Load sample analytics data
    ref.read(galleryAnalyticsProvider.notifier).state = _generateSampleAnalytics();
    showDialog(
      context: context,
      builder: (context) => _AnalyticsDialog(gallery: gallery),
    );
  }

  void _downloadSelected(BuildContext context, Gallery gallery, List<String> imageIds) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Preparing download for ${imageIds.length} images...'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleGalleryAction(BuildContext context, Gallery gallery, String action) {
    switch (action) {
      case 'edit':
        ref.read(editingGalleryProvider.notifier).state = true;
        break;
      case 'duplicate':
        ref.read(galleriesProvider.notifier).duplicateGallery(gallery.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gallery duplicated')),
        );
        break;
      case 'close':
        ref.read(galleriesProvider.notifier).closeGallery(gallery.id);
        ref.read(selectedGalleryIdProvider.notifier).state = null;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gallery closed')),
        );
        break;
      case 'delete':
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Gallery'),
            content: Text('Are you sure you want to delete "${gallery.name}"? This cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  ref.read(galleriesProvider.notifier).deleteGallery(gallery.id);
                  ref.read(selectedGalleryIdProvider.notifier).state = null;
                  Navigator.of(ctx).pop();
                },
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        break;
    }
  }

  Future<void> _pickExpirationDate(BuildContext context, Gallery gallery) async {
    final date = await showDatePicker(
      context: context,
      initialDate: gallery.expiresAt ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      ref.read(galleriesProvider.notifier).updateGallery(
        gallery.id,
        gallery.copyWith(expiresAt: date),
      );
    }
  }

  String _statusLabel(GalleryStatus status) {
    switch (status) {
      case GalleryStatus.draft: return 'Draft';
      case GalleryStatus.published: return 'Published';
      case GalleryStatus.expired: return 'Expired';
      case GalleryStatus.closed: return 'Closed';
    }
  }

  String _downloadSettingLabel(DownloadSetting setting) {
    switch (setting) {
      case DownloadSetting.fullRes: return 'Full Resolution';
      case DownloadSetting.webRes: return 'Web Resolution';
      case DownloadSetting.disabled: return 'Downloads Disabled';
    }
  }
}

// ─── Gallery Card ─────────────────────────────────────────────────────────────

class _GalleryCard extends ConsumerWidget {
  final Gallery gallery;

  const _GalleryCard({required this.gallery});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          ref.read(selectedGalleryIdProvider.notifier).state = gallery.id;
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail area
            Container(
              height: 130,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    gallery.themeColor.withValues(alpha: 0.3),
                    gallery.themeColor.withValues(alpha: 0.1),
                  ],
                ),
              ),
              child: gallery.images.isNotEmpty
                  ? Stack(
                      children: [
                        // Grid of thumbnails
                        Row(
                          children: [
                            Expanded(
                              child: Image.network(
                                gallery.images[0].thumbnailUrl,
                                fit: BoxFit.cover,
                                height: 130,
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.grey.shade800,
                                  child: Icon(Icons.image, color: Colors.grey.shade600),
                                ),
                              ),
                            ),
                            if (gallery.images.length > 1)
                              Expanded(
                                child: Image.network(
                                  gallery.images[1].thumbnailUrl,
                                  fit: BoxFit.cover,
                                  height: 130,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: Colors.grey.shade800,
                                    child: Icon(Icons.image, color: Colors.grey.shade600),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        // Overlay with view count
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.visibility, size: 12, color: Colors.white70),
                                const SizedBox(width: 4),
                                Text(
                                  '${gallery.viewCount}',
                                  style: const TextStyle(color: Colors.white, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Selected indicator
                        if (gallery.selectedCount > 0)
                          Positioned(
                            bottom: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.greenAccent.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${gallery.selectedCount} selected',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                      ],
                    )
                  : Center(
                      child: Icon(Icons.photo_library_outlined,
                          size: 40, color: Colors.grey.shade600),
                    ),
            ),
            // Info area
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          gallery.name,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _StatusBadge(status: gallery.status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.photo_outlined, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        '${gallery.imageCount} images',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.download_outlined, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        '${gallery.downloadCount}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                  if (gallery.expiresAt != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.timer_outlined, size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          'Expires ${_formatDate(gallery.expiresAt!)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: gallery.expiresAt!.isBefore(DateTime.now())
                                ? Colors.redAccent
                                : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now).inDays;
    if (diff == 0) return 'today';
    if (diff == 1) return 'tomorrow';
    if (diff < 0) return '${-diff}d ago';
    return 'in ${diff}d';
  }
}

// ─── Status Badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final GalleryStatus status;
  final bool compact;

  const _StatusBadge({required this.status, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final (color, label, icon) = switch (status) {
      GalleryStatus.draft => (Colors.grey, 'Draft', Icons.create_outlined),
      GalleryStatus.published => (Colors.green, 'Published', Icons.public),
      GalleryStatus.expired => (Colors.orange, 'Expired', Icons.timer_off),
      GalleryStatus.closed => (Colors.red, 'Closed', Icons.archive_outlined),
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 8, vertical: compact ? 2 : 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(compact ? 8 : 12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 10 : 12, color: color),
          if (!compact) ...[
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Share Dialog ─────────────────────────────────────────────────────────────

class _ShareDialog extends ConsumerWidget {
  final Gallery gallery;

  const _ShareDialog({required this.gallery});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.share, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          const Text('Share Gallery'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Share link
            Text(
              'Share Link',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade700),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      gallery.shareLink,
                      style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: gallery.shareLink));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Link copied to clipboard')),
                      );
                    },
                    tooltip: 'Copy link',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // QR Code placeholder
            Text(
              'QR Code',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_2, size: 100, color: Colors.grey.shade800),
                      const SizedBox(height: 4),
                      Text(
                        'QR Code',
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Send email
            Text(
              'Send via Email',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'client@email.com',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade700),
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Email sent!')),
                    );
                  },
                  icon: const Icon(Icons.send, size: 16),
                  label: const Text('Send'),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

// ─── Analytics Dialog ─────────────────────────────────────────────────────────

class _AnalyticsDialog extends ConsumerWidget {
  final Gallery gallery;

  const _AnalyticsDialog({required this.gallery});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(galleryAnalyticsProvider);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.analytics, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          const Text('Gallery Analytics'),
        ],
      ),
      content: SizedBox(
        width: 600,
        height: 500,
        child: analytics == null
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats row
                  Row(
                    children: [
                      _buildStatCard(context, 'Views', '${gallery.viewCount}', Icons.visibility, Colors.blue),
                      const SizedBox(width: 12),
                      _buildStatCard(context, 'Downloads', '${gallery.downloadCount}', Icons.download, Colors.green),
                      const SizedBox(width: 12),
                      _buildStatCard(context, 'Selections', '${gallery.selectedCount}', Icons.check_circle, Colors.orange),
                      const SizedBox(width: 12),
                      _buildStatCard(context, 'Images', '${gallery.imageCount}', Icons.photo, Colors.purple),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Chart placeholder
                  Text(
                    'Activity Over Time',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade800),
                      ),
                      child: Column(
                        children: [
                          // Simple bar chart visualization
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: analytics.views.take(15).map((point) {
                                final maxVal = analytics.views.map((p) => p.value).reduce(math.max);
                                final height = maxVal > 0 ? (point.value / maxVal) * 120.0 : 0.0;
                                return Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 1),
                                    child: Tooltip(
                                      message: '${point.value} views',
                                      child: Container(
                                        height: height + 4,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const Divider(height: 1),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('15 days ago', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                              Text('Today', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Comments section
                  Text(
                    'Client Comments',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: analytics.comments.length,
                      itemBuilder: (context, index) {
                        final comment = analytics.comments[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                              child: Text(
                                comment.author[0].toUpperCase(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                            title: Text(
                              comment.author,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                            subtitle: Text(
                              comment.text,
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: Text(
                              _formatTimeAgo(comment.createdAt),
                              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
