import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/local_track.dart';
import 'local_audio_scanner.dart';

enum LocalScanStatus { ok, permissionDenied, alreadyScanning, error }

class LocalScanResult {
  final LocalScanStatus status;
  final int added;
  final int removed;
  const LocalScanResult(this.status, {this.added = 0, this.removed = 0});
}

class LocalRenameException implements Exception {
  final String message;
  const LocalRenameException(this.message);
  @override
  String toString() => 'LocalRenameException: $message';
}

typedef PermissionRequester = Future<bool> Function();
typedef RootsProvider = Future<List<String>> Function();
typedef DirectoryScanner = Future<List<ScannedFile>> Function(List<String>);

/// Beheert muziek die lokaal op het apparaat staat: scannen, hernoemen en
/// lokale (niet-deelbare) afspeellijsten. Alles wordt alleen in
/// SharedPreferences bewaard; er gaat niets naar de server en de bestanden
/// blijven waar ze staan.
class LocalLibraryService extends ChangeNotifier {
  static const tracksKey = 'local_tracks_v1';
  static const playlistsKey = 'local_playlists_v1';
  static const lastScanKey = 'local_last_scan_v1';

  final PermissionRequester _requestPermission;
  final RootsProvider _roots;
  final DirectoryScanner _scanner;

  // pad → track, in volgorde van ontdekking
  final Map<String, LocalTrack> _tracks = {};
  final List<LocalPlaylist> _playlists = [];
  bool _scanning = false;
  DateTime? _lastScan;
  int _idSeq = 0;

  LocalLibraryService({
    PermissionRequester? requestPermission,
    RootsProvider? roots,
    DirectoryScanner? scanner,
  })  : _requestPermission = requestPermission ?? defaultRequestPermission,
        _roots = roots ?? defaultScanRoots,
        _scanner = scanner ?? scanDirectories;

  bool get isScanning => _scanning;
  DateTime? get lastScan => _lastScan;
  bool get hasScanned => _lastScan != null;

  /// Alle lokale nummers, alfabetisch op titel.
  List<LocalTrack> get tracks {
    final list = _tracks.values.toList()
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return list;
  }

  List<LocalPlaylist> get playlists => List.unmodifiable(_playlists);

  LocalTrack? trackByPath(String path) => _tracks[path];

  LocalPlaylist? playlistById(String id) {
    for (final p in _playlists) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Nummers van een playlist in de opgeslagen volgorde; paden waarvan het
  /// bestand niet meer in de bibliotheek staat worden overgeslagen.
  List<LocalTrack> tracksForPlaylist(String id) {
    final p = playlistById(id);
    if (p == null) return const [];
    return [
      for (final path in p.paths)
        if (_tracks[path] != null) _tracks[path]!,
    ];
  }

  /// Filtert op titel, artiest of bestandsnaam (hoofdletterongevoelig).
  List<LocalTrack> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return tracks;
    return tracks
        .where((t) =>
            t.title.toLowerCase().contains(q) ||
            t.artist.toLowerCase().contains(q) ||
            t.fileName.toLowerCase().contains(q))
        .toList();
  }

