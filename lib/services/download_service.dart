import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';

class DownloadedSongInfo {
  final int id;
  final String title;
  final String artist;
  final String path;

  const DownloadedSongInfo({
    required this.id,
    required this.title,
    required this.artist,
    required this.path,
  });
}

class DownloadService extends ChangeNotifier {
  static const _prefKey = 'downloaded_songs_v1';

  final String? _testBaseDir;
  // songId → {path, title, artist}
  final Map<int, Map<String, String>> _downloads = {};
  final Map<int, double> _progress = {};
  final Map<int, int> _sizes = {}; // cached file sizes in bytes

  DownloadService({String? testBaseDir}) : _testBaseDir = testBaseDir;

  bool isDownloaded(int songId) => _downloads.containsKey(songId);
  String? getLocalPath(int songId) => _downloads[songId]?['path'];
  bool isDownloading(int songId) => _progress.containsKey(songId);
  double getProgress(int songId) => _progress[songId] ?? 0.0;

  List<DownloadedSongInfo> get downloadedSongs => _downloads.entries
      .map((e) => DownloadedSongInfo(
            id: e.key,
            title: e.value['title'] ?? '',
            artist: e.value['artist'] ?? '',
            path: e.value['path'] ?? '',
          ))
      .toList();

  int getFileSizeBytes(int songId) => _sizes[songId] ?? 0;

  int get totalDownloadSizeBytes =>
      _sizes.values.fold(0, (sum, s) => sum + s);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    if (raw == null) return;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    for (final entry in map.entries) {
      final id = int.tryParse(entry.key);
      if (id == null) continue;
      final value = entry.value;
      String? path;
      String title = '';
      String artist = '';
      if (value is String) {
        // Migrate old format: {"id": "path"}
        path = value;
      } else if (value is Map) {
        path = value['path'] as String?;
        title = value['title'] as String? ?? '';
        artist = value['artist'] as String? ?? '';
      }
      if (path != null && File(path).existsSync()) {
        _downloads[id] = {'path': path, 'title': title, 'artist': artist};
        try {
          _sizes[id] = File(path).lengthSync();
        } catch (_) {
          _sizes[id] = 0;
        }
      }
    }
    notifyListeners();
  }

  Future<String> _downloadsDir() async {
    if (_testBaseDir != null) return _testBaseDir;
    final base = await getApplicationDocumentsDirectory();
    return '${base.path}/song_downloads';
  }

  Future<void> download(Song song, Dio dio) async {
    if (isDownloaded(song.id) || isDownloading(song.id)) return;

    final dir = await _downloadsDir();
    await Directory(dir).create(recursive: true);
    final localPath = '$dir/${song.id}.mp3';

    _progress[song.id] = 0.0;
    notifyListeners();

    try {
      await dio.download(
        song.audioUrl,
        localPath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            _progress[song.id] = received / total;
            notifyListeners();
          }
        },
      );
      _downloads[song.id] = {
        'path': localPath,
        'title': song.title,
        'artist': song.artist,
      };
      try {
        _sizes[song.id] = File(localPath).lengthSync();
      } catch (_) {
        _sizes[song.id] = 0;
      }
      await _persist();
    } catch (_) {
      final f = File(localPath);
      if (f.existsSync()) f.deleteSync();
    } finally {
      _progress.remove(song.id);
      notifyListeners();
    }
  }

  Future<void> delete(int songId) async {
    final entry = _downloads.remove(songId);
    _sizes.remove(songId);
    if (entry != null) {
      final path = entry['path'];
      if (path != null) {
        final f = File(path);
        if (f.existsSync()) f.deleteSync();
      }
      await _persist();
      notifyListeners();
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final map = _downloads.map((k, v) => MapEntry(k.toString(), v));
    await prefs.setString(_prefKey, jsonEncode(map));
  }
}
