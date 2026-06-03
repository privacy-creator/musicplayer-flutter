import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import '../models/song.dart';

class PlayerService extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  final _rng = Random();

  Song? _currentSong;
  List<Song> _playlist = [];
  int _currentIndex = 0;
  bool _shuffleMode = false;

  Song? get currentSong => _currentSong;
  bool get isPlaying => _player.playing;
  bool get shuffleMode => _shuffleMode;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Duration get position => _player.position;
  Duration? get duration => _player.duration;

  PlayerService() {
    _setup();
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        playNext();
      }
      notifyListeners();
    });
    _player.positionStream.listen((_) => notifyListeners());
  }

  Future<void> _setup() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  }

  Future<void> playSong(Song song, List<Song> playlist, int index) async {
    if (_currentSong?.id == song.id) {
      await togglePlayPause();
      return;
    }
    _playlist = playlist;
    _currentIndex = index;
    _currentSong = song;
    notifyListeners();
    try {
      await _player.setUrl(song.audioUrl);
      await _player.play();
    } catch (_) {}
    notifyListeners();
  }

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
    notifyListeners();
  }

  Future<void> playNext() async {
    if (_playlist.isEmpty) return;
    int next;
    if (_shuffleMode && _playlist.length > 1) {
      do {
        next = _rng.nextInt(_playlist.length);
      } while (next == _currentIndex);
    } else {
      next = (_currentIndex + 1) % _playlist.length;
    }
    await playSong(_playlist[next], _playlist, next);
  }

  Future<void> playPrevious() async {
    if (_playlist.isEmpty) return;
    final prev =
        _currentIndex > 0 ? _currentIndex - 1 : _playlist.length - 1;
    await playSong(_playlist[prev], _playlist, prev);
  }

  void toggleShuffle() {
    _shuffleMode = !_shuffleMode;
    notifyListeners();
  }

  Future<void> shufflePlay(List<Song> playlist) async {
    if (playlist.isEmpty) return;
    final shuffled = List<Song>.from(playlist)..shuffle(_rng);
    _shuffleMode = true;
    await playSong(shuffled[0], shuffled, 0);
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
