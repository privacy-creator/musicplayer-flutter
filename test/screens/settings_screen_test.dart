import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_player_flutter/l10n/app_localizations.dart';
import 'package:music_player_flutter/screens/settings_screen.dart';
import 'package:music_player_flutter/services/download_service.dart';
import 'package:music_player_flutter/services/language_service.dart';
import 'package:music_player_flutter/services/theme_service.dart';
import 'package:music_player_flutter/services/translation_service.dart';

Widget _buildSettings(
    ThemeService themeService,
    LanguageService langService,
    TranslationService translationService,
    DownloadService downloadService) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ThemeService>.value(value: themeService),
      ChangeNotifierProvider<LanguageService>.value(value: langService),
      Provider<TranslationService>.value(value: translationService),
      ChangeNotifierProvider<DownloadService>.value(value: downloadService),
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
    Future<
            (
              ThemeService,
              LanguageService,
              TranslationService,
              DownloadService
            )>
        makeServices({String? downloadDir}) async {
      final prefs = await SharedPreferences.getInstance();
      return (
        ThemeService(prefs),
        LanguageService(prefs),
        TranslationService(prefs),
        DownloadService(testBaseDir: downloadDir),
      );
    }

    testWidgets('shows settings title', (tester) async {
      final (theme, lang, trans, dl) = await makeServices();
      await tester.pumpWidget(_buildSettings(theme, lang, trans, dl));
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('shows Appearance, Language, Storage and Downloads sections',
        (tester) async {
      final (theme, lang, trans, dl) = await makeServices();
      await tester.pumpWidget(_buildSettings(theme, lang, trans, dl));
      await tester.pumpAndSettle();
      expect(find.text('APPEARANCE'), findsOneWidget);
      expect(find.text('LANGUAGE'), findsOneWidget);
      expect(find.text('STORAGE'), findsOneWidget);
      expect(find.text('DOWNLOADS'), findsOneWidget);
    });

    testWidgets('shows Theme tile', (tester) async {
      final (theme, lang, trans, dl) = await makeServices();
      await tester.pumpWidget(_buildSettings(theme, lang, trans, dl));
      await tester.pumpAndSettle();
      expect(find.text('Theme'), findsOneWidget);
    });

    testWidgets('shows Language tile', (tester) async {
      final (theme, lang, trans, dl) = await makeServices();
      await tester.pumpWidget(_buildSettings(theme, lang, trans, dl));
      await tester.pumpAndSettle();
      expect(find.text('Language'), findsOneWidget);
    });

    testWidgets('shows Clear cache tile', (tester) async {
      final (theme, lang, trans, dl) = await makeServices();
      await tester.pumpWidget(_buildSettings(theme, lang, trans, dl));
      await tester.pumpAndSettle();
      expect(find.text('Clear cache'), findsOneWidget);
    });

    testWidgets('tapping theme tile opens bottom sheet with options',
        (tester) async {
      final (theme, lang, trans, dl) = await makeServices();
      await tester.pumpWidget(_buildSettings(theme, lang, trans, dl));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Theme'));
      await tester.pumpAndSettle();
      expect(find.text('Dark'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('System default'), findsAtLeastNWidgets(1));
    });

    testWidgets('selecting dark theme updates ThemeService', (tester) async {
      final (theme, lang, trans, dl) = await makeServices();
      await tester.pumpWidget(_buildSettings(theme, lang, trans, dl));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Theme'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();
      expect(theme.themeMode, ThemeMode.dark);
    });

    testWidgets('tapping language tile opens bottom sheet', (tester) async {
      final (theme, lang, trans, dl) = await makeServices();
      await tester.pumpWidget(_buildSettings(theme, lang, trans, dl));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Language'));
      await tester.pumpAndSettle();
      expect(find.text('Nederlands'), findsAtLeastNWidgets(1));
      expect(find.text('English'), findsOneWidget);
      expect(find.text('Español'), findsOneWidget);
    });

    testWidgets('selecting English updates LanguageService', (tester) async {
      final (theme, lang, trans, dl) = await makeServices();
      await tester.pumpWidget(_buildSettings(theme, lang, trans, dl));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Language'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();
      expect(lang.locale, const Locale('en'));
    });

    testWidgets('shows version label', (tester) async {
      final (theme, lang, trans, dl) = await makeServices();
      await tester.pumpWidget(_buildSettings(theme, lang, trans, dl));
      await tester.pumpAndSettle();
      expect(find.text('alfa 0.6.0'), findsOneWidget);
    });

    testWidgets('shows "No downloaded songs" when downloads list is empty',
        (tester) async {
      final (theme, lang, trans, dl) = await makeServices();
      await tester.pumpWidget(_buildSettings(theme, lang, trans, dl));
      await tester.pumpAndSettle();
      expect(find.text('No downloaded songs'), findsOneWidget);
    });

    testWidgets('shows "0 songs · 0 B" summary when no downloads',
        (tester) async {
      final (theme, lang, trans, dl) = await makeServices();
      await tester.pumpWidget(_buildSettings(theme, lang, trans, dl));
      await tester.pumpAndSettle();
      expect(find.text('0 songs · 0 B'), findsOneWidget);
    });

    testWidgets('shows downloaded song title and delete button',
        (tester) async {
      final tempDir =
          await Directory.systemTemp.createTemp('settings_dl_test_');
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final filePath = '${tempDir.path}/99.mp3';
      await File(filePath).writeAsBytes(List.filled(1024, 0));

      SharedPreferences.setMockInitialValues({
        'downloaded_songs_v1': jsonEncode({
          '99': {'path': filePath, 'title': 'Test Song', 'artist': 'Test Artist'},
        }),
      });

      final (theme, lang, trans, dl) = await makeServices(downloadDir: tempDir.path);
      await dl.init();

      await tester.pumpWidget(_buildSettings(theme, lang, trans, dl));
      await tester.pumpAndSettle();

      expect(find.text('Test Song'), findsOneWidget);
      expect(find.text('Test Artist · 1.0 KB'), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('delete button removes song from list', (tester) async {
      final tempDir =
          await Directory.systemTemp.createTemp('settings_dl_del_test_');
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final filePath = '${tempDir.path}/7.mp3';
      await File(filePath).writeAsBytes([1, 2, 3]);

      SharedPreferences.setMockInitialValues({
        'downloaded_songs_v1': jsonEncode({
          '7': {'path': filePath, 'title': 'Song To Delete', 'artist': 'Artist'},
        }),
      });

      final (theme, lang, trans, dl) = await makeServices(downloadDir: tempDir.path);
      await dl.init();

      await tester.pumpWidget(_buildSettings(theme, lang, trans, dl));
      await tester.pumpAndSettle();

      expect(find.text('Song To Delete'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.text('Song To Delete'), findsNothing);
      expect(find.text('No downloaded songs'), findsOneWidget);
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

      await tester.pumpWidget(_buildSettings(theme, lang, trans, dl));
      await tester.pumpAndSettle();

      expect(find.textContaining('2 translations'), findsOneWidget);
    });
  });
}
