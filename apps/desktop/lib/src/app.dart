import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/dashboard/dashboard_screen.dart';
import 'features/catalog/catalog_screen.dart';
import 'features/editor/editor_screen.dart';
import 'features/culling/culling_screen.dart';
import 'features/batch/batch_screen.dart';
import 'features/galleries/galleries_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/tether/tether_panel.dart';
import 'features/verticals/vertical_packs.dart';
import 'features/export/export_presets.dart';
import 'features/marketplace/marketplace_panel.dart';
import 'features/sync/sync_panel.dart';
import 'features/studio/studio_panel.dart';
import 'core/providers/app_providers.dart';

class LumosApp extends ConsumerWidget {
  const LumosApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Lumos AI',
      debugShowCheckedModeBanner: false,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      home: const MainScreen(),
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6366F1),
        brightness: Brightness.light,
      ),
      textTheme: GoogleFonts.interTextTheme(),
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6366F1),
        brightness: Brightness.dark,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
      ),
    );
  }
}

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    CatalogScreen(),
    EditorScreen(),
    CullingScreen(),
    BatchScreen(),
    GalleriesScreen(),
    TetherPanel(),
    VerticalPacksPanel(),
    ExportPresetsPanel(),
    MarketplacePanel(),
    SyncPanel(),
    StudioPanel(),
    SettingsScreen(),
  ];

  final List<NavigationItem> _navItems = const [
    NavigationItem(icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard, label: 'Dashboard'),
    NavigationItem(icon: Icons.folder_open, selectedIcon: Icons.folder, label: 'Catalog'),
    NavigationItem(icon: Icons.edit_outlined, selectedIcon: Icons.edit, label: 'Editor'),
    NavigationItem(icon: Icons.auto_awesome_outlined, selectedIcon: Icons.auto_awesome, label: 'AI Cull'),
    NavigationItem(icon: Icons.build_outlined, selectedIcon: Icons.build, label: 'Batch'),
    NavigationItem(icon: Icons.photo_library_outlined, selectedIcon: Icons.photo_library, label: 'Galleries'),
    NavigationItem(icon: Icons.videocam_outlined, selectedIcon: Icons.videocam, label: 'Tether'),
    NavigationItem(icon: Icons.style_outlined, selectedIcon: Icons.style, label: 'Verticals'),
    NavigationItem(icon: Icons.ios_share_outlined, selectedIcon: Icons.ios_share, label: 'Export'),
    NavigationItem(icon: Icons.store_outlined, selectedIcon: Icons.store, label: 'Market'),
    NavigationItem(icon: Icons.cloud_outlined, selectedIcon: Icons.cloud, label: 'Sync'),
    NavigationItem(icon: Icons.business_center_outlined, selectedIcon: Icons.business_center, label: 'Studio'),
    NavigationItem(icon: Icons.settings_outlined, selectedIcon: Icons.settings, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) => setState(() => _selectedIndex = index),
            extended: false,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            leading: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'LUMOS AI',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            destinations: _navItems
                .map((item) => NavigationRailDestination(
                      icon: Icon(item.icon),
                      selectedIcon: Icon(item.selectedIcon),
                      label: Text(item.label),
                    ))
                .toList(),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: _screens[_selectedIndex]),
        ],
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const NavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}
