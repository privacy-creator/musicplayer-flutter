import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';
import 'audio_handler.dart';
import 'download_service.dart';

const _shuffleKey = 'shuffle_mode';

class PlayerService extends ChangeNotifier {
  final MusicAudioHandler _handler;
  final DownloadService? _downloadService;
  final _rng = Random();

  AudioPlayer get _player => _handler.player;

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

  PlayerService({MusicAudioHandler? handler, DownloadService? downloadService})
      : _handler = handler ?? MusicAudioHandler(),
        _downloadService = downloadService {
    _handler.onSkipToNext = () => playNext();
    _handler.onSkipToPrevious = () => playPrevious();
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        playNext();
      }
      notifyListeners();
    });
    _player.positionStream.listen((_) => notifyListeners());
    _loadShuffleMode();
  }

  Future<void> _loadShuffleMode() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool(_shuffleKey);
    if (saved != null && saved != _shuffleMode) {
      _shuffleMode = saved;
      notifyListeners();
    }
  }

  Future<void> _saveShuffleMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_shuffleKey, _shuffleMode);
  }

  Future<void> playSong(Song song, List<Song> playlist, int index) async {
    if (_currentSong?.id == song.id) {
      await togglePlayPause();
      return;
    }
    _playlist = playlist;
    _currentIndex = index;
    _currentSong = song;
    _handler.setMediaItem(song);
    notifyListeners();
    try {
      final localPath = _downloadService?.getLocalPath(song.id);
      if (localPath != null && File(localPath).existsSync()) {
        await _player.setFilePath(localPath);
      } else {
        await _player.setUrl(song.audioUrl);
      }
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
    _saveShuffleMode();
    notifyListeners();
  }

  Future<void> shufflePlay(List<Song> playlist) async {
    if (playlist.isEmpty) return;
    final shuffled = List<Song>.from(playlist)..shuffle(_rng);
    _shuffleMode = true;
    _saveShuffleMode();
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
