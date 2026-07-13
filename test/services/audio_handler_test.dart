import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_player_flutter/models/song.dart';
import 'package:music_player_flutter/services/audio_handler.dart';

class MockAudioPlayer extends Mock implements AudioPlayer {}

Song makeSong(int id, {String? imageUrl, int duration = 180}) => Song(
      id: id,
      title: 'Song $id',
      artist: 'Artist',
      genre: 'Pop',
      language: 'Dutch',
      year: 2024,
      duration: duration,
      audioUrl: 'https://api.hiddebalestra.nl/muziek/uploads/$id.mp3',
      imageUrl: imageUrl,
    );

void main() {
  late MockAudioPlayer mockPlayer;
  late StreamController<Duration?> durationCtrl;
  late MusicAudioHandler handler;

  setUp(() {
    mockPlayer = MockAudioPlayer();
    durationCtrl = StreamController<Duration?>.broadcast();

    when(() => mockPlayer.playerStateStream)
        .thenAnswer((_) => const Stream.empty());
    when(() => mockPlayer.positionStream)
        .thenAnswer((_) => const Stream.empty());
    when(() => mockPlayer.durationStream)
        .thenAnswer((_) => durationCtrl.stream);
    when(() => mockPlayer.playing).thenReturn(false);
    when(() => mockPlayer.position).thenReturn(Duration.zero);
    when(() => mockPlayer.duration).thenReturn(null);
    when(() => mockPlayer.bufferedPosition).thenReturn(Duration.zero);
    when(() => mockPlayer.playerState)
        .thenReturn(PlayerState(false, ProcessingState.idle));

    handler = MusicAudioHandler(player: mockPlayer);
  });

  tearDown(() async {
    await durationCtrl.close();
  });

  group('setMediaItem artwork', () {
    test('gebruikt de imageUrl van het nummer wanneer aanwezig', () {
      handler.fallbackArtUri = Uri.file('/tmp/fallback_art.png');
      handler.setMediaItem(
          makeSong(1, imageUrl: 'https://example.com/art.jpg'));

      expect(handler.mediaItem.value!.artUri,
          Uri.parse('https://example.com/art.jpg'));
    });

    test('valt terug op het app-logo zonder imageUrl', () {
      final fallback = Uri.file('/tmp/fallback_art.png');
      handler.fallbackArtUri = fallback;
      handler.setMediaItem(makeSong(1));

      expect(handler.mediaItem.value!.artUri, fallback);
    });

    test('artUri is null zonder imageUrl én zonder fallback', () {
      handler.setMediaItem(makeSong(1));
      expect(handler.mediaItem.value!.artUri, isNull);
    });
  });

  group('durationStream → mediaItem', () {
    test('werkt de duur bij zodra de speler die kent', () async {
      handler.setMediaItem(makeSong(1, duration: 0));
      expect(handler.mediaItem.value!.duration, Duration.zero);

      durationCtrl.add(const Duration(seconds: 213));
      await Future<void>.delayed(Duration.zero);

      expect(handler.mediaItem.value!.duration,
          const Duration(seconds: 213));
    });

    test('laat een correcte duur ongemoeid', () async {
      handler.setMediaItem(makeSong(1, duration: 180));

      durationCtrl.add(const Duration(seconds: 180));
      await Future<void>.delayed(Duration.zero);

      expect(handler.mediaItem.value!.duration,
          const Duration(seconds: 180));
    });

    test('crasht niet zonder actief media item', () async {
      durationCtrl.add(const Duration(seconds: 30));
      await Future<void>.delayed(Duration.zero);
      expect(handler.mediaItem.valueOrNull, isNull);
    });

    test('negeert null-duur van de speler', () async {
      handler.setMediaItem(makeSong(1, duration: 180));

      durationCtrl.add(null);
      await Future<void>.delayed(Duration.zero);

      expect(handler.mediaItem.value!.duration,
          const Duration(seconds: 180));
    });
  });
}
