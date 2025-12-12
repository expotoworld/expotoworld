import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences async provider
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

/// Theme mode provider for managing dark/light mode
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(() {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const String _themeKey = 'theme_mode';

  @override
  ThemeMode build() {
    // Start with system default, then load from prefs
    _loadTheme();
    return ThemeMode.system;
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_themeKey);
    switch (savedTheme) {
      case 'light':
        state = ThemeMode.light;
        break;
      case 'dark':
        state = ThemeMode.dark;
        break;
      default:
        state = ThemeMode.system;
    }
  }

  /// Toggle between light and dark mode
  Future<void> toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    if (state == ThemeMode.light) {
      state = ThemeMode.dark;
      await prefs.setString(_themeKey, 'dark');
    } else {
      state = ThemeMode.light;
      await prefs.setString(_themeKey, 'light');
    }
  }

  /// Set specific theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    state = mode;
    switch (mode) {
      case ThemeMode.light:
        await prefs.setString(_themeKey, 'light');
        break;
      case ThemeMode.dark:
        await prefs.setString(_themeKey, 'dark');
        break;
      case ThemeMode.system:
        await prefs.remove(_themeKey);
        break;
    }
  }

  /// Check if current theme is dark
  bool isDark(BuildContext context) {
    if (state == ThemeMode.system) {
      return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    }
    return state == ThemeMode.dark;
  }
}
