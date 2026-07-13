import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_player_flutter/models/song.dart';
import 'package:music_player_flutter/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockDio extends Mock implements Dio {}

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

Response<dynamic> songsResponse(List<Song> songs) => Response(
      requestOptions: RequestOptions(path: '/songs.php'),
      statusCode: 200,
      data: songs.map((s) => s.toJson()).toList(),
    );

void main() {
  late MockDio mockDio;
  late ApiService api;

  void stubGetSongs(List<Song> songs) {
    when(() => mockDio.get(
          '/songs.php',
          queryParameters: any(named: 'queryParameters'),
        )).thenAnswer((_) async => songsResponse(songs));
  }

  void stubNetworkError() {
    when(() => mockDio.get(
          '/songs.php',
          queryParameters: any(named: 'queryParameters'),
        )).thenThrow(DioException(
      requestOptions: RequestOptions(path: '/songs.php'),
      type: DioExceptionType.connectionError,
    ));
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockDio = MockDio();
    api = ApiService(dio: mockDio);
  });

  group('Songs cache opslaan', () {
    test('getSongs slaat de volledige lijst en een timestamp op', () async {
      stubGetSongs([makeSong(1), makeSong(2)]);

      await api.getSongs();

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('songs_cache_v1');
      expect(raw, isNotNull);
      expect((jsonDecode(raw!) as List).length, 2);
      expect(prefs.getInt('songs_cache_time_v1'), isNotNull);
    });

    test('getSongs met filter slaat geen cache op', () async {
      stubGetSongs([makeSong(1)]);

      await api.getSongs(search: 'Song');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('songs_cache_v1'), isNull);
    });

    test('getSongs gebruikt de cache als het netwerk faalt', () async {
      stubGetSongs([makeSong(1), makeSong(2)]);
      await api.getSongs();

      stubNetworkError();
      final songs = await api.getSongs();

      expect(songs.length, 2);
      expect(songs.first.id, 1);
    });
  });

  group('Cache uitschakelen', () {
    test('cache staat standaard aan', () async {
      expect(await api.isCacheEnabled(), isTrue);
    });

    test('setCacheEnabled(false) wordt onthouden', () async {
      await api.setCacheEnabled(false);
      expect(await api.isCacheEnabled(), isFalse);
    });

    test('uitschakelen wist de bestaande cache en timestamp', () async {
      stubGetSongs([makeSong(1)]);
      await api.getSongs();

      await api.setCacheEnabled(false);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('songs_cache_v1'), isNull);
      expect(prefs.getInt('songs_cache_time_v1'), isNull);
    });

    test('getSongs slaat niets op wanneer cache uit staat', () async {
      await api.setCacheEnabled(false);
      stubGetSongs([makeSong(1)]);

      await api.getSongs();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('songs_cache_v1'), isNull);
    });

    test('offline zonder cache geeft een lege lijst', () async {
      await api.setCacheEnabled(false);
      stubNetworkError();

      final songs = await api.getSongs();
      expect(songs, isEmpty);
    });

    test('weer inschakelen laat getSongs opnieuw cachen', () async {
      await api.setCacheEnabled(false);
      await api.setCacheEnabled(true);
      stubGetSongs([makeSong(1)]);

      await api.getSongs();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('songs_cache_v1'), isNotNull);
    });
  });

  group('refreshCacheIfStale', () {
    test('haalt songs op wanneer er nog geen cache is', () async {
      stubGetSongs([makeSong(1)]);

      await api.refreshCacheIfStale();

      verify(() => mockDio.get('/songs.php',
          queryParameters: any(named: 'queryParameters'))).called(1);
    });

    test('doet niets bij een verse cache', () async {
      stubGetSongs([makeSong(1)]);
      await api.getSongs();
      clearInteractions(mockDio);

      await api.refreshCacheIfStale();

      verifyNever(() => mockDio.get(any(),
          queryParameters: any(named: 'queryParameters')));
    });

    test('ververst een cache die ouder is dan 24 uur', () async {
      final staleTime = DateTime.now()
          .subtract(const Duration(hours: 25))
          .millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({
        'songs_cache_v1': jsonEncode([makeSong(1).toJson()]),
        'songs_cache_time_v1': staleTime,
      });
      stubGetSongs([makeSong(1), makeSong(2)]);

      await api.refreshCacheIfStale();

      verify(() => mockDio.get('/songs.php',
          queryParameters: any(named: 'queryParameters'))).called(1);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('songs_cache_time_v1'), greaterThan(staleTime));
    });

    test('doet niets wanneer de cache is uitgeschakeld', () async {
      await api.setCacheEnabled(false);

      await api.refreshCacheIfStale();

      verifyNever(() => mockDio.get(any(),
          queryParameters: any(named: 'queryParameters')));
    });

    test('slikt netwerkfouten in zonder exception', () async {
      stubNetworkError();
      await expectLater(api.refreshCacheIfStale(), completes);
    });
  });
}
