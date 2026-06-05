import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_player_flutter/services/theme_service.dart';

void main() {
  group('ThemeService', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('defaults to system theme when no preference saved', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = ThemeService(prefs);
      expect(service.themeMode, ThemeMode.system);
    });

    test('restores saved dark theme', () async {
      SharedPreferences.setMockInitialValues({'app_theme_mode': 'dark'});
      final prefs = await SharedPreferences.getInstance();
      final service = ThemeService(prefs);
      expect(service.themeMode, ThemeMode.dark);
    });

    test('restores saved light theme', () async {
      SharedPreferences.setMockInitialValues({'app_theme_mode': 'light'});
      final prefs = await SharedPreferences.getInstance();
      final service = ThemeService(prefs);
      expect(service.themeMode, ThemeMode.light);
    });

    test('restores saved system theme', () async {
      SharedPreferences.setMockInitialValues({'app_theme_mode': 'system'});
      final prefs = await SharedPreferences.getInstance();
      final service = ThemeService(prefs);
      expect(service.themeMode, ThemeMode.system);
    });

    test('unknown saved value falls back to system', () async {
      SharedPreferences.setMockInitialValues({'app_theme_mode': 'invalid'});
      final prefs = await SharedPreferences.getInstance();
      final service = ThemeService(prefs);
      expect(service.themeMode, ThemeMode.system);
    });

    test('setThemeMode updates themeMode', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = ThemeService(prefs);
      await service.setThemeMode(ThemeMode.dark);
      expect(service.themeMode, ThemeMode.dark);
    });

    test('setThemeMode persists to prefs', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = ThemeService(prefs);
      await service.setThemeMode(ThemeMode.light);
      expect(prefs.getString('app_theme_mode'), 'light');
    });

    test('setThemeMode notifies listeners', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = ThemeService(prefs);
      int count = 0;
      service.addListener(() => count++);
      await service.setThemeMode(ThemeMode.dark);
      expect(count, 1);
    });

    test('setThemeMode with same value does not notify', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = ThemeService(prefs);
      int count = 0;
      service.addListener(() => count++);
      await service.setThemeMode(ThemeMode.system);
      expect(count, 0);
    });

    test('all three modes can be set and persisted', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = ThemeService(prefs);
      for (final mode in ThemeMode.values) {
        await service.setThemeMode(mode);
        expect(service.themeMode, mode);
      }
    });
  });
}
