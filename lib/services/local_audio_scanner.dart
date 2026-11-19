import 'dart:io';
import 'dart:isolate';

/// Bestandsextensies die als audio worden herkend.
const kAudioExtensions = {
  'mp3', 'm4a', 'aac', 'flac', 'wav', 'ogg', 'oga', 'opus', 'wma',
  'aif', 'aiff', 'alac', 'amr', 'mka', 'weba', '3gp',
};

/// Mappen die nooit doorzocht worden (app-data, caches, systeemmappen).
const _skipDirNames = {
  'appdata', 'node_modules', r'$recycle.bin', 'system volume information',
  'library', 'cache', '.cache', 'proc', 'sys', 'dev',
};

/// Paden (lowercase, met `/`) die overgeslagen worden.
const _skipPathSuffixes = ['/android/data', '/android/obb'];

class ScannedFile {
  final String path;
  final int sizeBytes;
  const ScannedFile(this.path, this.sizeBytes);
}

bool isAudioFile(String path) {
  final dot = path.lastIndexOf('.');
  if (dot < 0 || dot == path.length - 1) return false;
  return kAudioExtensions.contains(path.substring(dot + 1).toLowerCase());
}

/// Doorzoekt [roots] recursief naar audiobestanden. Verborgen mappen
/// (beginnend met `.`), app-data en mappen zonder leesrechten worden
/// overgeslagen. Bestanden kleiner dan [minBytes] (systeemgeluidjes)
/// tellen niet mee. Symlinks worden niet gevolgd, zodat er geen lussen
/// ontstaan.
List<ScannedFile> scanDirectoriesSync(
  List<String> roots, {
  int minBytes = 32 * 1024,
  int maxFiles = 50000,
}) {
  final result = <ScannedFile>[];
  final seen = <String>{};
  final stack = <Directory>[
    for (final r in roots)
      if (Directory(r).existsSync()) Directory(r),
  ];

  while (stack.isNotEmpty && result.length < maxFiles) {
    final dir = stack.removeLast();
    final normalized = dir.path.replaceAll('\\', '/').toLowerCase();
    if (!seen.add(normalized)) continue;
    if (_skipPathSuffixes.any(normalized.endsWith)) continue;

    List<FileSystemEntity> entries;
    try {
      entries = dir.listSync(followLinks: false);
    } catch (_) {
      continue; // geen leesrechten
    }
    for (final e in entries) {
      if (result.length >= maxFiles) break;
      final name = e.path.split(RegExp(r'[/\\]')).last;
      if (name.startsWith('.')) continue;
      if (e is Directory) {
        if (!_skipDirNames.contains(name.toLowerCase())) stack.add(e);
      } else if (e is File && isAudioFile(e.path)) {
        int size;
        try {
          size = e.lengthSync();
        } catch (_) {
          continue;
        }
        if (size >= minBytes) result.add(ScannedFile(e.path, size));
      }
    }
  }
  return result;
}

/// Zelfde als [scanDirectoriesSync], maar in een aparte isolate zodat de UI
/// niet hapert bij grote opslag.
Future<List<ScannedFile>> scanDirectories(List<String> roots) =>
    Isolate.run(() => scanDirectoriesSync(roots));
