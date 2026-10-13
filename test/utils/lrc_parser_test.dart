import 'package:flutter_test/flutter_test.dart';
import 'package:music_player_flutter/utils/lrc_parser.dart';

void main() {
  group('formatLrcTimestamp', () {
    test('formatteert minuten, seconden en honderdsten', () {
      expect(
        formatLrcTimestamp(
            const Duration(minutes: 1, seconds: 2, milliseconds: 340)),
        '[01:02.34]',
      );
    });

    test('nul wordt [00:00.00]', () {
      expect(formatLrcTimestamp(Duration.zero), '[00:00.00]');
    });

    test('kapt milliseconden af in plaats van af te ronden', () {
      expect(formatLrcTimestamp(const Duration(milliseconds: 1999)),
          '[00:01.99]');
    });

    test('negatieve duur wordt geklemd op nul', () {
      expect(formatLrcTimestamp(const Duration(seconds: -3)), '[00:00.00]');
    });

    test('ondersteunt meer dan tien minuten', () {
      expect(formatLrcTimestamp(const Duration(minutes: 12, seconds: 5)),
          '[12:05.00]');
    });

    test('round-trip met parseLrcLine is exact', () {
      for (final ms in [0, 10, 990, 12340, 61230, 359990]) {
        final d = Duration(milliseconds: ms);
        final parsed = parseLrcLine('${formatLrcTimestamp(d)} tekst');
        expect(parsed!.timestamp, d, reason: 'voor $ms ms');
      }
    });
  });

  group('parseLrcLine', () {
    test('parset een getimede regel', () {
      final line = parseLrcLine('[00:12.30] Eerste regel');
      expect(line!.timestamp, const Duration(seconds: 12, milliseconds: 300));
      expect(line.text, 'Eerste regel');
    });

    test('geeft null voor een regel zonder tijd', () {
      expect(parseLrcLine('Gewoon tekst'), isNull);
    });

    test('geeft null voor metadata-tags', () {
      expect(parseLrcLine('[ar:Artiest]'), isNull);
    });

    test('accepteert een getimede regel zonder tekst', () {
      final line = parseLrcLine('[01:00.00]');
      expect(line!.text, '');
      expect(line.timestamp, const Duration(minutes: 1));
    });
  });

  group('parseLrc', () {
    test('slaat ongetimede regels over en sorteert op tijd', () {
      final lines = parseLrc('[00:10.00] B\nplat\n[00:05.00] A');
      expect(lines.map((l) => l.text), ['A', 'B']);
    });
  });
}
