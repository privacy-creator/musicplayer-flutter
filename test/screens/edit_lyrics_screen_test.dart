import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_player_flutter/l10n/app_localizations.dart';
import 'package:music_player_flutter/l10n/app_localizations_en.dart';
import 'package:music_player_flutter/models/song.dart';
import 'package:music_player_flutter/screens/edit_lyrics_screen.dart';
import 'package:music_player_flutter/screens/lrc_sync_screen.dart';

import '../helpers/fake_sync_playback.dart';

Song _song({String? lyrics, String? lyricsLrc}) => Song(
      id: 3,
      title: 'Test',
      artist: 'Artist',
      genre: 'Pop',
      language: 'English',
      year: 2024,
      duration: 180,
      audioUrl: 'https://example.com/3.mp3',
      lyrics: lyrics,
      lyricsLrc: lyricsLrc,
    );

final l10n = AppL10nEn();

void main() {
  late FakeSyncPlayback playback;

  setUp(() => playback = FakeSyncPlayback());

  Future<void> pumpEditor(WidgetTester tester, Song song) async {
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      home: EditLyricsScreen(song: song, syncPlayback: playback),
    ));
    await tester.pumpAndSettle();
  }

  String editorText(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField)).controller!.text;

  Future<void> openSyncTool(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('open-sync-tool')));
    await tester.pumpAndSettle();
  }

  group('EditLyricsScreen — sync-tool', () {
    testWidgets('toont de knop om per regel te synchroniseren',
        (tester) async {
      await pumpEditor(tester, _song());
      expect(find.text(l10n.syncLyricsTool), findsOneWidget);
    });

    testWidgets('lege editor gebruikt de platte lyrics van het nummer',
        (tester) async {
      await pumpEditor(tester, _song(lyrics: 'Regel een\nRegel twee'));
      await openSyncTool(tester);
      expect(find.byType(LrcSyncScreen), findsOneWidget);
      expect(find.text('Regel een'), findsOneWidget);
      expect(find.text('Regel twee'), findsOneWidget);
    });

    testWidgets('gebruikt de tekst uit de editor als die er is',
        (tester) async {
      await pumpEditor(
          tester, _song(lyrics: 'Plat', lyricsLrc: '[00:01.00] Uit LRC'));
      await openSyncTool(tester);
      expect(find.text('Uit LRC'), findsOneWidget);
      expect(find.text('Plat'), findsNothing);
    });

    testWidgets('Klaar zet het resultaat in de editor', (tester) async {
      await pumpEditor(tester, _song(lyrics: 'Een\nTwee'));
      await openSyncTool(tester);

      playback.position = const Duration(seconds: 1);
      await tester.tap(find.byKey(const Key('sync-stamp')));
      await tester.pump();
      playback.position = const Duration(seconds: 2, milliseconds: 500);
      await tester.tap(find.byKey(const Key('sync-stamp')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('sync-done')));
      await tester.pumpAndSettle();

      expect(find.byType(LrcSyncScreen), findsNothing);
      expect(editorText(tester), '[00:01.00] Een\n[00:02.50] Twee');
    });

    testWidgets('terug zonder Klaar laat de editor ongewijzigd',
        (tester) async {
      await pumpEditor(tester, _song(lyricsLrc: '[00:01.00] Een'));
      await openSyncTool(tester);
      await tester.tap(find.text('Een'));
      await tester.pump();
      await tester.tap(find.byKey(const Key('sync-stamp')));
      await tester.pump();
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(editorText(tester), '[00:01.00] Een');
    });

    testWidgets('zonder regels toont de tool uitleg', (tester) async {
      await pumpEditor(tester, _song());
      await openSyncTool(tester);
      expect(find.text(l10n.syncNoLines), findsOneWidget);
    });
  });
}
