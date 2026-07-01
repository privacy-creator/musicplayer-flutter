import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:music_player_flutter/models/stream_room.dart';
import 'package:music_player_flutter/services/streaming_service.dart';

// ── Mocks ─────────────────────────────────────────────────────────────────────

class MockDio extends Mock implements Dio {}

class MockWebSocketChannel extends Mock implements WebSocketChannel {}

class MockWebSocketSink extends Mock implements WebSocketSink {}

// ── Helpers ───────────────────────────────────────────────────────────────────

MockDio _mockDio() {
  final dio = MockDio();
  final opts = BaseOptions(baseUrl: 'http://test');
  when(() => dio.options).thenReturn(opts);
  return dio;
}

Response<dynamic> _jsonResp(Map<String, dynamic> data) => Response(
      data: data,
      requestOptions: RequestOptions(path: ''),
      statusCode: 200,
    );

// ── StreamRoom model tests ────────────────────────────────────────────────────

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    registerFallbackValue(RequestOptions(path: ''));
  });

  group('StreamRoom.fromJson', () {
    test('parses full JSON correctly', () {
      final json = {
        'id': 42,
        'host_id': 7,
        'room_code': 'ABC123',
        'current_track_id': 99,
        'position': 30.5,
        'is_playing': true,
        'participants': [
          {'id': 7, 'email': 'host@example.com'},
          {'id': 8, 'email': 'listener@example.com'},
        ],
      };
      final room = StreamRoom.fromJson(json);
      expect(room.id, 42);
      expect(room.hostId, 7);
      expect(room.roomCode, 'ABC123');
      expect(room.currentTrackId, 99);
      expect(room.position, closeTo(30.5, 0.001));
      expect(room.isPlaying, true);
      expect(room.participants.length, 2);
      expect(room.participants.first.name, 'host@example.com');
    });

    test('handles null currentTrackId', () {
      final json = {
        'id': 1,
        'host_id': 1,
        'room_code': 'XYZABC',
        'current_track_id': null,
        'position': 0,
        'is_playing': 0,
        'participants': [],
      };
      final room = StreamRoom.fromJson(json);
      expect(room.currentTrackId, isNull);
      expect(room.isPlaying, false);
    });

    test('copyWith preserves fields', () {
      const room = StreamRoom(
        id: 1,
        hostId: 2,
        roomCode: 'AAAAAA',
        currentTrackId: 5,
        position: 10.0,
        isPlaying: true,
        participants: [],
      );
      final updated = room.copyWith(isPlaying: false, position: 20.0);
      expect(updated.isPlaying, false);
      expect(updated.position, 20.0);
      expect(updated.currentTrackId, 5);
    });

    test('copyWith can set currentTrackId to null explicitly', () {
      const room = StreamRoom(
        id: 1,
        hostId: 1,
        roomCode: 'AA0000',
        currentTrackId: 5,
        position: 0,
        isPlaying: false,
        participants: [],
      );
      final updated = room.copyWith(currentTrackId: null);
      expect(updated.currentTrackId, isNull);
    });
  });

  // ── StreamingService tests ─────────────────────────────────────────────────

  group('StreamingService.createRoom', () {
    test('calls POST /streams.php with action=create', () async {
      final dio = _mockDio();
      when(() => dio.post(
            '/streams.php',
            data: any(named: 'data'),
          )).thenAnswer((_) async => _jsonResp(
            {'success': true, 'stream_id': 11, 'room_code': 'ABC123'},
          ));

      final ws = MockWebSocketChannel();
      final sink = MockWebSocketSink();
      final streamCtrl = StreamController<dynamic>.broadcast();
      when(() => ws.stream).thenAnswer((_) => streamCtrl.stream);
      when(() => ws.sink).thenReturn(sink);
      when(() => sink.add(any())).thenReturn(null);
      when(() => sink.close()).thenAnswer((_) async {});

      final service = StreamingService(dio, wsFactory: (_) => ws);
      await service.createRoom(trackId: 5, position: 10.0, isPlaying: true);

      expect(service.inRoom, true);
      expect(service.isHost, true);
      expect(service.room?.roomCode, 'ABC123');
      expect(service.room?.id, 11);

      final captured = verify(() => dio.post('/streams.php',
              data: captureAny(named: 'data')))
          .captured
          .first as Map<String, dynamic>;
      expect(captured['action'], 'create');
      expect(captured['host_token'], isNotNull);
      expect(captured['track_id'], 5);
      expect(captured['is_playing'], true);

      service.dispose();
      await streamCtrl.close();
    });
  });

  group('StreamingService.joinRoom', () {
    test('calls POST /streams.php with action=join', () async {
      final dio = _mockDio();
      final stateJson = {
        'id': 7,
        'host_id': 3,
        'room_code': 'XYZABC',
        'current_track_id': null,
        'position': 0,
        'is_playing': false,
        'participants': <dynamic>[],
      };
      when(() => dio.post('/streams.php', data: any(named: 'data')))
          .thenAnswer((_) async => _jsonResp({
                'success': true,
                'stream_id': 7,
                'room_code': 'XYZABC',
                'is_host': false,
                'state': stateJson,
              }));

      final ws = MockWebSocketChannel();
      final sink = MockWebSocketSink();
      final streamCtrl = StreamController<dynamic>.broadcast();
      when(() => ws.stream).thenAnswer((_) => streamCtrl.stream);
      when(() => ws.sink).thenReturn(sink);
      when(() => sink.add(any())).thenReturn(null);
      when(() => sink.close()).thenAnswer((_) async {});

      final service = StreamingService(dio, wsFactory: (_) => ws);
      await service.joinRoom('xyzabc');

      expect(service.inRoom, true);
      expect(service.isHost, false);
      expect(service.room?.roomCode, 'XYZABC');

      final captured = verify(() => dio.post('/streams.php',
              data: captureAny(named: 'data')))
          .captured
          .first as Map<String, dynamic>;
      expect(captured['action'], 'join');
      expect(captured['room_code'], 'XYZABC');
      expect(captured['participant_token'], isNotNull);

      service.dispose();
      await streamCtrl.close();
    });
  });

  group('StreamingService.leaveRoom', () {
    test('clears room state and calls POST leave', () async {
      final dio = _mockDio();
      when(() => dio.post('/streams.php', data: any(named: 'data')))
          .thenAnswer((_) async => _jsonResp({'success': true}));

      final ws = MockWebSocketChannel();
      final sink = MockWebSocketSink();
      final streamCtrl = StreamController<dynamic>.broadcast();
      when(() => ws.stream).thenAnswer((_) => streamCtrl.stream);
      when(() => ws.sink).thenReturn(sink);
      when(() => sink.add(any())).thenReturn(null);
      when(() => sink.close()).thenAnswer((_) async {});

      when(() => dio.post('/streams.php',
              data: any(
                  that: predicate<Map>((m) => m['action'] == 'create'),
                  named: 'data')))
          .thenAnswer((_) async => _jsonResp(
              {'success': true, 'stream_id': 1, 'room_code': 'AAAAAA'}));

      final service = StreamingService(dio, wsFactory: (_) => ws);
      await service.createRoom();
      expect(service.inRoom, true);

      await service.leaveRoom();
      expect(service.inRoom, false);
      expect(service.isHost, false);

      service.dispose();
      await streamCtrl.close();
    });
  });

  group('StreamingService WebSocket sync', () {
    test('onSyncReceived is called when sync message arrives', () async {
      final dio = _mockDio();
      when(() => dio.post('/streams.php', data: any(named: 'data')))
          .thenAnswer((_) async => _jsonResp(
              {'success': true, 'stream_id': 3, 'room_code': 'BBBBBB'}));

      final ws = MockWebSocketChannel();
      final sink = MockWebSocketSink();
      final streamCtrl = StreamController<dynamic>.broadcast();
      when(() => ws.stream).thenAnswer((_) => streamCtrl.stream);
      when(() => ws.sink).thenReturn(sink);
      when(() => sink.add(any())).thenReturn(null);
      when(() => sink.close()).thenAnswer((_) async {});

      final service = StreamingService(dio, wsFactory: (_) => ws);

      Map<String, dynamic>? received;
      service.onSyncReceived = (event) => received = event;

      await service.createRoom(trackId: 1);

      // Simulate incoming sync from WebSocket.
      final syncMsg = jsonEncode({
        'type': 'sync',
        'track_id': 2,
        'position': 42.5,
        'is_playing': false,
      });
      streamCtrl.add(syncMsg);
      await Future.delayed(Duration.zero);

      expect(received, isNotNull);
      expect(received!['track_id'], 2);
      expect(received!['is_playing'], false);
      expect(service.room?.currentTrackId, 2);
      expect(service.room?.isPlaying, false);

      service.dispose();
      await streamCtrl.close();
    });
  });

  group('StreamingService.updateState', () {
    test('does nothing when not host', () async {
      final dio = _mockDio();
      final service = StreamingService(dio);
      // No room set — nothing should happen.
      await service.updateState(trackId: 1, position: 0, isPlaying: true);
      verifyNever(() => dio.post(any(), data: any(named: 'data')));
      service.dispose();
    });
  });
}
