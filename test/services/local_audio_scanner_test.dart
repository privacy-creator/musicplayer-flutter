import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:music_player_flutter/services/local_audio_scanner.dart';

void main() {
  late Directory root;

  void writeFile(String relPath, int bytes) {
    final f = File('${root.path}/$relPath');
    f.parent.createSync(recursive: true);
    f.writeAsBytesSync(List.filled(bytes, 0));
  }

  List<String> names(List<ScannedFile> files) =>
      files.map((f) => f.path.split(RegExp(r'[/\\]')).last).toList()..sort();

  setUp(() {
    root = Directory.systemTemp.createTempSync('scan_test_');
  });

  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  group('isAudioFile', () {
    test('herkent gangbare audio-extensies, ongeacht hoofdletters', () {
      expect(isAudioFile('/a/b.mp3'), true);
      expect(isAudioFile('/a/b.FLAC'), true);
      expect(isAudioFile('/a/b.m4a'), true);
      expect(isAudioFile('/a/b.opus'), true);
    });

    test('negeert andere bestanden', () {
      expect(isAudioFile('/a/b.jpg'), false);
      expect(isAudioFile('/a/b.txt'), false);
      expect(isAudioFile('/a/mp3'), false);
      expect(isAudioFile('/a/b.'), false);
    });
  });

  group('scanDirectoriesSync', () {
    test('vindt audiobestanden recursief en negeert andere bestanden', () {
      writeFile('a.mp3', 100);
      writeFile('sub/deeper/b.flac', 100);
      writeFile('sub/cover.jpg', 100);
      final result = scanDirectoriesSync([root.path], minBytes: 0);
      expect(names(result), ['a.mp3', 'b.flac']);
    });

    test('slaat verborgen mappen en bestanden over', () {
      writeFile('.hidden/a.mp3', 100);
      writeFile('.b.mp3', 100);
      writeFile('c.mp3', 100);
      expect(names(scanDirectoriesSync([root.path], minBytes: 0)), ['c.mp3']);
    });

    test('slaat Android/data en Android/obb over', () {
      writeFile('Android/data/com.app/x.mp3', 100);
      writeFile('Android/obb/y.mp3', 100);
      writeFile('Android/media/z.mp3', 100);
      expect(names(scanDirectoriesSync([root.path], minBytes: 0)), ['z.mp3']);
    });

    test('slaat bestanden kleiner dan minBytes over', () {
      writeFile('klein.mp3', 10);
      writeFile('groot.mp3', 2000);
      final result = scanDirectoriesSync([root.path], minBytes: 1000);
      expect(names(result), ['groot.mp3']);
      expect(result.single.sizeBytes, 2000);
    });

    test('niet-bestaande root levert een lege lijst op', () {
      expect(scanDirectoriesSync(['${root.path}/bestaat-niet']), isEmpty);
    });

    test('dubbele roots leveren geen dubbele resultaten op', () {
      writeFile('a.mp3', 100);
      final result = scanDirectoriesSync([root.path, root.path], minBytes: 0);
      expect(result, hasLength(1));
    });

    test('maxFiles begrenst het aantal resultaten', () {
      for (var i = 0; i < 5; i++) {
        writeFile('n$i.mp3', 100);
      }
      expect(scanDirectoriesSync([root.path], minBytes: 0, maxFiles: 3),
          hasLength(3));
    });
  });

  test('scanDirectories draait in een isolate met hetzelfde resultaat',
      () async {
    writeFile('a.mp3', 64 * 1024);
    final result = await scanDirectories([root.path]);
    expect(names(result), ['a.mp3']);
  });
}
