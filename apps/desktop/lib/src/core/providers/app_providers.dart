import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Theme provider for dark/light mode toggle
final themeProvider = StateNotifierProvider<ThemeNotifier, bool>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<bool> {
  ThemeNotifier() : super(true); // Default to dark mode

  void toggle() {
    state = !state;
  }

  void setDarkMode(bool isDark) {
    state = isDark;
  }
}
