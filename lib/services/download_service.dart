import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';

class DownloadService extends ChangeNotifier {
  static const _prefKey = 'downloaded_songs_v1';

  final String? _testBaseDir;
  final Map<int, String> _downloads = {};
  final Map<int, double> _progress = {};

  DownloadService({String? testBaseDir}) : _testBaseDir = testBaseDir;

  bool isDownloaded(int songId) => _downloads.containsKey(songId);
  String? getLocalPath(int songId) => _downloads[songId];
  bool isDownloading(int songId) => _progress.containsKey(songId);
  double getProgress(int songId) => _progress[songId] ?? 0.0;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    if (raw == null) return;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    for (final entry in map.entries) {
      final id = int.tryParse(entry.key);
      final path = entry.value as String?;
      if (id != null && path != null && File(path).existsSync()) {
        _downloads[id] = path;
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
      _downloads[song.id] = localPath;
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
    final path = _downloads.remove(songId);
    if (path != null) {
      final f = File(path);
      if (f.existsSync()) f.deleteSync();
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
