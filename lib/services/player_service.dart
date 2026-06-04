import 'dart:async';
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
  final _errorController = StreamController<String>.broadcast();

  Song? _currentSong;
  List<Song> _playlist = [];
  int _currentIndex = 0;
  bool _shuffleMode = false;

  // Wachtrij: songs die voor de volgende playlist-song spelen
  final List<Song> _queue = [];

  // Smart shuffle: gevulde zak met indices; huidige song staat altijd achteraan
  final List<int> _shuffleBag = [];

  Song? get currentSong => _currentSong;
  bool get isPlaying => _player.playing;
  bool get shuffleMode => _shuffleMode;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Duration get position => _player.position;
  Duration? get duration => _player.duration;
  Stream<String> get errorStream => _errorController.stream;
  List<Song> get queue => List.unmodifiable(_queue);

  /// Volgende songs in playlist na huidige (shuffle-volgorde of sequentieel).
  List<Song> get upcomingInPlaylist {
    if (_playlist.isEmpty) return [];
    if (_shuffleMode) {
      return _shuffleBag.map((i) => _playlist[i]).toList();
    }
    final result = <Song>[];
    for (var i = 1; i < _playlist.length && result.length < 20; i++) {
      final idx = (_currentIndex + i) % _playlist.length;
      result.add(_playlist[idx]);
    }
    return result;
  }

  AudioPlayer get _player => _handler.player;

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

  /// Vult de shuffle-zak met alle playlist-indices, huidige index altijd achteraan.
  void _fillShuffleBag() {
    final indices = List.generate(_playlist.length, (i) => i)..shuffle(_rng);
    if (indices.remove(_currentIndex)) indices.add(_currentIndex);
    _shuffleBag.addAll(indices);
  }

  /// Laadt en speelt een nummer af zonder playlist-state te wijzigen.
  Future<void> _loadAndPlay(Song song) async {
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
    } catch (_) {
      _errorController.add('errorCannotLoad');
    }
    notifyListeners();
  }

  /// Speelt een nummer af vanuit de UI (bijv. tik op song card).
  Future<void> playSong(Song song, List<Song> playlist, int index) async {
    if (_currentSong?.id == song.id) {
      await togglePlayPause();
      return;
    }
    _playlist = playlist;
    _currentIndex = index;
    if (_shuffleMode) {
      _shuffleBag.clear();
      _fillShuffleBag();
      _shuffleBag.remove(index);
    }
    await _loadAndPlay(song);
  }

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
    notifyListeners();
  }

  /// Speelt het volgende nummer: wachtrij eerst, daarna playlist (smart shuffle).
  Future<void> playNext() async {
    if (_queue.isNotEmpty) {
      final next = _queue.removeAt(0);
      notifyListeners();
      await _loadAndPlay(next);
      return;
    }
    if (_playlist.isEmpty) return;

    int nextIdx;
    if (_shuffleMode) {
      if (_shuffleBag.isEmpty) _fillShuffleBag();
      nextIdx = _shuffleBag.removeAt(0);
    } else {
      nextIdx = (_currentIndex + 1) % _playlist.length;
    }
    _currentIndex = nextIdx;
    await _loadAndPlay(_playlist[nextIdx]);
  }

  Future<void> playPrevious() async {
    if (_playlist.isEmpty) return;
    final prev = _currentIndex > 0 ? _currentIndex - 1 : _playlist.length - 1;
    _currentIndex = prev;
    await _loadAndPlay(_playlist[prev]);
  }

  // ── Wachtrij ────────────────────────────────────────────────────────────────

  void addToQueue(Song song) {
    _queue.add(song);
    notifyListeners();
  }

  void removeFromQueue(int index) {
    if (index >= 0 && index < _queue.length) {
      _queue.removeAt(index);
      notifyListeners();
    }
  }

  void clearQueue() {
    _queue.clear();
    notifyListeners();
  }

  // ── Shuffle ──────────────────────────────────────────────────────────────────

  void toggleShuffle() {
    _shuffleMode = !_shuffleMode;
    if (_shuffleMode && _playlist.isNotEmpty) {
      _shuffleBag.clear();
      _fillShuffleBag();
      _shuffleBag.remove(_currentIndex);
    } else {
      _shuffleBag.clear();
    }
    _saveShuffleMode();
    notifyListeners();
  }

  Future<void> shufflePlay(List<Song> playlist) async {
    if (playlist.isEmpty) return;
    _queue.clear();
    _shuffleBag.clear();
    _shuffleMode = true;
    _saveShuffleMode();
    _playlist = playlist;
    final startIdx = _rng.nextInt(playlist.length);
    _currentIndex = startIdx;
    _fillShuffleBag();
    _shuffleBag.remove(startIdx);
    await _loadAndPlay(playlist[startIdx]);
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  @override
  void dispose() {
    _errorController.close();
    _player.dispose();
    super.dispose();
  }
}
