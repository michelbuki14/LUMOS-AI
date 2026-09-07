import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Settings provider
final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});

/// Application settings
class AppSettings {
  final bool darkMode;
  final bool gpuAcceleration;
  final String inferenceDevice; // 'cuda', 'cpu', 'tensorrt'
  final double cacheSizeGB;
  final bool autoSave;
  final int autoSaveIntervalSeconds;
  final String defaultExportFormat;
  final int defaultJpegQuality;
  final bool showHistogram;
  final bool showClipping;
  final String keymap; // 'default', 'lightroom', 'capture_one'
  final String language;
  final double uiScale;
  final bool animationsEnabled;
  final bool soundEffects;

  const AppSettings({
    this.darkMode = true,
    this.gpuAcceleration = true,
    this.inferenceDevice = 'cuda',
    this.cacheSizeGB = 4.0,
    this.autoSave = true,
    this.autoSaveIntervalSeconds = 30,
    this.defaultExportFormat = 'jpeg',
    this.defaultJpegQuality = 90,
    this.showHistogram = true,
    this.showClipping = true,
    this.keymap = 'default',
    this.language = 'en',
    this.uiScale = 1.0,
    this.animationsEnabled = true,
    this.soundEffects = false,
  });

  AppSettings copyWith({
    bool? darkMode,
    bool? gpuAcceleration,
    String? inferenceDevice,
    double? cacheSizeGB,
    bool? autoSave,
    int? autoSaveIntervalSeconds,
    String? defaultExportFormat,
    int? defaultJpegQuality,
    bool? showHistogram,
    bool? showClipping,
    String? keymap,
    String? language,
    double? uiScale,
    bool? animationsEnabled,
    bool? soundEffects,
  }) {
    return AppSettings(
      darkMode: darkMode ?? this.darkMode,
      gpuAcceleration: gpuAcceleration ?? this.gpuAcceleration,
      inferenceDevice: inferenceDevice ?? this.inferenceDevice,
      cacheSizeGB: cacheSizeGB ?? this.cacheSizeGB,
      autoSave: autoSave ?? this.autoSave,
      autoSaveIntervalSeconds: autoSaveIntervalSeconds ?? this.autoSaveIntervalSeconds,
      defaultExportFormat: defaultExportFormat ?? this.defaultExportFormat,
      defaultJpegQuality: defaultJpegQuality ?? this.defaultJpegQuality,
      showHistogram: showHistogram ?? this.showHistogram,
      showClipping: showClipping ?? this.showClipping,
      keymap: keymap ?? this.keymap,
      language: language ?? this.language,
      uiScale: uiScale ?? this.uiScale,
      animationsEnabled: animationsEnabled ?? this.animationsEnabled,
      soundEffects: soundEffects ?? this.soundEffects,
    );
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(const AppSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    state = AppSettings(
      darkMode: prefs.getBool('dark_mode') ?? true,
      gpuAcceleration: prefs.getBool('gpu_acceleration') ?? true,
      inferenceDevice: prefs.getString('inference_device') ?? 'cuda',
      cacheSizeGB: prefs.getDouble('cache_size_gb') ?? 4.0,
      autoSave: prefs.getBool('auto_save') ?? true,
      autoSaveIntervalSeconds: prefs.getInt('auto_save_interval') ?? 30,
      defaultExportFormat: prefs.getString('default_export_format') ?? 'jpeg',
      defaultJpegQuality: prefs.getInt('default_jpeg_quality') ?? 90,
      showHistogram: prefs.getBool('show_histogram') ?? true,
      showClipping: prefs.getBool('show_clipping') ?? true,
      keymap: prefs.getString('keymap') ?? 'default',
      language: prefs.getString('language') ?? 'en',
      uiScale: prefs.getDouble('ui_scale') ?? 1.0,
      animationsEnabled: prefs.getBool('animations_enabled') ?? true,
      soundEffects: prefs.getBool('sound_effects') ?? false,
    );
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', state.darkMode);
    await prefs.setBool('gpu_acceleration', state.gpuAcceleration);
    await prefs.setString('inference_device', state.inferenceDevice);
    await prefs.setDouble('cache_size_gb', state.cacheSizeGB);
    await prefs.setBool('auto_save', state.autoSave);
    await prefs.setInt('auto_save_interval', state.autoSaveIntervalSeconds);
    await prefs.setString('default_export_format', state.defaultExportFormat);
    await prefs.setInt('default_jpeg_quality', state.defaultJpegQuality);
    await prefs.setBool('show_histogram', state.showHistogram);
    await prefs.setBool('show_clipping', state.showClipping);
    await prefs.setString('keymap', state.keymap);
    await prefs.setString('language', state.language);
    await prefs.setDouble('ui_scale', state.uiScale);
    await prefs.setBool('animations_enabled', state.animationsEnabled);
    await prefs.setBool('sound_effects', state.soundEffects);
  }

  void setDarkMode(bool value) { state = state.copyWith(darkMode: value); _saveSettings(); }
  void setGpuAcceleration(bool value) { state = state.copyWith(gpuAcceleration: value); _saveSettings(); }
  void setInferenceDevice(String value) { state = state.copyWith(inferenceDevice: value); _saveSettings(); }
  void setCacheSize(double value) { state = state.copyWith(cacheSizeGB: value); _saveSettings(); }
  void setAutoSave(bool value) { state = state.copyWith(autoSave: value); _saveSettings(); }
  void setDefaultExportFormat(String value) { state = state.copyWith(defaultExportFormat: value); _saveSettings(); }
  void setDefaultJpegQuality(int value) { state = state.copyWith(defaultJpegQuality: value); _saveSettings(); }
  void setKeymap(String value) { state = state.copyWith(keymap: value); _saveSettings(); }
  void setUiScale(double value) { state = state.copyWith(uiScale: value); _saveSettings(); }
  void setAnimationsEnabled(bool value) { state = state.copyWith(animationsEnabled: value); _saveSettings(); }
  void setShowHistogram(bool value) { state = state.copyWith(showHistogram: value); _saveSettings(); }
  void setShowClipping(bool value) { state = state.copyWith(showClipping: value); _saveSettings(); }
  void reset() { state = const AppSettings(); _saveSettings(); }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          TextButton.icon(
            onPressed: () => _resetToDefaults(ref),
            icon: const Icon(Icons.restore),
            label: const Text('Reset'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildSection(context, 'Appearance', [
            SwitchListTile(
              title: const Text('Dark Mode'),
              subtitle: const Text('Use dark theme throughout the app'),
              value: settings.darkMode,
              onChanged: (v) => ref.read(settingsProvider.notifier).setDarkMode(v),
            ),
            ListTile(
              title: const Text('UI Scale'),
              subtitle: Slider(
                value: settings.uiScale,
                min: 0.8,
                max: 1.5,
                divisions: 7,
                label: '${(settings.uiScale * 100).toStringAsFixed(0)}%',
                onChanged: (v) => ref.read(settingsProvider.notifier).setUiScale(v),
              ),
            ),
            SwitchListTile(
              title: const Text('Animations'),
              value: settings.animationsEnabled,
              onChanged: (v) => ref.read(settingsProvider.notifier).setAnimationsEnabled(v),
            ),
          ]),
          _buildSection(context, 'Performance', [
            SwitchListTile(
              title: const Text('GPU Acceleration'),
              subtitle: const Text('Use GPU for image processing'),
              value: settings.gpuAcceleration,
              onChanged: (v) => ref.read(settingsProvider.notifier).setGpuAcceleration(v),
            ),
            ListTile(
              title: const Text('Inference Device'),
              subtitle: DropdownButton<String>(
                value: settings.inferenceDevice,
                items: const [
                  DropdownMenuItem(value: 'cuda', child: Text('NVIDIA CUDA')),
                  DropdownMenuItem(value: 'tensorrt', child: Text('TensorRT')),
                  DropdownMenuItem(value: 'cpu', child: Text('CPU Only')),
                ],
                onChanged: (v) => ref.read(settingsProvider.notifier).setInferenceDevice(v!),
              ),
            ),
            ListTile(
              title: const Text('Cache Size'),
              subtitle: Slider(
                value: settings.cacheSizeGB,
                min: 1.0,
                max: 16.0,
                divisions: 15,
                label: '${settings.cacheSizeGB.toStringAsFixed(1)} GB',
                onChanged: (v) => ref.read(settingsProvider.notifier).setCacheSize(v),
              ),
            ),
          ]),
          _buildSection(context, 'Editing', [
            SwitchListTile(
              title: const Text('Auto Save'),
              subtitle: const Text('Automatically save edits'),
              value: settings.autoSave,
              onChanged: (v) => ref.read(settingsProvider.notifier).setAutoSave(v),
            ),
            SwitchListTile(
              title: const Text('Show Histogram'),
              value: settings.showHistogram,
              onChanged: (v) => ref.read(settingsProvider.notifier).setShowHistogram(v),
            ),
            SwitchListTile(
              title: const Text('Show Clipping Warning'),
              value: settings.showClipping,
              onChanged: (v) => ref.read(settingsProvider.notifier).setShowClipping(v),
            ),
            ListTile(
              title: const Text('Keymap'),
              subtitle: DropdownButton<String>(
                value: settings.keymap,
                items: const [
                  DropdownMenuItem(value: 'default', child: Text('LUMOS Default')),
                  DropdownMenuItem(value: 'lightroom', child: Text('Adobe Lightroom')),
                  DropdownMenuItem(value: 'capture_one', child: Text('Capture One')),
                ],
                onChanged: (v) => ref.read(settingsProvider.notifier).setKeymap(v!),
              ),
            ),
          ]),
          _buildSection(context, 'Export', [
            ListTile(
              title: const Text('Default Format'),
              subtitle: DropdownButton<String>(
                value: settings.defaultExportFormat,
                items: const [
                  DropdownMenuItem(value: 'jpeg', child: Text('JPEG')),
                  DropdownMenuItem(value: 'png', child: Text('PNG')),
                  DropdownMenuItem(value: 'tiff', child: Text('TIFF')),
                  DropdownMenuItem(value: 'webp', child: Text('WebP')),
                ],
                onChanged: (v) => ref.read(settingsProvider.notifier).setDefaultExportFormat(v!),
              ),
            ),
            ListTile(
              title: const Text('Default JPEG Quality'),
              subtitle: Slider(
                value: settings.defaultJpegQuality.toDouble(),
                min: 50,
                max: 100,
                divisions: 10,
                label: '${settings.defaultJpegQuality}%',
                onChanged: (v) => ref.read(settingsProvider.notifier).setDefaultJpegQuality(v.toInt()),
              ),
            ),
          ]),
          _buildSection(context, 'About', [
            const ListTile(
              title: Text('Version'),
              subtitle: Text('LUMOS AI v1.0.0'),
            ),
            ListTile(
              title: const Text('License'),
              subtitle: const Text('Apache 2.0 — LUMOS AI Contributors'),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  void _resetToDefaults(WidgetRef ref) {
    ref.read(settingsProvider.notifier).reset();
  }
}
