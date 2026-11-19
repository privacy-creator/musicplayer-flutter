import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_player_flutter/models/local_track.dart';
import 'package:music_player_flutter/models/song.dart';
import 'package:music_player_flutter/services/audio_handler.dart';
import 'package:music_player_flutter/services/history_service.dart';
import 'package:music_player_flutter/services/player_service.dart';
import 'package:music_player_flutter/services/recently_played_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAudioPlayer extends Mock implements AudioPlayer {}

void main() {
  late MockAudioPlayer mockPlayer;
  late PlayerService service;
  late HistoryService history;
  late RecentlyPlayedService recent;

  setUp(() async {
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
    when(() => mockPlayer.setFilePath(any())).thenAnswer((_) async => null);
    when(() => mockPlayer.setVolume(any())).thenAnswer((_) async {});
    when(() => mockPlayer.play()).thenAnswer((_) async {});
    when(() => mockPlayer.dispose()).thenAnswer((_) async {});

    final prefs = await SharedPreferences.getInstance();
    history = HistoryService(prefs);
    recent = RecentlyPlayedService();
    service = PlayerService(
      handler: MusicAudioHandler(player: mockPlayer),
      historyService: history,
      recentlyPlayedService: recent,
    );
  });

  tearDown(() => service.dispose());

  final local = LocalTrack.fromPath('/music/Band - Lied.mp3').toSong();
  const cloud = Song(
    id: 7,
    title: 'Cloud',
    artist: 'A',
    genre: 'Pop',
    language: 'nl',
    year: 2024,
    duration: 100,
    audioUrl: 'https://example.com/7.mp3',
  );

  test('lokaal nummer wordt via het bestandspad afgespeeld', () async {
    await service.playSong(local, [local], 0);
    verify(() => mockPlayer.setFilePath('/music/Band - Lied.mp3')).called(1);
    verifyNever(() => mockPlayer.setUrl(any()));
    expect(service.currentSong?.isLocal, true);
  });

  test('lokaal nummer komt niet in "recent gespeeld" of de geschiedenis',
      () async {
    await service.playSong(local, [local], 0);
    expect(recent.recentSongs, isEmpty);
    expect(history.entries, isEmpty);
  });

  test('cloud-nummer wordt nog steeds via de URL gestreamd en geregistreerd',
      () async {
    await service.playSong(cloud, [cloud], 0);
    verify(() => mockPlayer.setUrl('https://example.com/7.mp3')).called(1);
    expect(recent.recentSongs.single.id, 7);
  });
}
