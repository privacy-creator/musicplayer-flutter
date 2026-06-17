import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../constants.dart';
import '../models/stream_room.dart';

typedef WsChannelFactory = WebSocketChannel Function(Uri);

class StreamingService extends ChangeNotifier {
  final Dio _dio;
  final WsChannelFactory _wsFactory;

  StreamRoom? _room;
  bool _isHost = false;
  bool _wsConnected = false;
  String? _error;
  String? _guestToken;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _wsSub;
  Timer? _pingTimer;
  Timer? _pollTimer;

  /// Called whenever a sync event is received from the host (via WS or poll).
  /// Passes {type, track_id, position, is_playing}.
  void Function(Map<String, dynamic>)? onSyncReceived;

  StreamingService(Dio dio, {WsChannelFactory? wsFactory})
      : _dio = dio,
        _wsFactory = wsFactory ?? WebSocketChannel.connect;

  // ── State ────────────────────────────────────────────────────

  StreamRoom? get room => _room;
  bool get isHost => _isHost;
  bool get inRoom => _room != null;
  bool get wsConnected => _wsConnected;
  String? get error => _error;

  // ── Room management ──────────────────────────────────────────

  Future<void> createRoom({
    int? trackId,
    double position = 0,
    bool isPlaying = false,
  }) async {
    _error = null;
    try {
      final hostToken = await _getGuestToken();
      final resp = await _dio.post(
        '/streams.php',
        data: {
          'action': 'create',
          'host_token': hostToken,
          'track_id': trackId,
          'position': position,
          'is_playing': isPlaying,
        },
      );
      final data = resp.data as Map<String, dynamic>;
      if (data['success'] == true) {
        final streamId = data['stream_id'] as int;
        final roomCode = data['room_code'] as String;
        _room = StreamRoom(
          id: streamId,
          hostId: 0,
          roomCode: roomCode,
          currentTrackId: trackId,
          position: position,
          isPlaying: isPlaying,
          participants: [],
        );
        _isHost = true;
        _connectWs(streamId);
        _startPolling(streamId);
        notifyListeners();
      }
    } on DioException catch (e) {
      _error = e.message ?? 'Failed to create room';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> joinRoom(String code) async {
    _error = null;
    try {
      final participantToken = await _getGuestToken();
      final resp = await _dio.post(
        '/streams.php',
        data: {
          'action': 'join',
          'room_code': code.trim().toUpperCase(),
          'participant_token': participantToken,
        },
      );
      final data = resp.data as Map<String, dynamic>;
      if (data['success'] == true) {
        final state = data['state'] as Map<String, dynamic>?;
        _room = state != null ? StreamRoom.fromJson(state) : null;
        _isHost = data['is_host'] == true;
        _error = null;
        final streamId = data['stream_id'] as int;
        _connectWs(streamId);
        _startPolling(streamId);
        notifyListeners();
      } else {
        _error = data['message'] as String? ?? 'Room not found';
        notifyListeners();
      }
    } on DioException catch (e) {
      _error = e.message ?? 'Failed to join room';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateState({
    int? trackId,
    double? position,
    bool? isPlaying,
  }) async {
    if (_room == null || !_isHost) return;
    final body = <String, dynamic>{
      'action': 'update',
      'stream_id': _room!.id,
      'host_token': _guestToken!,
    };
    if (trackId != null) body['track_id'] = trackId;
    if (position != null) body['position'] = position;
    if (isPlaying != null) body['is_playing'] = isPlaying;

    try {
      await _dio.post('/streams.php', data: body);
    } catch (_) {}

    _room = _room!.copyWith(
      currentTrackId: trackId ?? _room!.currentTrackId,
      position: position ?? _room!.position,
      isPlaying: isPlaying ?? _room!.isPlaying,
    );

    // Broadcast via WebSocket so listeners receive the event instantly.
    final syncMsg = jsonEncode({
      'type': 'sync',
      'track_id': _room!.currentTrackId,
      'position': _room!.position,
      'is_playing': _room!.isPlaying,
    });
    _channel?.sink.add(syncMsg);

    notifyListeners();
  }

  Future<void> transferHost(int newParticipantId) async {
    if (_room == null || !_isHost) return;
    try {
      await _dio.post('/streams.php', data: {
        'action': 'transfer',
        'stream_id': _room!.id,
        'host_token': _guestToken!,
        'new_participant_id': newParticipantId,
      });
      _isHost = false;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> leaveRoom() async {
    if (_room == null) return;
    final streamId = _room!.id;
    final participantToken = _guestToken ?? await _getGuestToken();
    _clearRoom();
    try {
      await _dio.post('/streams.php', data: {
        'action': 'leave',
        'stream_id': streamId,
        'participant_token': participantToken,
      });
    } catch (_) {}
  }

  Future<void> endRoom() async {
    if (_room == null || !_isHost) return;
    final streamId = _room!.id;
    final hostToken = _guestToken!;
    _clearRoom();
    try {
      await _dio.post('/streams.php', data: {
        'action': 'end',
        'stream_id': streamId,
        'host_token': hostToken,
      });
    } catch (_) {}
  }

  // ── Guest token ──────────────────────────────────────────────

  Future<String> _getGuestToken() async {
    if (_guestToken != null) return _guestToken!;
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('stream_guest_token');
    if (token == null) {
      final rng = Random.secure();
      token = List.generate(32, (_) => rng.nextInt(16).toRadixString(16)).join();
      await prefs.setString('stream_guest_token', token);
    }
    _guestToken = token;
    return token;
  }

  // ── WebSocket ────────────────────────────────────────────────

  void _connectWs(int streamId) {
    _disconnectWs();
    try {
      final uri = Uri.parse(AppConstants.wsUrl);
      _channel = _wsFactory(uri);
      _wsSub = _channel!.stream.listen(
        (msg) {
          if (msg is String) _onWsMessage(msg);
        },
        onError: (_) {
          _wsConnected = false;
          notifyListeners();
        },
        onDone: () {
          _wsConnected = false;
          notifyListeners();
        },
      );
      _channel!.sink
          .add(jsonEncode({'type': 'subscribe', 'stream_id': streamId}));
      _pingTimer =
          Timer.periodic(const Duration(seconds: 25), (_) {
        _channel?.sink.add(jsonEncode({'type': 'ping'}));
      });
    } catch (_) {
      _wsConnected = false;
    }
  }

  void _onWsMessage(String raw) {
    final Map<String, dynamic> msg;
    try {
      msg = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return;
    }

    final type = msg['type'] as String?;
    if (type == 'subscribed') {
      _wsConnected = true;
      notifyListeners();
    } else if (type == 'sync' && _room != null) {
      // Apply to local room state snapshot.
      _room = _room!.copyWith(
        currentTrackId: msg['track_id'] as int?,
        position: (msg['position'] as num?)?.toDouble() ?? _room!.position,
        isPlaying: msg['is_playing'] as bool? ?? _room!.isPlaying,
      );
      onSyncReceived?.call(msg);
      notifyListeners();
    }
  }

  void _disconnectWs() {
    _pingTimer?.cancel();
    _pingTimer = null;
    _wsSub?.cancel();
    _wsSub = null;
    _channel?.sink.close();
    _channel = null;
    _wsConnected = false;
  }

  // ── Polling (participant refresh + WS fallback) ───────────────

  void _startPolling(int streamId) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _poll(streamId),
    );
  }

  Future<void> _poll(int streamId) async {
    try {
      final resp = await _dio.get(
        '/streams.php',
        queryParameters: {'action': 'state', 'stream_id': streamId},
      );
      final data = resp.data as Map<String, dynamic>;

      if (data['ended'] == true) {
        _clearRoom();
        return;
      }

      final state = data['state'] as Map<String, dynamic>?;
      if (state != null && _room != null) {
        final updated = StreamRoom.fromJson(state);

        // If WS is not connected use poll state for playback sync.
        if (!_wsConnected) {
          if (updated.currentTrackId != _room!.currentTrackId ||
              updated.isPlaying != _room!.isPlaying) {
            onSyncReceived?.call({
              'type': 'sync',
              'track_id': updated.currentTrackId,
              'position': updated.position,
              'is_playing': updated.isPlaying,
            });
          }
        }

        // Always refresh participants list from poll.
        _room = _room!.copyWith(participants: updated.participants);
        notifyListeners();
      }
    } catch (_) {}
  }

  void _clearRoom() {
    _disconnectWs();
    _pollTimer?.cancel();
    _pollTimer = null;
    _room = null;
    _isHost = false;
    _wsConnected = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _clearRoom();
    super.dispose();
  }
}
