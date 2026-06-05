import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_player_flutter/l10n/app_localizations.dart';
import 'package:music_player_flutter/screens/settings_screen.dart';
import 'package:music_player_flutter/services/language_service.dart';
import 'package:music_player_flutter/services/theme_service.dart';
import 'package:music_player_flutter/services/translation_service.dart';

Widget _buildSettings(
    ThemeService themeService,
    LanguageService langService,
    TranslationService translationService) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ThemeService>.value(value: themeService),
      ChangeNotifierProvider<LanguageService>.value(value: langService),
      Provider<TranslationService>.value(value: translationService),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      home: const SettingsScreen(),
    ),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('SettingsScreen', () {
    Future<(ThemeService, LanguageService, TranslationService)>
        _makeServices() async {
      final prefs = await SharedPreferences.getInstance();
      return (
        ThemeService(prefs),
        LanguageService(prefs),
        TranslationService(prefs),
      );
    }

    testWidgets('shows settings title', (tester) async {
      final (theme, lang, trans) = await _makeServices();
      await tester.pumpWidget(_buildSettings(theme, lang, trans));
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('shows Appearance, Language and Storage sections',
        (tester) async {
      final (theme, lang, trans) = await _makeServices();
      await tester.pumpWidget(_buildSettings(theme, lang, trans));
      await tester.pumpAndSettle();
      expect(find.text('APPEARANCE'), findsOneWidget);
      expect(find.text('LANGUAGE'), findsOneWidget);
      expect(find.text('STORAGE'), findsOneWidget);
    });

    testWidgets('shows Theme tile', (tester) async {
      final (theme, lang, trans) = await _makeServices();
      await tester.pumpWidget(_buildSettings(theme, lang, trans));
      await tester.pumpAndSettle();
      expect(find.text('Theme'), findsOneWidget);
    });

    testWidgets('shows Language tile', (tester) async {
      final (theme, lang, trans) = await _makeServices();
      await tester.pumpWidget(_buildSettings(theme, lang, trans));
      await tester.pumpAndSettle();
      expect(find.text('Language'), findsOneWidget);
    });

    testWidgets('shows Clear cache tile', (tester) async {
      final (theme, lang, trans) = await _makeServices();
      await tester.pumpWidget(_buildSettings(theme, lang, trans));
      await tester.pumpAndSettle();
      expect(find.text('Clear cache'), findsOneWidget);
    });

    testWidgets('tapping theme tile opens bottom sheet with options',
        (tester) async {
      final (theme, lang, trans) = await _makeServices();
      await tester.pumpWidget(_buildSettings(theme, lang, trans));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Theme'));
      await tester.pumpAndSettle();
      expect(find.text('Dark'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      // 'System default' appears in both subtitle and sheet
      expect(find.text('System default'), findsAtLeastNWidgets(1));
    });

    testWidgets('selecting dark theme updates ThemeService', (tester) async {
      final (theme, lang, trans) = await _makeServices();
      await tester.pumpWidget(_buildSettings(theme, lang, trans));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Theme'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();
      expect(theme.themeMode, ThemeMode.dark);
    });

    testWidgets('tapping language tile opens bottom sheet', (tester) async {
      final (theme, lang, trans) = await _makeServices();
      await tester.pumpWidget(_buildSettings(theme, lang, trans));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Language'));
      await tester.pumpAndSettle();
      // 'Nederlands' appears in both tile subtitle and sheet (default locale)
      expect(find.text('Nederlands'), findsAtLeastNWidgets(1));
      expect(find.text('English'), findsOneWidget);
      expect(find.text('Español'), findsOneWidget);
    });

    testWidgets('selecting English updates LanguageService', (tester) async {
      final (theme, lang, trans) = await _makeServices();
      await tester.pumpWidget(_buildSettings(theme, lang, trans));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Language'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();
      expect(lang.locale, const Locale('en'));
    });

    testWidgets('shows version label', (tester) async {
      final (theme, lang, trans) = await _makeServices();
      await tester.pumpWidget(_buildSettings(theme, lang, trans));
      await tester.pumpAndSettle();
      expect(find.text('alfa 0.6.0'), findsOneWidget);
    });
  });
}