  // ── Opslag ──────────────────────────────────────────────────────────────────

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _tracks.clear();
    _playlists.clear();
    final rawTracks = prefs.getString(tracksKey);
    if (rawTracks != null) {
      try {
        for (final j in jsonDecode(rawTracks) as List<dynamic>) {
          final t = LocalTrack.fromJson(j as Map<String, dynamic>);
          _tracks[t.path] = t;
        }
      } catch (_) {}
    }
    final rawPlaylists = prefs.getString(playlistsKey);
    if (rawPlaylists != null) {
      try {
        for (final j in jsonDecode(rawPlaylists) as List<dynamic>) {
          _playlists.add(LocalPlaylist.fromJson(j as Map<String, dynamic>));
        }
      } catch (_) {}
    }
    final last = prefs.getInt(lastScanKey);
    _lastScan = last != null ? DateTime.fromMillisecondsSinceEpoch(last) : null;
    notifyListeners();
  }

  Future<void> _persistTracks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        tracksKey, jsonEncode(_tracks.values.map((t) => t.toJson()).toList()));
  }

  Future<void> _persistPlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        playlistsKey, jsonEncode(_playlists.map((p) => p.toJson()).toList()));
  }

  // ── Scannen ─────────────────────────────────────────────────────────────────

  /// Vraagt toegang tot de opslag en doorzoekt het apparaat naar
  /// audiobestanden. Bestaande nummers behouden hun (eventueel aangepaste)
  /// naam; verdwenen bestanden verdwijnen uit de bibliotheek.
  Future<LocalScanResult> scan() async {
    if (_scanning) return const LocalScanResult(LocalScanStatus.alreadyScanning);
    _scanning = true;
    notifyListeners();
    try {
      if (!await _requestPermission()) {
        return const LocalScanResult(LocalScanStatus.permissionDenied);
      }
      final found = await _scanner(await _roots());
      final foundPaths = <String>{};
      var added = 0;
      for (final f in found) {
        foundPaths.add(f.path);
        final existing = _tracks[f.path];
        if (existing != null) {
          _tracks[f.path] = existing.copyWith(sizeBytes: f.sizeBytes);
        } else {
          _tracks[f.path] = LocalTrack.fromPath(f.path, sizeBytes: f.sizeBytes);
          added++;
        }
      }
      final missing =
          _tracks.keys.where((p) => !foundPaths.contains(p)).toList();
      for (final p in missing) {
        _tracks.remove(p);
      }
      _lastScan = DateTime.now();
      await _persistTracks();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(lastScanKey, _lastScan!.millisecondsSinceEpoch);
      return LocalScanResult(LocalScanStatus.ok,
          added: added, removed: missing.length);
    } catch (_) {
      return const LocalScanResult(LocalScanStatus.error);
    } finally {
      _scanning = false;
      notifyListeners();
    }
  }

  // ── Hernoemen ───────────────────────────────────────────────────────────────

  /// Wijzigt de weergavenaam van een lokaal nummer. Met [renameFile] wordt
  /// ook het bestand op het apparaat hernoemd (in dezelfde map, extensie
  /// blijft gelijk); playlists worden dan bijgewerkt naar het nieuwe pad.
  /// Geeft het (mogelijk nieuwe) pad terug.
  Future<String> renameTrack(
    String path, {
    required String title,
    String artist = '',
    bool renameFile = false,
  }) async {
    final track = _tracks[path];
    if (track == null) throw const LocalRenameException('not_found');
    final cleanTitle = title.trim();
    final cleanArtist = artist.trim();
    if (cleanTitle.isEmpty) throw const LocalRenameException('empty_title');

    var newPath = path;
    if (renameFile) {
      final base = sanitizeFileName(
          cleanArtist.isEmpty ? cleanTitle : '$cleanArtist - $cleanTitle');
      final sepIdx = path.lastIndexOf(RegExp(r'[/\\]'));
      final dir = sepIdx >= 0 ? path.substring(0, sepIdx + 1) : '';
      final ext = track.extension.isEmpty ? '' : '.${track.extension}';
      newPath = '$dir$base$ext';
      if (newPath != path) {
        if (File(newPath).existsSync() || _tracks.containsKey(newPath)) {
          throw const LocalRenameException('exists');
        }
        try {
          await File(path).rename(newPath);
        } on FileSystemException {
          throw const LocalRenameException('io');
        }
      }
    }

    final updated =
        track.copyWith(path: newPath, title: cleanTitle, artist: cleanArtist);
    if (newPath == path) {
      _tracks[path] = updated;
    } else {
      // Volgorde behouden: map opnieuw opbouwen met de nieuwe sleutel.
      final entries = _tracks.entries.toList();
      _tracks
        ..clear()
        ..addEntries(entries.map((e) =>
            e.key == path ? MapEntry(newPath, updated) : e));
      for (var i = 0; i < _playlists.length; i++) {
        final p = _playlists[i];
        if (p.paths.contains(path)) {
          _playlists[i] = p.copyWith(
              paths: [for (final x in p.paths) x == path ? newPath : x]);
        }
      }
      await _persistPlaylists();
    }
    await _persistTracks();
    notifyListeners();
    return newPath;
  }

  /// Verwijdert tekens die niet in een bestandsnaam mogen.
  static String sanitizeFileName(String name) {
    final cleaned = name
        .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    // Windows staat geen punt/spatie aan het eind toe.
    return cleaned.replaceAll(RegExp(r'[. ]+$'), '');
  }

  // ── Lokale playlists ────────────────────────────────────────────────────────

  Future<LocalPlaylist> createPlaylist(String name) async {
    final clean = name.trim();
    if (clean.isEmpty) throw ArgumentError('name');
    final p = LocalPlaylist(
      id: 'lp_${DateTime.now().microsecondsSinceEpoch}_${_idSeq++}',
      name: clean,
      paths: const [],
    );
    _playlists.add(p);
    await _persistPlaylists();
    notifyListeners();
    return p;
  }

  Future<void> renamePlaylist(String id, String name) async {
    final clean = name.trim();
    if (clean.isEmpty) return;
    _update(id, (p) => p.copyWith(name: clean));
    await _persistPlaylists();
    notifyListeners();
  }

  Future<void> deletePlaylist(String id) async {
    _playlists.removeWhere((p) => p.id == id);
    await _persistPlaylists();
    notifyListeners();
  }

  /// Voegt een nummer toe; geeft false als het er al in stond.
  Future<bool> addToPlaylist(String id, String path) async {
    final p = playlistById(id);
    if (p == null || p.paths.contains(path)) return false;
    _update(id, (p) => p.copyWith(paths: [...p.paths, path]));
    await _persistPlaylists();
    notifyListeners();
    return true;
  }

  Future<void> removeFromPlaylist(String id, String path) async {
    _update(id,
        (p) => p.copyWith(paths: p.paths.where((x) => x != path).toList()));
    await _persistPlaylists();
    notifyListeners();
  }

  void _update(String id, LocalPlaylist Function(LocalPlaylist) fn) {
    final i = _playlists.indexWhere((p) => p.id == id);
    if (i >= 0) _playlists[i] = fn(_playlists[i]);
  }

  // ── Platform-standaarden ────────────────────────────────────────────────────

  /// Android: eerst "toegang tot alle bestanden" (Android 11+), anders de
  /// audio-mediarechten (13+) of de oude opslagrechten. Andere platformen
  /// hebben geen runtime-toestemming nodig.
  static Future<bool> defaultRequestPermission() async {
    if (!Platform.isAndroid) return true;
    try {
      if (await Permission.manageExternalStorage.request().isGranted) {
        return true;
      }
    } catch (_) {}
    if (await Permission.audio.request().isGranted) return true;
    return (await Permission.storage.request()).isGranted;
  }

  static Future<List<String>> defaultScanRoots() async {
    if (Platform.isAndroid) {
      final roots = <String>['/storage/emulated/0'];
      // Externe SD-kaarten / USB-opslag
      try {
        for (final e in Directory('/storage').listSync(followLinks: false)) {
          final name = e.path.split('/').last;
          if (e is Directory && name != 'emulated' && name != 'self') {
            roots.add(e.path);
          }
        }
      } catch (_) {}
      return roots;
    }
    if (Platform.isIOS) {
      // iOS staat alleen toegang tot de eigen app-map toe (bestanden die via
      // de Bestanden-app in "Music Player" zijn gezet).
      final docs = await getApplicationDocumentsDirectory();
      return [docs.path];
    }
    if (Platform.isWindows) {
      final home = Platform.environment['USERPROFILE'];
      return home != null ? [home] : const [];
    }
    var home = Platform.environment['HOME'];
    if (home == null) return const [];
    if (Platform.isMacOS) {
      // In de sandbox wijst HOME naar de container; het echte thuismap-pad
      // staat ervoor. Met de music-entitlement is ~/Music leesbaar.
      final i = home.indexOf('/Library/Containers/');
      if (i > 0) home = home.substring(0, i);
      return ['$home/Music'];
    }
    return [home];
  }
}
