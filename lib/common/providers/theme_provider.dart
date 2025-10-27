import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:locally/common/services/theme/theme_service.dart';

final themeProvider =
    StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) => ThemeNotifier());

class ThemeNotifier extends StateNotifier<ThemeMode> {
  final _service = ThemeService();

  ThemeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final mode = await _service.loadThemeMode();
    state = mode;
  }

  Future<void> toggleTheme() async {
    final newMode =
        state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    state = newMode;
    await _service.saveThemeMode(newMode);
  }
}
