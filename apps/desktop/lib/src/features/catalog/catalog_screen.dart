import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Catalog state
class CatalogState {
  final List<CatalogFolder> folders;
  final CatalogFolder? selectedFolder;
  final List<CatalogImage> images;
  final Set<String> selectedImageIds;
  final bool isLoading;
  final String? error;
  final String sortBy;
  final bool sortDescending;
  final int thumbnailSize;

  const CatalogState({
    this.folders = const [],
    this.selectedFolder,
    this.images = const [],
    this.selectedImageIds = const {},
    this.isLoading = false,
    this.error,
    this.sortBy = 'date',
    this.sortDescending = true,
    this.thumbnailSize = 200,
  });

  CatalogState copyWith({
    List<CatalogFolder>? folders,
    CatalogFolder? selectedFolder,
    List<CatalogImage>? images,
    Set<String>? selectedImageIds,
    bool? isLoading,
    String? error,
    String? sortBy,
    bool? sortDescending,
    int? thumbnailSize,
  }) {
    return CatalogState(
      folders: folders ?? this.folders,
      selectedFolder: selectedFolder ?? this.selectedFolder,
      images: images ?? this.images,
      selectedImageIds: selectedImageIds ?? this.selectedImageIds,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      sortBy: sortBy ?? this.sortBy,
      sortDescending: sortDescending ?? this.sortDescending,
      thumbnailSize: thumbnailSize ?? this.thumbnailSize,
    );
  }
}

class CatalogFolder {
  final String id;
  final String name;
  final int imageCount;
  final bool isSystem;
  final IconData icon;

  const CatalogFolder({
    required this.id,
    required this.name,
    required this.imageCount,
    this.isSystem = false,
    this.icon = Icons.folder,
  });
}

class CatalogImage {
  final String id;
  final String name;
  final String? thumbnailUrl;
  final DateTime dateTaken;
  final int rating;
  final bool isPicked;
  final double? aiScore;
  final List<String> flags;

  const CatalogImage({
    required this.id,
    required this.name,
    this.thumbnailUrl,
    required this.dateTaken,
    this.rating = 0,
    this.isPicked = true,
    this.aiScore,
    this.flags = const [],
  });
}

class CatalogNotifier extends StateNotifier<CatalogState> {
  CatalogNotifier() : super(const CatalogState()) {
    _loadFolders();
  }

  void _loadFolders() {
    state = state.copyWith(
      folders: [
        CatalogFolder(id: 'all', name: 'All Photos', imageCount: 12847, isSystem: true, icon: Icons.photo_library),
        CatalogFolder(id: 'recent', name: 'Recent', imageCount: 234, isSystem: true, icon: Icons.access_time),
        CatalogFolder(id: 'favorites', name: 'Favorites', imageCount: 456, isSystem: true, icon: Icons.star),
        CatalogFolder(id: 'imports', name: 'Imports', imageCount: 89, isSystem: true, icon: Icons.import_export),
        CatalogFolder(id: 'album_weddings', name: 'Weddings', imageCount: 3420, icon: Icons.favorite),
        CatalogFolder(id: 'album_portraits', name: 'Portraits', imageCount: 2100, icon: Icons.person),
        CatalogFolder(id: 'album_landscapes', name: 'Landscapes', imageCount: 1800, icon: Icons.landscape),
      ],
      selectedFolder: const CatalogFolder(id: 'all', name: 'All Photos', imageCount: 12847, isSystem: true, icon: Icons.photo_library),
    );
  }

  void selectFolder(CatalogFolder folder) {
    state = state.copyWith(selectedFolder: folder);
    _loadImages(folder.id);
  }

  void _loadImages(String folderId) {
    // In production: load from API
    state = state.copyWith(isLoading: true);
    // Simulate loading
    Future.delayed(const Duration(milliseconds: 500), () {
      state = state.copyWith(
        images: List.generate(50, (i) => CatalogImage(
          id: 'img_$i',
          name: 'IMG_${1000 + i}.jpg',
          dateTaken: DateTime.now().subtract(Duration(days: i)),
          rating: i % 6,
          isPicked: i % 3 != 0,
          aiScore: 50 + (i % 50).toDouble(),
          flags: i % 7 == 0 ? ['blurry'] : [],
        )),
        isLoading: false,
      );
    });
  }

  void toggleImageSelection(String id) {
    final selected = Set<String>.from(state.selectedImageIds);
    if (selected.contains(id)) {
      selected.remove(id);
    } else {
      selected.add(id);
    }
    state = state.copyWith(selectedImageIds: selected);
  }

  void selectAll() {
    state = state.copyWith(
      selectedImageIds: state.images.map((i) => i.id).toSet(),
    );
  }

  void deselectAll() {
    state = state.copyWith(selectedImageIds: {});
  }

