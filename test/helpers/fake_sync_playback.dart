import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:music_player_flutter/screens/lrc_sync_screen.dart';

class FakeSyncPlayback extends ChangeNotifier implements SyncPlayback {
  final _positions = StreamController<Duration>.broadcast();

  @override
  Duration position = Duration.zero;
  @override
  bool isPlaying = false;
  @override
  bool isSongLoaded;

  final seeks = <Duration>[];
  int playSongCalls = 0;
  int toggleCalls = 0;

  FakeSyncPlayback({this.isSongLoaded = true});

  @override
  Stream<Duration> get positionStream => _positions.stream;

  @override
  Future<void> playSong() async {
    playSongCalls++;
    isSongLoaded = true;
    isPlaying = true;
    notifyListeners();
  }

  @override
  Future<void> togglePlayPause() async {
    toggleCalls++;
    isPlaying = !isPlaying;
    notifyListeners();
  }

  @override
  Future<void> seek(Duration p) async {
    seeks.add(p);
    position = p;
  }

  @override
  void dispose() {
    _positions.close();
    super.dispose();
  }
}
