import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_player_flutter/l10n/app_localizations.dart';
import 'package:music_player_flutter/l10n/app_localizations_en.dart';
import 'package:music_player_flutter/models/song.dart';
import 'package:music_player_flutter/screens/lrc_sync_screen.dart';

import '../helpers/fake_sync_playback.dart';

final _song = Song(
  id: 7,
  title: 'Test',
  artist: 'Artist',
  genre: 'Pop',
  language: 'English',
  year: 2024,
  duration: 180,
  audioUrl: 'https://example.com/7.mp3',
);

final l10n = AppL10nEn();

void main() {
  late FakeSyncPlayback playback;

  setUp(() => playback = FakeSyncPlayback());

  /// Hosts the sync screen behind a button so we can capture the pop result.
  Future<List<String?>> pumpSync(WidgetTester tester, String text) async {
    final results = <String?>[];
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async {
              results.add(await Navigator.push<String>(
                context,
                MaterialPageRoute(
                  builder: (_) => LrcSyncScreen(
                    song: _song,
                    initialText: text,
                    playback: playback,
                  ),
                ),
              ));
            },
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return results;
  }

  Future<void> stampAt(WidgetTester tester, Duration at) async {
    playback.position = at;
    await tester.tap(find.byKey(const Key('sync-stamp')));
    await tester.pumpAndSettle();
  }

  Text timeText(WidgetTester tester, int i) => tester.widget<Text>(find.descendant(
      of: find.byKey(Key('sync-time-$i')), matching: find.byType(Text)));

  group('LrcSyncScreen — weergave', () {
    testWidgets('toont alle regels met lege tijden voor platte tekst',
        (tester) async {
      await pumpSync(tester, 'Een\nTwee\nDrie');
      expect(find.text('Een'), findsOneWidget);
      expect(find.text('Twee'), findsOneWidget);
      expect(find.text('Drie'), findsOneWidget);
      expect(find.text('--:--.--'), findsNWidgets(3));
      expect(find.text(l10n.syncProgress(0, 3)), findsOneWidget);
    });

    testWidgets('toont bestaande tijden uit LRC', (tester) async {
      await pumpSync(tester, '[00:12.30] Een\nTwee');
      expect(timeText(tester, 0).data, '00:12.30');
      expect(timeText(tester, 1).data, '--:--.--');
      expect(find.text(l10n.syncProgress(1, 2)), findsOneWidget);
    });

    testWidgets('lege tekst toont uitleg en Klaar is uitgeschakeld',
        (tester) async {
      await pumpSync(tester, '   ');
      expect(find.text(l10n.syncNoLines), findsOneWidget);
      final done =
          tester.widget<TextButton>(find.byKey(const Key('sync-done')));
      expect(done.onPressed, isNull);
    });
  });

  group('LrcSyncScreen — tikken', () {
    testWidgets('Tijd vastleggen legt de huidige positie vast',
        (tester) async {
      await pumpSync(tester, 'Een\nTwee');
      await stampAt(tester, const Duration(seconds: 3, milliseconds: 450));
      expect(timeText(tester, 0).data, '00:03.45');
      expect(find.text(l10n.syncProgress(1, 2)), findsOneWidget);
    });

    testWidgets('opeenvolgende tikken lopen de regels af', (tester) async {
      final results = await pumpSync(tester, 'Een\nTwee\nDrie');
      await stampAt(tester, const Duration(seconds: 1));
      await stampAt(tester, const Duration(seconds: 2));
      await stampAt(tester, const Duration(seconds: 3));

      await tester.tap(find.byKey(const Key('sync-done')));
      await tester.pumpAndSettle();
      expect(results.single,
          '[00:01.00] Een\n[00:02.00] Twee\n[00:03.00] Drie');
    });

    testWidgets('knop is uitgeschakeld na de laatste regel', (tester) async {
      await pumpSync(tester, 'Een');
      await stampAt(tester, const Duration(seconds: 1));
      final stamp =
          tester.widget<FilledButton>(find.byKey(const Key('sync-stamp')));
      expect(stamp.onPressed, isNull);
    });

    testWidgets('tik op een regel selecteert hem om opnieuw te timen',
        (tester) async {
      final results = await pumpSync(tester, 'Een\nTwee');
      await stampAt(tester, const Duration(seconds: 1));
      await stampAt(tester, const Duration(seconds: 2));

      await tester.tap(find.text('Een'));
      await tester.pumpAndSettle();
      await stampAt(tester, const Duration(milliseconds: 1500));

      await tester.tap(find.byKey(const Key('sync-done')));
      await tester.pumpAndSettle();
      expect(results.single, '[00:01.50] Een\n[00:02.00] Twee');
    });

    testWidgets('ongedaan maken draait de laatste tik terug', (tester) async {
      await pumpSync(tester, 'Een\nTwee');
      final undo = find.byKey(const Key('sync-undo'));
      expect(tester.widget<IconButton>(undo).onPressed, isNull);

      await stampAt(tester, const Duration(seconds: 1));
      await tester.tap(undo);
      await tester.pumpAndSettle();

      expect(timeText(tester, 0).data, '--:--.--');
      expect(tester.widget<IconButton>(undo).onPressed, isNull);

      // Cursor is back on line 0, so the next tap stamps "Een" again.
      await stampAt(tester, const Duration(seconds: 4));
      expect(timeText(tester, 0).data, '00:04.00');
      expect(timeText(tester, 1).data, '--:--.--');
    });

    testWidgets('terug zonder Klaar geeft null terug', (tester) async {
      final results = await pumpSync(tester, 'Een');
      await stampAt(tester, const Duration(seconds: 1));
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(results, [null]);
    });

    testWidgets('niet-gesynchroniseerde regels blijven als tekst behouden',
        (tester) async {
      final results = await pumpSync(tester, 'Een\nTwee');
      await stampAt(tester, const Duration(seconds: 1));
      await tester.tap(find.byKey(const Key('sync-done')));
      await tester.pumpAndSettle();
      expect(results.single, '[00:01.00] Een\nTwee');
    });
  });

  group('LrcSyncScreen — bijstellen', () {
    testWidgets('+ en - verschuiven de geselecteerde regel met 0,1s',
        (tester) async {
      await pumpSync(tester, '[00:05.00] Een\nTwee');
      await tester.tap(find.text('Een'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('sync-nudge-plus-0')));
      await tester.pumpAndSettle();
      expect(timeText(tester, 0).data, '00:05.10');

      await tester.tap(find.byKey(const Key('sync-nudge-minus-0')));
      await tester.tap(find.byKey(const Key('sync-nudge-minus-0')));
      await tester.pumpAndSettle();
      expect(timeText(tester, 0).data, '00:04.90');
    });

    testWidgets('bijstel-knoppen alleen bij geselecteerde getimede regel',
        (tester) async {
      await pumpSync(tester, '[00:05.00] Een\nTwee');
      // Cursor starts on "Twee", which has no time yet.
      expect(find.byKey(const Key('sync-nudge-plus-0')), findsNothing);
      expect(find.byKey(const Key('sync-nudge-plus-1')), findsNothing);
    });

    testWidgets('wissen haalt de tijd weg', (tester) async {
      await pumpSync(tester, '[00:05.00] Een\nTwee');
      await tester.tap(find.text('Een'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('sync-clear-0')));
      await tester.pumpAndSettle();
      expect(timeText(tester, 0).data, '--:--.--');
      expect(find.text(l10n.syncProgress(0, 2)), findsOneWidget);
    });

    testWidgets('tik op een tijd springt daarheen in het nummer',
        (tester) async {
      await pumpSync(tester, '[00:42.00] Een');
      await tester.tap(find.byKey(const Key('sync-time-0')));
      await tester.pumpAndSettle();
      expect(playback.seeks, [const Duration(seconds: 42)]);
    });

    testWidgets('tik op een lege tijd springt nergens heen', (tester) async {
      await pumpSync(tester, 'Een');
      await tester.tap(find.byKey(const Key('sync-time-0')));
      await tester.pumpAndSettle();
      expect(playback.seeks, isEmpty);
    });
  });

  group('LrcSyncScreen — afspelen', () {
    testWidgets('afspeelknop schakelt play/pause', (tester) async {
      await pumpSync(tester, 'Een');
      expect(find.byIcon(Icons.play_circle_filled), findsOneWidget);
      await tester.tap(find.byKey(const Key('sync-play-pause')));
      await tester.pumpAndSettle();
      expect(playback.toggleCalls, 1);
      expect(find.byIcon(Icons.pause_circle_filled), findsOneWidget);
    });

    testWidgets('terug- en vooruitspoelen met 5 seconden', (tester) async {
      await pumpSync(tester, 'Een');
      playback.position = const Duration(seconds: 10);
      await tester.tap(find.byKey(const Key('sync-rewind')));
      await tester.tap(find.byKey(const Key('sync-forward')));
      await tester.pumpAndSettle();
      expect(playback.seeks,
          [const Duration(seconds: 5), const Duration(seconds: 10)]);
    });

    testWidgets('terugspoelen stopt bij nul', (tester) async {
      await pumpSync(tester, 'Een');
      playback.position = const Duration(seconds: 2);
      await tester.tap(find.byKey(const Key('sync-rewind')));
      await tester.pumpAndSettle();
      expect(playback.seeks, [Duration.zero]);
    });

    testWidgets('ander nummer actief: banner en tikken uitgeschakeld',
        (tester) async {
      playback = FakeSyncPlayback(isSongLoaded: false);
      await pumpSync(tester, 'Een');
      expect(find.text(l10n.syncPlaySongHint), findsOneWidget);
      expect(
          tester
              .widget<FilledButton>(find.byKey(const Key('sync-stamp')))
              .onPressed,
          isNull);
      expect(
          tester
              .widget<IconButton>(find.byKey(const Key('sync-play-pause')))
              .onPressed,
          isNull);
    });

    testWidgets('Nummer afspelen laadt het nummer en activeert tikken',
        (tester) async {
      playback = FakeSyncPlayback(isSongLoaded: false);
      await pumpSync(tester, 'Een');
      await tester.tap(find.byKey(const Key('sync-play-song')));
      await tester.pumpAndSettle();

      expect(playback.playSongCalls, 1);
      expect(find.text(l10n.syncPlaySongHint), findsNothing);
      expect(
          tester
              .widget<FilledButton>(find.byKey(const Key('sync-stamp')))
              .onPressed,
          isNotNull);
    });
  });
}
