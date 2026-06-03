import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_player_flutter/models/song.dart';
import 'package:music_player_flutter/services/api_service.dart';
import 'package:music_player_flutter/services/audio_handler.dart';
import 'package:music_player_flutter/services/download_service.dart';
import 'package:music_player_flutter/services/player_service.dart';
import 'package:music_player_flutter/screens/songs_screen.dart';

class MockApiService extends Mock implements ApiService {}
class MockAudioPlayer extends Mock implements AudioPlayer {}

Song makeSong(int id) => Song(
      id: id,
      title: 'Song $id',
      artist: 'Artist',
      genre: 'Pop',
      language: 'Dutch',
      year: 2024,
      duration: 180,
      audioUrl: 'https://api.hiddebalestra.nl/muziek/uploads/$id.mp3',
    );

void main() {
  late MockApiService mockApi;
  late MockAudioPlayer mockPlayer;
  late PlayerService playerService;
  late DownloadService downloadService;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockApi = MockApiService();
    mockPlayer = MockAudioPlayer();
    downloadService = DownloadService();

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
    when(() => mockPlayer.dispose()).thenAnswer((_) async {});

    final handler = MusicAudioHandler(player: mockPlayer);
    playerService = PlayerService(handler: handler);
  });

  tearDown(() => playerService.dispose());

  // Passes a mock connectivity checker so platform channels aren't needed
  Widget buildScreen({bool online = true}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<DownloadService>.value(value: downloadService),
        Provider<ApiService>.value(value: mockApi),
        ChangeNotifierProvider<PlayerService>.value(value: playerService),
      ],
      child: MaterialApp(
        home: SongsScreen(connectivityChecker: () async => online),
      ),
    );
  }

  group('SongsScreen refresh knop', () {
    testWidgets('ApiService.getSongs wordt aangeroepen bij init', (tester) async {
      when(() => mockApi.getSongs(
            search: any(named: 'search'),
            language: any(named: 'language'),
            genre: any(named: 'genre'),
            year: any(named: 'year'),
          )).thenAnswer((_) async => [makeSong(1), makeSong(2)]);

      await tester.pumpWidget(buildScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockApi.getSongs(
            search: any(named: 'search'),
            language: any(named: 'language'),
            genre: any(named: 'genre'),
            year: any(named: 'year'),
          )).called(greaterThanOrEqualTo(1));
    });

    testWidgets('refresh knop is zichtbaar in de AppBar', (tester) async {
      when(() => mockApi.getSongs(
            search: any(named: 'search'),
            language: any(named: 'language'),
            genre: any(named: 'genre'),
            year: any(named: 'year'),
          )).thenAnswer((_) async => []);

      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('tik op refresh roept getSongs opnieuw aan als online', (tester) async {
      when(() => mockApi.getSongs(
            search: any(named: 'search'),
            language: any(named: 'language'),
            genre: any(named: 'genre'),
            year: any(named: 'year'),
          )).thenAnswer((_) async => [makeSong(1)]);

      await tester.pumpWidget(buildScreen(online: true));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      clearInteractions(mockApi);

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockApi.getSongs(
            search: any(named: 'search'),
            language: any(named: 'language'),
            genre: any(named: 'genre'),
            year: any(named: 'year'),
          )).called(1);
    });

    testWidgets('offline banner verschijnt als geen internet', (tester) async {
      when(() => mockApi.getSongs(
            search: any(named: 'search'),
            language: any(named: 'language'),
            genre: any(named: 'genre'),
            year: any(named: 'year'),
          )).thenAnswer((_) async => []);

      await tester.pumpWidget(buildScreen(online: false));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.wifi_off), findsOneWidget);
    });

    testWidgets('liedjes worden getoond na laden', (tester) async {
      when(() => mockApi.getSongs(
            search: any(named: 'search'),
            language: any(named: 'language'),
            genre: any(named: 'genre'),
            year: any(named: 'year'),
          )).thenAnswer((_) async => [makeSong(1), makeSong(2)]);

      await tester.pumpWidget(buildScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Song 1'), findsOneWidget);
      expect(find.text('Song 2'), findsOneWidget);
    });
  });
}
