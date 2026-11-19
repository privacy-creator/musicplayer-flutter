import 'package:flutter_test/flutter_test.dart';
import 'package:music_player_flutter/models/local_track.dart';

void main() {
  group('LocalTrack.parseFileName', () {
    test('splitst "Artiest - Titel.mp3" in artiest en titel', () {
      final r = LocalTrack.parseFileName('Queen - Bohemian Rhapsody.mp3');
      expect(r.artist, 'Queen');
      expect(r.title, 'Bohemian Rhapsody');
    });

    test('zonder scheidingsteken wordt alles de titel', () {
      final r = LocalTrack.parseFileName('opname_01.m4a');
      expect(r.title, 'opname 01');
      expect(r.artist, '');
    });

    test('alleen het eerste " - " scheidt artiest en titel', () {
      final r = LocalTrack.parseFileName('A - B - C.flac');
      expect(r.artist, 'A');
      expect(r.title, 'B - C');
    });

    test('bestand zonder extensie blijft leesbaar', () {
      expect(LocalTrack.parseFileName('nummer').title, 'nummer');
    });
  });

  group('LocalTrack.id', () {
    test('is altijd negatief zodat het niet botst met cloud-id\'s', () {
      for (final p in ['/a.mp3', '/storage/emulated/0/Music/x.mp3', r'C:\m\y.flac']) {
        expect(LocalTrack.idForPath(p), lessThan(0));
      }
    });

    test('is stabiel voor hetzelfde pad', () {
      expect(LocalTrack.idForPath('/music/a.mp3'),
          LocalTrack.idForPath('/music/a.mp3'));
    });

    test('verschilt voor verschillende paden', () {
      expect(LocalTrack.idForPath('/music/a.mp3'),
          isNot(LocalTrack.idForPath('/music/b.mp3')));
    });
  });

  group('LocalTrack', () {
    test('fromPath leidt titel, artiest en bestandsnaam af', () {
      final t = LocalTrack.fromPath('/music/Adele - Hello.MP3', sizeBytes: 10);
      expect(t.title, 'Hello');
      expect(t.artist, 'Adele');
      expect(t.fileName, 'Adele - Hello.MP3');
      expect(t.extension, 'mp3');
      expect(t.sizeBytes, 10);
    });

    test('fromPath werkt met Windows-paden', () {
      final t = LocalTrack.fromPath(r'C:\Users\x\Music\Lied.wav');
      expect(t.fileName, 'Lied.wav');
      expect(t.title, 'Lied');
    });

    test('toSong geeft een lokaal Song met het bestandspad als audioUrl', () {
      final t = LocalTrack.fromPath('/music/Hello.mp3');
      final s = t.toSong();
      expect(s.isLocal, true);
      expect(s.id, t.id);
      expect(s.audioUrl, '/music/Hello.mp3');
      expect(s.imageUrl, isNull);
    });

    test('JSON heen en terug behoudt alle velden', () {
      const t = LocalTrack(
          path: '/m/a.mp3', title: 'T', artist: 'A', sizeBytes: 42);
      final back = LocalTrack.fromJson(t.toJson());
      expect(back.path, t.path);
      expect(back.title, 'T');
      expect(back.artist, 'A');
      expect(back.sizeBytes, 42);
    });
  });

  group('LocalPlaylist', () {
    test('is nooit deelbaar', () {
      const p = LocalPlaylist(id: 'lp_1', name: 'Mijn lijst');
      expect(p.isShareable, false);
    });

    test('JSON heen en terug behoudt naam en volgorde van paden', () {
      const p = LocalPlaylist(id: 'lp_1', name: 'L', paths: ['/b', '/a']);
      final back = LocalPlaylist.fromJson(p.toJson());
      expect(back.id, 'lp_1');
      expect(back.name, 'L');
      expect(back.paths, ['/b', '/a']);
    });
  });
}
