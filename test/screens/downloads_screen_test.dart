import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_player_flutter/l10n/app_localizations.dart';
import 'package:music_player_flutter/screens/downloads_screen.dart';
import 'package:music_player_flutter/services/download_service.dart';

Widget _buildDownloads(DownloadService downloadService) {
  return ChangeNotifierProvider<DownloadService>.value(
    value: downloadService,
    child: const MaterialApp(
      locale: Locale('en'),
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      home: DownloadsScreen(),
    ),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('DownloadsScreen', () {
    testWidgets('shows Downloads title in app bar', (tester) async {
      final dl = DownloadService();
      await tester.pumpWidget(_buildDownloads(dl));
      await tester.pumpAndSettle();
      expect(find.text('Downloads'), findsOneWidget);
    });

    testWidgets('shows "No downloaded songs" when list is empty',
        (tester) async {
      final dl = DownloadService();
      await tester.pumpWidget(_buildDownloads(dl));
      await tester.pumpAndSettle();
      expect(find.text('No downloaded songs'), findsOneWidget);
    });

    testWidgets('shows "0 songs · 0 B" summary when no downloads',
        (tester) async {
      final dl = DownloadService();
      await tester.pumpWidget(_buildDownloads(dl));
      await tester.pumpAndSettle();
      expect(find.text('0 songs · 0 B'), findsOneWidget);
    });

    testWidgets('shows downloaded song title and size', (tester) async {
      final tempDir =
          await Directory.systemTemp.createTemp('downloads_screen_test_');
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final filePath = '${tempDir.path}/42.mp3';
      await File(filePath).writeAsBytes(List.filled(2048, 0));

      SharedPreferences.setMockInitialValues({
        'downloaded_songs_v1': jsonEncode({
          '42': {
            'path': filePath,
            'title': 'Sample Song',
            'artist': 'Sample Artist'
          },
        }),
      });

      final dl = DownloadService(testBaseDir: tempDir.path);
      await dl.init();

      await tester.pumpWidget(_buildDownloads(dl));
      await tester.pump();
      await tester.pump();

      expect(find.text('Sample Song'), findsOneWidget);
      expect(find.text('Sample Artist · 2.0 KB'), findsOneWidget);
    });

    testWidgets('shows delete button for each downloaded song', (tester) async {
      final tempDir =
          await Directory.systemTemp.createTemp('downloads_screen_btn_test_');
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final filePath = '${tempDir.path}/5.mp3';
      await File(filePath).writeAsBytes([1, 2, 3]);

      SharedPreferences.setMockInitialValues({
        'downloaded_songs_v1': jsonEncode({
          '5': {'path': filePath, 'title': 'Delete Me', 'artist': 'Artist'},
        }),
      });

      final dl = DownloadService(testBaseDir: tempDir.path);
      await dl.init();

      await tester.pumpWidget(_buildDownloads(dl));
      await tester.pump();
      await tester.pump();

      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('delete button removes song from list', (tester) async {
      final tempDir =
          await Directory.systemTemp.createTemp('downloads_screen_del_test_');
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final filePath = '${tempDir.path}/9.mp3';
      await File(filePath).writeAsBytes([1, 2, 3]);

      SharedPreferences.setMockInitialValues({
        'downloaded_songs_v1': jsonEncode({
          '9': {'path': filePath, 'title': 'Gone Song', 'artist': 'Artist'},
        }),
      });

      final dl = DownloadService(testBaseDir: tempDir.path);
      await dl.init();

      await tester.pumpWidget(_buildDownloads(dl));
      await tester.pump();
      await tester.pump();

      expect(find.text('Gone Song'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();

      expect(find.text('Gone Song'), findsNothing);
      expect(find.text('No downloaded songs'), findsOneWidget);
    });

    testWidgets('shows delete all button when songs are present',
        (tester) async {
      final tempDir =
          await Directory.systemTemp.createTemp('downloads_screen_all_test_');
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final filePath = '${tempDir.path}/3.mp3';
      await File(filePath).writeAsBytes([1]);

      SharedPreferences.setMockInitialValues({
        'downloaded_songs_v1': jsonEncode({
          '3': {'path': filePath, 'title': 'A Song', 'artist': 'Artist'},
        }),
      });

      final dl = DownloadService(testBaseDir: tempDir.path);
      await dl.init();

      await tester.pumpWidget(_buildDownloads(dl));
      await tester.pump();
      await tester.pump();

      expect(find.text('Delete all downloads'), findsOneWidget);
    });
  });
}
