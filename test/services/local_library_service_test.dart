import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:music_player_flutter/services/local_audio_scanner.dart';
import 'package:music_player_flutter/services/local_library_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late List<ScannedFile> fakeFiles;
  late bool permissionGranted;
  late LocalLibraryService service;

  LocalLibraryService makeService() => LocalLibraryService(
        requestPermission: () async => permissionGranted,
        roots: () async => ['/fake'],
        scanner: (_) async => fakeFiles,
      );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    permissionGranted = true;
    fakeFiles = const [
      ScannedFile('/fake/Queen - Bohemian Rhapsody.mp3', 5000),
      ScannedFile('/fake/abba - Dancing Queen.flac', 7000),
      ScannedFile('/fake/notitie.m4a', 3000),
    ];
    service = makeService();
    await service.init();
  });

  group('Beginwaarden', () {
    test('bibliotheek is leeg en nog niet gescand', () {
      expect(service.tracks, isEmpty);
      expect(service.playlists, isEmpty);
      expect(service.hasScanned, false);
      expect(service.isScanning, false);
    });
  });

  group('scan', () {
    test('voegt gevonden bestanden toe, alfabetisch op titel', () async {
      final r = await service.scan();
      expect(r.status, LocalScanStatus.ok);
      expect(r.added, 3);
      expect(service.tracks.map((t) => t.title).toList(),
          ['Bohemian Rhapsody', 'Dancing Queen', 'notitie']);
      expect(service.hasScanned, true);
    });

    test('alle lokale nummers hebben een negatief id', () async {
      await service.scan();
      for (final t in service.tracks) {
        expect(t.toSong().isLocal, true);
      }
    });

    test('zonder toestemming wordt niets toegevoegd', () async {
      permissionGranted = false;
      final r = await service.scan();
      expect(r.status, LocalScanStatus.permissionDenied);
      expect(service.tracks, isEmpty);
      expect(service.isScanning, false);
    });

    test('fout in de scanner levert status error op', () async {
      final s = LocalLibraryService(
        requestPermission: () async => true,
        roots: () async => const [],
        scanner: (_) async => throw const FileSystemException('kapot'),
      );
      final r = await s.scan();
      expect(r.status, LocalScanStatus.error);
      expect(s.isScanning, false);
    });

    test('verdwenen bestanden worden verwijderd bij een nieuwe scan', () async {
      await service.scan();
      fakeFiles = [fakeFiles.first];
      final r = await service.scan();
      expect(r.removed, 2);
      expect(r.added, 0);
      expect(service.tracks, hasLength(1));
    });

    test('een hernoemd nummer behoudt zijn naam bij opnieuw scannen', () async {
      await service.scan();
      await service.renameTrack('/fake/notitie.m4a',
          title: 'Mijn opname', artist: 'Ik');
      await service.scan();
      final t = service.trackByPath('/fake/notitie.m4a')!;
      expect(t.title, 'Mijn opname');
      expect(t.artist, 'Ik');
    });

    test('tijdens het scannen staat isScanning aan', () async {
      final states = <bool>[];
      service.addListener(() => states.add(service.isScanning));
      await service.scan();
      expect(states.first, true);
      expect(states.last, false);
    });
  });

  group('persistentie', () {
    test('nummers en playlists blijven bewaard na herstart', () async {
      await service.scan();
      final p = await service.createPlaylist('Favoriet');
      await service.addToPlaylist(p.id, '/fake/notitie.m4a');

      final fresh = makeService();
      await fresh.init();
      expect(fresh.tracks, hasLength(3));
      expect(fresh.playlists.single.name, 'Favoriet');
      expect(fresh.tracksForPlaylist(p.id).single.path, '/fake/notitie.m4a');
      expect(fresh.hasScanned, true);
    });

    test('lokale data staat los van de cloud-cache', () async {
      await service.scan();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(LocalLibraryService.tracksKey), isNotNull);
      expect(prefs.getString('songs_cache_v1'), isNull);
      final stored =
          jsonDecode(prefs.getString(LocalLibraryService.tracksKey)!) as List;
      expect(stored, hasLength(3));
    });

    test('kapotte opgeslagen JSON wordt genegeerd', () async {
      SharedPreferences.setMockInitialValues({
        LocalLibraryService.tracksKey: 'geen json',
        LocalLibraryService.playlistsKey: '[{',
      });
      final s = makeService();
      await s.init();
      expect(s.tracks, isEmpty);
      expect(s.playlists, isEmpty);
    });
  });

  group('zoeken', () {
    setUp(() => service.scan());

    test('zoekt op titel, artiest en bestandsnaam', () {
      expect(service.search('queen'), hasLength(2)); // titel + artiest
      expect(service.search('ABBA').single.title, 'Dancing Queen');
      expect(service.search('.m4a').single.title, 'notitie');
    });

    test('lege zoekopdracht geeft alles terug', () {
      expect(service.search('  '), hasLength(3));
    });
  });

  group('renameTrack (alleen weergavenaam)', () {
    setUp(() => service.scan());

    test('wijzigt titel en artiest zonder het pad te veranderen', () async {
      final newPath = await service.renameTrack('/fake/notitie.m4a',
          title: '  Nieuwe titel ', artist: ' Artiest ');
      expect(newPath, '/fake/notitie.m4a');
      final t = service.trackByPath(newPath)!;
      expect(t.title, 'Nieuwe titel');
      expect(t.artist, 'Artiest');
    });

    test('lege titel wordt geweigerd', () {
      expect(
        () => service.renameTrack('/fake/notitie.m4a', title: '   '),
        throwsA(isA<LocalRenameException>()),
      );
    });

    test('onbekend pad wordt geweigerd', () {
      expect(
        () => service.renameTrack('/bestaat/niet.mp3', title: 'x'),
        throwsA(isA<LocalRenameException>()),
      );
    });
  });

  group('renameTrack (bestand op apparaat)', () {
    late Directory dir;
    late LocalLibraryService fs;

    setUp(() async {
      dir = Directory.systemTemp.createTempSync('rename_test_');
      File('${dir.path}/oud.mp3').writeAsStringSync('audio');
      File('${dir.path}/Bezet.mp3').writeAsStringSync('audio');
      fs = LocalLibraryService(
        requestPermission: () async => true,
        roots: () async => [dir.path],
        scanner: (roots) async => scanDirectoriesSync(roots, minBytes: 0),
      );
      await fs.init();
      await fs.scan();
    });

    tearDown(() {
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    });

    String p(String name) =>
        fs.tracks.firstWhere((t) => t.fileName == name).path;

    test('hernoemt het bestand en behoudt de extensie', () async {
      final oldPath = p('oud.mp3');
      final newPath = await fs.renameTrack(oldPath,
          title: 'Nieuw', artist: 'Band', renameFile: true);
      expect(newPath.endsWith('Band - Nieuw.mp3'), true);
      expect(File(newPath).existsSync(), true);
      expect(File(oldPath).existsSync(), false);
      expect(fs.trackByPath(oldPath), isNull);
      expect(fs.trackByPath(newPath)!.title, 'Nieuw');
    });

    test('werkt playlists bij naar het nieuwe pad', () async {
      final oldPath = p('oud.mp3');
      final pl = await fs.createPlaylist('L');
      await fs.addToPlaylist(pl.id, oldPath);
      final newPath =
          await fs.renameTrack(oldPath, title: 'Ander', renameFile: true);
      expect(fs.playlistById(pl.id)!.paths, [newPath]);
      expect(fs.tracksForPlaylist(pl.id).single.title, 'Ander');
    });

    test('weigert als er al een bestand met die naam bestaat', () async {
      final oldPath = p('oud.mp3');
      await expectLater(
        fs.renameTrack(oldPath, title: 'Bezet', renameFile: true),
        throwsA(isA<LocalRenameException>()
            .having((e) => e.message, 'message', 'exists')),
      );
      expect(File(oldPath).existsSync(), true);
    });

    test('verwijdert ongeldige tekens uit de bestandsnaam', () async {
      final newPath = await fs.renameTrack(p('oud.mp3'),
          title: 'Wat? Nu: "ja"', renameFile: true);
      expect(newPath.split(RegExp(r'[/\\]')).last, 'Wat Nu ja.mp3');
    });
  });

  group('sanitizeFileName', () {
    test('verwijdert verboden tekens en punten/spaties aan het eind', () {
      expect(LocalLibraryService.sanitizeFileName('a/b\\c:d*e?f"g<h>i|j. '),
          'abcdefghij');
      expect(LocalLibraryService.sanitizeFileName('  veel   ruimte  '),
          'veel ruimte');
    });
  });

  group('lokale playlists', () {
    setUp(() => service.scan());

    test('aanmaken met naam, lege naam wordt geweigerd', () async {
      final p = await service.createPlaylist('  Roadtrip ');
      expect(p.name, 'Roadtrip');
      expect(p.isShareable, false);
      expect(() => service.createPlaylist('  '), throwsArgumentError);
    });

    test('elke playlist krijgt een uniek id', () async {
      final a = await service.createPlaylist('A');
      final b = await service.createPlaylist('B');
      expect(a.id, isNot(b.id));
    });

    test('nummer toevoegen, geen dubbelen', () async {
      final p = await service.createPlaylist('A');
      expect(await service.addToPlaylist(p.id, '/fake/notitie.m4a'), true);
      expect(await service.addToPlaylist(p.id, '/fake/notitie.m4a'), false);
      expect(service.tracksForPlaylist(p.id), hasLength(1));
    });

    test('volgorde van toevoegen blijft behouden', () async {
      final p = await service.createPlaylist('A');
      await service.addToPlaylist(p.id, '/fake/notitie.m4a');
      await service.addToPlaylist(p.id, '/fake/Queen - Bohemian Rhapsody.mp3');
      expect(service.tracksForPlaylist(p.id).map((t) => t.title).toList(),
          ['notitie', 'Bohemian Rhapsody']);
    });

    test('nummer verwijderen uit playlist laat het bestand in de bibliotheek',
        () async {
      final p = await service.createPlaylist('A');
      await service.addToPlaylist(p.id, '/fake/notitie.m4a');
      await service.removeFromPlaylist(p.id, '/fake/notitie.m4a');
      expect(service.tracksForPlaylist(p.id), isEmpty);
      expect(service.trackByPath('/fake/notitie.m4a'), isNotNull);
    });

    test('hernoemen en verwijderen', () async {
      final p = await service.createPlaylist('A');
      await service.renamePlaylist(p.id, 'B');
      expect(service.playlistById(p.id)!.name, 'B');
      await service.renamePlaylist(p.id, '  ');
      expect(service.playlistById(p.id)!.name, 'B');
      await service.deletePlaylist(p.id);
      expect(service.playlists, isEmpty);
      expect(service.tracks, hasLength(3));
    });

    test('verdwenen bestanden worden overgeslagen in de playlist', () async {
      final p = await service.createPlaylist('A');
      await service.addToPlaylist(p.id, '/fake/notitie.m4a');
      fakeFiles = [fakeFiles.first];
      await service.scan();
      expect(service.tracksForPlaylist(p.id), isEmpty);
    });

    test('onbekende playlist geeft lege lijst', () {
      expect(service.tracksForPlaylist('bestaat-niet'), isEmpty);
    });
  });
}
