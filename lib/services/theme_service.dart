import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _themeKey = 'app_theme_mode';

class ThemeService extends ChangeNotifier {
  final SharedPreferences _prefs;
  late ThemeMode _themeMode;

  ThemeService(this._prefs) {
    final saved = _prefs.getString(_themeKey);
    _themeMode = _fromString(saved);
  }

  ThemeMode get themeMode => _themeMode;

  static ThemeMode _fromString(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String _toString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    await _prefs.setString(_themeKey, _toString(mode));
    notifyListeners();
  }
}
