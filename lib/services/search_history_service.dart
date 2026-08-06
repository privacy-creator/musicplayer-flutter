import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchHistoryService extends ChangeNotifier {
  static const _prefKey = 'search_history_v1';
  static const _maxEntries = 10;

  List<String> _history = [];

  List<String> get history => List.unmodifiable(_history);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefKey);
    if (raw == null) return;
    _history = raw;
    notifyListeners();
  }

  Future<void> add(String term) async {
    final trimmed = term.trim();
    if (trimmed.isEmpty) return;
    _history.removeWhere((e) => e.toLowerCase() == trimmed.toLowerCase());
    _history.insert(0, trimmed);
    if (_history.length > _maxEntries) {
      _history = _history.sublist(0, _maxEntries);
    }
    notifyListeners();
    await _persist();
  }

  Future<void> remove(String term) async {
    final removed = _history.remove(term);
    if (!removed) return;
    notifyListeners();
    await _persist();
  }

  Future<void> clear() async {
    if (_history.isEmpty) return;
    _history = [];
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefKey, _history);
  }
}
