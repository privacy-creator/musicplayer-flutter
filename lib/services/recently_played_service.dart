import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';

class RecentlyPlayedService extends ChangeNotifier {
  static const _prefKey = 'recently_played_v1';
  static const _maxEntries = 30;

  // songId → {song: Song.toJson(), playedAt: epochMillis, seq: monotonic order}
  final Map<int, Map<String, dynamic>> _entries = {};

  // Ordering uses this counter rather than playedAt (wall-clock millis),
  // since plays that happen within the same millisecond would otherwise tie
  // and List.sort() doesn't guarantee ties preserve insertion order.
  int _nextSeq = 0;

  List<Song> get recentSongs {
    final entries = _entries.values.toList()
      ..sort((a, b) => (b['seq'] as int).compareTo(a['seq'] as int));
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
      final value = entry.value as Map<String, dynamic>;
      _entries[id] = value;
      final seq = value['seq'] as int? ?? 0;
      if (seq >= _nextSeq) _nextSeq = seq + 1;
    }
    notifyListeners();
  }

  Future<void> recordPlay(Song song) async {
    _entries[song.id] = {
      'song': song.toJson(),
      'playedAt': DateTime.now().millisecondsSinceEpoch,
      'seq': _nextSeq++,
    };
    _trim();
    notifyListeners();
    await _persist();
  }

  void _trim() {
    if (_entries.length <= _maxEntries) return;
    final sorted = _entries.entries.toList()
      ..sort((a, b) =>
          (a.value['seq'] as int).compareTo(b.value['seq'] as int));
    final toDrop = sorted.length - _maxEntries;
    for (var i = 0; i < toDrop; i++) {
      _entries.remove(sorted[i].key);
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final map = _entries.map((k, v) => MapEntry(k.toString(), v));
    await prefs.setString(_prefKey, jsonEncode(map));
  }
}
