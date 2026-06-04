import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_player_flutter/services/language_service.dart';

void main() {
  group('LanguageService', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('standaard locale is Nederlands', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = LanguageService(prefs);
      expect(service.locale, const Locale('nl'));
    });

    test('herstelt opgeslagen locale', () async {
      SharedPreferences.setMockInitialValues({'app_locale': 'en'});
      final prefs = await SharedPreferences.getInstance();
      final service = LanguageService(prefs);
      expect(service.locale, const Locale('en'));
    });

    test('setLocale wijzigt de locale', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = LanguageService(prefs);
      await service.setLocale(const Locale('es'));
      expect(service.locale, const Locale('es'));
    });

    test('setLocale slaat locale op in prefs', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = LanguageService(prefs);
      await service.setLocale(const Locale('en'));
      expect(prefs.getString('app_locale'), 'en');
    });

    test('setLocale stuurt notifyListeners', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = LanguageService(prefs);
      int count = 0;
      service.addListener(() => count++);
      await service.setLocale(const Locale('es'));
      expect(count, 1);
    });

    test('setLocale met zelfde locale stuurt geen notifyListeners', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = LanguageService(prefs);
      int count = 0;
      service.addListener(() => count++);
      await service.setLocale(const Locale('nl'));
      expect(count, 0);
    });

    test('supportedLocales bevat nl, en en es', () {
      expect(LanguageService.supportedLocales, containsAll([
        const Locale('nl'),
        const Locale('en'),
        const Locale('es'),
      ]));
    });

    test('alle drie locales kunnen worden ingesteld', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = LanguageService(prefs);

      for (final locale in LanguageService.supportedLocales) {
        await service.setLocale(locale);
        expect(service.locale, locale);
      }
    });
  });
}
