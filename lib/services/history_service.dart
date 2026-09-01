import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/history_entry.dart';

const _historyKey = 'listening_history_v1';
const _maxHistoryEntries = 300;

/// Tracks per-device listening history (no backend — this is a single-user
/// app) so the UI can offer "Continue listening" and "On this day".
class HistoryService extends ChangeNotifier {
  final SharedPreferences _prefs;
  List<HistoryEntry> _entries = [];

  HistoryService(this._prefs) {
    _load();
  }

  List<HistoryEntry> get entries => List.unmodifiable(_entries);

  /// Most recent plays first, one entry per song, capped for the UI row.
  List<HistoryEntry> get continueListening => _entries.take(15).toList();

  /// Entries whose play date matches today's month/day in a previous year.
  List<HistoryEntry> onThisDay() {
    final now = DateTime.now();
    return _entries
        .where((e) =>
            e.playedAt.month == now.month &&
            e.playedAt.day == now.day &&
            e.playedAt.year != now.year)
        .toList();
  }

  void _load() {
    final raw = _prefs.getString(_historyKey);
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List;
      _entries =
          list.cast<Map<String, dynamic>>().map(HistoryEntry.fromJson).toList();
    } catch (_) {
      _entries = [];
    }
  }

  Future<void> _save() async {
    await _prefs.setString(
      _historyKey,
      jsonEncode(_entries.map((e) => e.toJson()).toList()),
    );
  }

  /// Records that [songId] just started playing.
  Future<void> recordPlay(int songId) async {
    _entries.removeWhere((e) => e.songId == songId);
    _entries.insert(0, HistoryEntry(songId: songId, playedAt: DateTime.now()));
    if (_entries.length > _maxHistoryEntries) {
      _entries = _entries.sublist(0, _maxHistoryEntries);
    }
    notifyListeners();
    await _save();
  }

  /// Updates the resume position for the currently-playing song's entry.
  Future<void> updatePosition(int songId, Duration position) async {
    final index = _entries.indexWhere((e) => e.songId == songId);
    if (index == -1) return;
    _entries[index] = _entries[index].copyWith(lastPosition: position);
    await _save();
  }
}
