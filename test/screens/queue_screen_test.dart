import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_player_flutter/l10n/app_localizations.dart';
import 'package:music_player_flutter/models/song.dart';
import 'package:music_player_flutter/services/audio_handler.dart';
import 'package:music_player_flutter/services/player_service.dart';
import 'package:music_player_flutter/screens/queue_screen.dart';

class MockAudioPlayer extends Mock implements AudioPlayer {}

Song makeSong(int id) => Song(
      id: id,
      title: 'Song $id',
      artist: 'Artist $id',
      genre: 'Pop',
      language: 'Dutch',
      year: 2024,
      duration: 180,
      audioUrl: 'https://api.hiddebalestra.nl/muziek/uploads/$id.mp3',
    );

void main() {
  late MockAudioPlayer mockPlayer;
  late PlayerService playerService;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockPlayer = MockAudioPlayer();

    when(() => mockPlayer.playerStateStream)
        .thenAnswer((_) => const Stream.empty());
    when(() => mockPlayer.positionStream)
        .thenAnswer((_) => const Stream.empty());
    when(() => mockPlayer.durationStream)
        .thenAnswer((_) => const Stream.empty());
    when(() => mockPlayer.playing).thenReturn(false);
    when(() => mockPlayer.position).thenReturn(Duration.zero);
    when(() => mockPlayer.duration).thenReturn(null);
    when(() => mockPlayer.bufferedPosition).thenReturn(Duration.zero);
    when(() => mockPlayer.playerState)
        .thenReturn(PlayerState(false, ProcessingState.idle));
    when(() => mockPlayer.setUrl(any())).thenAnswer((_) async => null);
    when(() => mockPlayer.play()).thenAnswer((_) async {});
    when(() => mockPlayer.dispose()).thenAnswer((_) async {});

    final handler = MusicAudioHandler(player: mockPlayer);
    playerService = PlayerService(handler: handler);
  });

  tearDown(() => playerService.dispose());

  Widget buildScreen() => ChangeNotifierProvider<PlayerService>.value(
        value: playerService,
        child: MaterialApp(
          locale: const Locale('nl'),
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          home: const QueueScreen(),
        ),
      );

  group('QueueScreen', () {
    testWidgets('toont lege wachtrij melding', (tester) async {
      await tester.pumpWidget(buildScreen());
      expect(find.text('Geen nummers in de wachtrij'), findsOneWidget);
    });

    testWidgets('toont huidig nummer na afspelen', (tester) async {
      await playerService.playSong(makeSong(1), [makeSong(1)], 0);

      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.text('Song 1'), findsOneWidget);
    });

    testWidgets('toont sectie Nu aan het afspelen', (tester) async {
      await playerService.playSong(makeSong(1), [makeSong(1)], 0);

      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.text('NU AAN HET AFSPELEN'), findsOneWidget);
    });

    testWidgets('toont wachtrijnummers', (tester) async {
      playerService.addToQueue(makeSong(2));
      playerService.addToQueue(makeSong(3));

      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.text('Song 2'), findsOneWidget);
      expect(find.text('Song 3'), findsOneWidget);
    });

    testWidgets('toont wachtrij sectieheader met aantal', (tester) async {
      playerService.addToQueue(makeSong(2));
      playerService.addToQueue(makeSong(3));

      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.text('WACHTRIJ (2)'), findsOneWidget);
    });

    testWidgets('toont verwijder-knop voor wachtrijnummers', (tester) async {
      playerService.addToQueue(makeSong(2));

      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('toont wis-knop als wachtrij niet leeg is', (tester) async {
      playerService.addToQueue(makeSong(2));

      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.text('Wis wachtrij'), findsOneWidget);
    });

    testWidgets('geen wis-knop bij lege wachtrij', (tester) async {
      await tester.pumpWidget(buildScreen());
      expect(find.text('Wis wachtrij'), findsNothing);
    });

    testWidgets('verwijder-knop verwijdert nummer uit wachtrij', (tester) async {
      playerService.addToQueue(makeSong(2));

      await tester.pumpWidget(buildScreen());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(playerService.queue, isEmpty);
      expect(find.text('Geen nummers in de wachtrij'), findsOneWidget);
    });

    testWidgets('wis-knop leegt de wachtrij', (tester) async {
      playerService.addToQueue(makeSong(2));
      playerService.addToQueue(makeSong(3));

      await tester.pumpWidget(buildScreen());
      await tester.pump();

      await tester.tap(find.text('Wis wachtrij'));
      await tester.pump();

      expect(playerService.queue, isEmpty);
    });

    testWidgets('toont Hierna sectie bij playlist', (tester) async {
      final pl = List.generate(3, (i) => makeSong(i + 1));
      await playerService.playSong(pl[0], pl, 0);

      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.text('HIERNA'), findsOneWidget);
      expect(find.text('Song 2'), findsOneWidget);
      expect(find.text('Song 3'), findsOneWidget);
    });
  });
}
