import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_player_flutter/l10n/app_localizations.dart';
import 'package:music_player_flutter/screens/settings_screen.dart';
import 'package:music_player_flutter/services/download_service.dart';
import 'package:music_player_flutter/services/language_service.dart';
import 'package:music_player_flutter/services/theme_service.dart';
import 'package:music_player_flutter/services/translation_service.dart';
import 'package:music_player_flutter/services/update_service.dart';

Widget _buildSettings(
  ThemeService themeService,
  LanguageService langService,
  TranslationService translationService,
  DownloadService downloadService,
  UpdateService updateService,
) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ThemeService>.value(value: themeService),
      ChangeNotifierProvider<LanguageService>.value(value: langService),
      Provider<TranslationService>.value(value: translationService),
      ChangeNotifierProvider<DownloadService>.value(value: downloadService),
      ChangeNotifierProvider<UpdateService>.value(value: updateService),
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
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'Music Player',
      packageName: 'com.example.music_player_flutter',
      version: '1.9.0',
      buildNumber: '9',
      buildSignature: '',
    );
  });

  group('SettingsScreen', () {
    Future<
            (
              ThemeService,
              LanguageService,
              TranslationService,
              DownloadService,
              UpdateService
            )>
        makeServices({String? downloadDir, String? latestTag}) async {
      final prefs = await SharedPreferences.getInstance();
      final update = UpdateService(
          fetchLatestTag: () async => latestTag);
      await update.init();
      return (
        ThemeService(prefs),
        LanguageService(prefs),
        TranslationService(prefs),
        DownloadService(testBaseDir: downloadDir),
        update,
      );
    }

    testWidgets('shows settings title', (tester) async {
      final (theme, lang, trans, dl, update) = await makeServices();
      await tester.pumpWidget(
          _buildSettings(theme, lang, trans, dl, update));
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets(
        'shows Appearance, Language, Storage, Downloads and About sections',
        (tester) async {
      final (theme, lang, trans, dl, update) = await makeServices();
      await tester.pumpWidget(
          _buildSettings(theme, lang, trans, dl, update));
      await tester.pumpAndSettle();
      expect(find.text('APPEARANCE'), findsOneWidget);
      expect(find.text('LANGUAGE'), findsOneWidget);
      expect(find.text('STORAGE'), findsOneWidget);
      expect(find.text('DOWNLOADS'), findsOneWidget);
      expect(find.text('ABOUT'), findsOneWidget);
    });

    testWidgets('shows Theme tile', (tester) async {
      final (theme, lang, trans, dl, update) = await makeServices();
      await tester.pumpWidget(
          _buildSettings(theme, lang, trans, dl, update));
      await tester.pumpAndSettle();
      expect(find.text('Theme'), findsOneWidget);
    });

    testWidgets('shows Language tile', (tester) async {
      final (theme, lang, trans, dl, update) = await makeServices();
      await tester.pumpWidget(
          _buildSettings(theme, lang, trans, dl, update));
      await tester.pumpAndSettle();
      expect(find.text('Language'), findsOneWidget);
    });

    testWidgets('shows Clear cache tile', (tester) async {
      final (theme, lang, trans, dl, update) = await makeServices();
      await tester.pumpWidget(
          _buildSettings(theme, lang, trans, dl, update));
      await tester.pumpAndSettle();
      expect(find.text('Clear cache'), findsOneWidget);
    });

    testWidgets('tapping theme tile opens bottom sheet with options',
        (tester) async {
      final (theme, lang, trans, dl, update) = await makeServices();
      await tester.pumpWidget(
          _buildSettings(theme, lang, trans, dl, update));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Theme'));
      await tester.pumpAndSettle();
      expect(find.text('Dark'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('System default'), findsAtLeastNWidgets(1));
    });

    testWidgets('selecting dark theme updates ThemeService', (tester) async {
      final (theme, lang, trans, dl, update) = await makeServices();
      await tester.pumpWidget(
          _buildSettings(theme, lang, trans, dl, update));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Theme'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();
      expect(theme.themeMode, ThemeMode.dark);
    });

    testWidgets('tapping language tile opens bottom sheet', (tester) async {
      final (theme, lang, trans, dl, update) = await makeServices();
      await tester.pumpWidget(
          _buildSettings(theme, lang, trans, dl, update));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Language'));
      await tester.pumpAndSettle();
      expect(find.text('Nederlands'), findsAtLeastNWidgets(1));
      expect(find.text('English'), findsOneWidget);
      expect(find.text('Español'), findsOneWidget);
    });

    testWidgets('selecting English updates LanguageService', (tester) async {
      final (theme, lang, trans, dl, update) = await makeServices();
      await tester.pumpWidget(
          _buildSettings(theme, lang, trans, dl, update));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Language'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();
      expect(lang.locale, const Locale('en'));
    });

    testWidgets('shows version from pubspec (v1.9.0)', (tester) async {
      final (theme, lang, trans, dl, update) = await makeServices();
      await tester.pumpWidget(
          _buildSettings(theme, lang, trans, dl, update));
      await tester.pumpAndSettle();
      expect(find.text('v1.9.0'), findsOneWidget);
    });

    testWidgets('does not show hardcoded "alfa 0.6.0" label', (tester) async {
      final (theme, lang, trans, dl, update) = await makeServices();
      await tester.pumpWidget(
          _buildSettings(theme, lang, trans, dl, update));
      await tester.pumpAndSettle();
      expect(find.text('alfa 0.6.0'), findsNothing);
    });

    testWidgets('shows GitHub Releases tile', (tester) async {
      final (theme, lang, trans, dl, update) = await makeServices();
      await tester.pumpWidget(
          _buildSettings(theme, lang, trans, dl, update));
      await tester.pumpAndSettle();
      expect(find.text('GitHub Releases'), findsOneWidget);
    });

    testWidgets('shows no update indicator when up to date', (tester) async {
      final (theme, lang, trans, dl, update) =
          await makeServices(latestTag: 'v1.9.0');
      await tester.pumpWidget(
          _buildSettings(theme, lang, trans, dl, update));
      await tester.pumpAndSettle();
      expect(find.text('Update available'), findsNothing);
    });

    testWidgets('shows update indicator when newer version available',
        (tester) async {
      final (theme, lang, trans, dl, update) =
          await makeServices(latestTag: 'v2.0.0');
      await tester.pumpWidget(
          _buildSettings(theme, lang, trans, dl, update));
      await tester.pumpAndSettle();
      expect(find.text('Update available'), findsOneWidget);
    });

    testWidgets('shows Downloads tile with chevron (navigates to screen)',
        (tester) async {
      final (theme, lang, trans, dl, update) = await makeServices();
      await tester.pumpWidget(
          _buildSettings(theme, lang, trans, dl, update));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('Downloads tile shows song count and size summary',
        (tester) async {
      final (theme, lang, trans, dl, update) = await makeServices();
      await tester.pumpWidget(
          _buildSettings(theme, lang, trans, dl, update));
      await tester.pumpAndSettle();
      expect(find.text('0 songs · 0 B'), findsOneWidget);
    });

    testWidgets('tapping Downloads tile navigates to DownloadsScreen',
        (tester) async {
      final (theme, lang, trans, dl, update) = await makeServices();
      await tester.pumpWidget(
          _buildSettings(theme, lang, trans, dl, update));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();
      expect(find.text('Downloads'), findsWidgets);
    });

    testWidgets('cache tile shows translation count and size', (tester) async {
      SharedPreferences.setMockInitialValues({
        'lyrics_translation_1_en': 'hello',
        'lyrics_translation_2_nl': 'dag',
      });
      final prefs = await SharedPreferences.getInstance();
      final theme = ThemeService(prefs);
      final lang = LanguageService(prefs);
      final trans = TranslationService(prefs);
      final dl = DownloadService();
      final update = UpdateService(fetchLatestTag: () async => null);
      await update.init();

      await tester.pumpWidget(_buildSettings(theme, lang, trans, dl, update));
      await tester.pumpAndSettle();

      expect(find.textContaining('2 translations'), findsOneWidget);
    });
  });
}