  void setSort(String sortBy) {
    final descending = state.sortBy == sortBy ? !state.sortDescending : true;
    state = state.copyWith(sortBy: sortBy, sortDescending: descending);
  }

  void setThumbnailSize(int size) {
    state = state.copyWith(thumbnailSize: size);
  }
}

final catalogProvider = StateNotifierProvider<CatalogNotifier, CatalogState>((ref) {
  return CatalogNotifier();
});

class CatalogScreen extends ConsumerWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(catalogProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(state.selectedFolder?.name ?? 'Catalog'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () => _showSearch(context)),
          IconButton(icon: const Icon(Icons.filter_list), onPressed: () => _showSortMenu(context, ref)),
          IconButton(icon: const Icon(Icons.grid_view), onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Grid view')))),
          IconButton(
            icon: const Icon(Icons.add_photo_alternate),
            onPressed: () => _showImportDialog(context),
          ),
        ],
      ),
      body: Row(
        children: [
          // Folder sidebar
          SizedBox(
            width: 220,
            child: _buildFolderSidebar(context, ref, state),
          ),
          const VerticalDivider(width: 1),
          // Main content
          Expanded(
            child: Column(
              children: [
                // Selection bar
                if (state.selectedImageIds.isNotEmpty)
                  _buildSelectionBar(context, ref, state),
                // Image grid
                Expanded(child: _buildImageGrid(context, state)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFolderSidebar(BuildContext context, WidgetRef ref, CatalogState state) {
    return Container(
      color: Theme.of(context).cardTheme.color,
      child: ListView(
        children: [
          ...state.folders.map((folder) => _buildFolderItem(context, ref, folder, state)),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('New Album'),
            onTap: () => _createAlbum(context),
          ),
        ],
      ),
    );
  }

  Widget _buildFolderItem(BuildContext context, WidgetRef ref, CatalogFolder folder, CatalogState state) {
    final isSelected = state.selectedFolder?.id == folder.id;
    return ListTile(
      leading: Icon(folder.icon, color: isSelected ? Color(0xFF6366F1) : Colors.grey),
      title: Text(folder.name, style: TextStyle(
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Color(0xFF6366F1) : null,
      )),
      trailing: Text('${folder.imageCount}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
      selected: isSelected,
      onTap: () => ref.read(catalogProvider.notifier).selectFolder(folder),
    );
  }

  Widget _buildSelectionBar(BuildContext context, WidgetRef ref, CatalogState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Color(0xFF6366F1).withValues(alpha: 0.1),
      child: Row(
        children: [
          Text('${state.selectedImageIds.length} selected'),
          const Spacer(),
          TextButton.icon(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rate — ★'))), icon: const Icon(Icons.star), label: const Text('Rate')),
          TextButton.icon(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add to album'))), icon: const Icon(Icons.folder), label: const Text('Album')),
          TextButton.icon(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Delete — moved to trash'))), icon: const Icon(Icons.delete), label: const Text('Delete')),
          TextButton.icon(onPressed: () => ref.read(catalogProvider.notifier).deselectAll(), icon: const Icon(Icons.close), label: const Text('Deselect')),
        ],
      ),
    );
  }

  Widget _buildImageGrid(BuildContext context, CatalogState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: state.thumbnailSize.toDouble(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: state.images.length,
      itemBuilder: (context, index) {
        final image = state.images[index];
        final isSelected = state.selectedImageIds.contains(image.id);
        return _buildImageTile(context, image, isSelected);
      },
    );
  }

  Widget _buildImageTile(BuildContext context, CatalogImage image, bool isSelected) {
    return GestureDetector(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Open — catalog preview'))),
      onSecondaryTap: () => _showImageMenu(context, image),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Color(0xFF6366F1) : Colors.transparent,
            width: 2,
          ),
          color: Colors.grey.shade900,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Thumbnail placeholder
            Center(child: Icon(Icons.image, size: 40, color: Colors.grey.shade700)),
            // Selection checkbox
            Positioned(
              top: 4,
              left: 4,
              child: Icon(
                isSelected ? Icons.check_circle : Icons.circle_outlined,
                color: isSelected ? Color(0xFF6366F1) : Colors.white54,
                size: 20,
              ),
            ),
            // Rating stars
            if (image.rating > 0)
              Positioned(
                bottom: 4,
                left: 4,
                child: Row(
                  children: List.generate(image.rating, (i) => const Icon(Icons.star, color: Colors.amber, size: 12)),
                ),
              ),
            // AI score
            if (image.aiScore != null)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: _getScoreColor(image.aiScore!),
                  ),
                  child: Text(
                    image.aiScore!.toStringAsFixed(0),
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  void _showSearch(BuildContext context) {}
  void _showSortMenu(BuildContext context, WidgetRef ref) {}
  void _showImportDialog(BuildContext context) {}
  void _createAlbum(BuildContext context) {}
  void _showImageMenu(BuildContext context, CatalogImage image) {}
}
