import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:music_player_flutter/l10n/app_localizations.dart';
import 'package:music_player_flutter/models/stream_room.dart';
import 'package:music_player_flutter/screens/listening_room_screen.dart';
import 'package:music_player_flutter/services/streaming_service.dart';
import 'package:music_player_flutter/services/player_service.dart';
import 'package:music_player_flutter/services/download_service.dart';

// ── Mocks ─────────────────────────────────────────────────────────────────────

class MockDio extends Mock implements Dio {}

class MockWebSocketChannel extends Mock implements WebSocketChannel {}

class MockWebSocketSink extends Mock implements WebSocketSink {}

// ── Helpers ───────────────────────────────────────────────────────────────────

Widget _buildScreen(StreamingService streaming, PlayerService player) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<StreamingService>.value(value: streaming),
      ChangeNotifierProvider<PlayerService>.value(value: player),
    ],
    child: const MaterialApp(
      locale: Locale('en'),
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      home: ListeningRoomScreen(),
    ),
  );
}

StreamingService _fakeStreaming() {
  final dio = MockDio();
  when(() => dio.options).thenReturn(BaseOptions(baseUrl: 'http://test'));
  final ws = MockWebSocketChannel();
  final sink = MockWebSocketSink();
  when(() => ws.stream).thenAnswer((_) => const Stream.empty());
  when(() => ws.sink).thenReturn(sink);
  when(() => sink.add(any())).thenReturn(null);
  when(() => sink.close()).thenAnswer((_) async {});
  return StreamingService(dio, wsFactory: (_) => ws);
}

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    registerFallbackValue(RequestOptions(path: ''));
  });

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('ListeningRoomScreen lobby', () {
    testWidgets('shows Start Listening Party and Join a Room options',
        (tester) async {
      final dl = DownloadService();
      final player = PlayerService(downloadService: dl);
      final streaming = _fakeStreaming();

      await tester.pumpWidget(_buildScreen(streaming, player));
      await tester.pump();
      await tester.pump();

      expect(find.text('Start Listening Party'), findsOneWidget);
      expect(find.text('Join a Room'), findsOneWidget);
    });

    testWidgets('shows Live Listening title in lobby', (tester) async {
      final dl = DownloadService();
      final player = PlayerService(downloadService: dl);
      final streaming = _fakeStreaming();

      await tester.pumpWidget(_buildScreen(streaming, player));
      await tester.pump();
      await tester.pump();

      expect(find.text('Live Listening'), findsOneWidget);
    });
  });

  group('StreamRoom model', () {
    test('fromJson with participants', () {
      final room = StreamRoom.fromJson({
        'id': 1,
        'host_id': 2,
        'room_code': 'ABCDEF',
        'current_track_id': 10,
        'position': 5.0,
        'is_playing': true,
        'participants': [
          {'id': 2, 'email': 'host@test.com'},
          {'id': 3, 'email': 'guest@test.com'},
        ],
      });

      expect(room.roomCode, 'ABCDEF');
      expect(room.participants.length, 2);
      expect(room.participants[0].name, 'host@test.com');
    });

    test('copyWith keeps unspecified fields', () {
      const room = StreamRoom(
        id: 5,
        hostId: 1,
        roomCode: 'ZZZZZZ',
        currentTrackId: 3,
        position: 15.0,
        isPlaying: false,
        participants: [],
      );

      final r2 = room.copyWith(isPlaying: true);
      expect(r2.isPlaying, true);
      expect(r2.roomCode, 'ZZZZZZ');
      expect(r2.currentTrackId, 3);
    });

    test('copyWith explicit null for currentTrackId', () {
      const room = StreamRoom(
        id: 1,
        hostId: 1,
        roomCode: 'AAAAAA',
        currentTrackId: 9,
        position: 0,
        isPlaying: false,
        participants: [],
      );

      final r2 = room.copyWith(currentTrackId: null);
      expect(r2.currentTrackId, isNull);
    });
  });

  group('StreamParticipant', () {
    test('fromJson parses id and name', () {
      final p =
          StreamParticipant.fromJson({'id': 7, 'email': 'Luisteraar A1B2'});
      expect(p.id, 7);
      expect(p.name, 'Luisteraar A1B2');
    });
  });
}
