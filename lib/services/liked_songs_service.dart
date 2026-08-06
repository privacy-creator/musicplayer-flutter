import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';

class LikedSongsService extends ChangeNotifier {
  static const _prefKey = 'liked_songs_v1';

  // songId → {song: Song.toJson(), likedAt: epochMillis}
  final Map<int, Map<String, dynamic>> _liked = {};

  bool isLiked(int songId) => _liked.containsKey(songId);

  List<Song> get likedSongs {
    final entries = _liked.values.toList()
      ..sort((a, b) =>
          (b['likedAt'] as int).compareTo(a['likedAt'] as int));
    return entries
        .map((e) => Song.fromJson(e['song'] as Map<String, dynamic>))
        .toList();
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    if (raw == null) return;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    for (final entry in map.entries) {
      final id = int.tryParse(entry.key);
      if (id == null) continue;
      _liked[id] = entry.value as Map<String, dynamic>;
    }
    notifyListeners();
  }

  Future<void> like(Song song) async {
    if (isLiked(song.id)) return;
    _liked[song.id] = {
      'song': song.toJson(),
      'likedAt': DateTime.now().millisecondsSinceEpoch,
    };
    notifyListeners();
    await _persist();
  }

  Future<void> unlike(int songId) async {
    if (_liked.remove(songId) == null) return;
    notifyListeners();
    await _persist();
  }

  Future<void> toggle(Song song) {
    return isLiked(song.id) ? unlike(song.id) : like(song);
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final map = _liked.map((k, v) => MapEntry(k.toString(), v));
    await prefs.setString(_prefKey, jsonEncode(map));
  }
}
