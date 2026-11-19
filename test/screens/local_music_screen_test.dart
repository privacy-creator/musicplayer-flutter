import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_player_flutter/l10n/app_localizations.dart';
import 'package:music_player_flutter/l10n/app_localizations_en.dart';
import 'package:music_player_flutter/screens/local_music_screen.dart';
import 'package:music_player_flutter/screens/local_playlist_detail_screen.dart';
import 'package:music_player_flutter/screens/local_folders_screen.dart';
import 'package:music_player_flutter/services/api_service.dart';
import 'package:music_player_flutter/services/audio_handler.dart';
import 'package:music_player_flutter/services/auth_service.dart';
import 'package:music_player_flutter/services/local_audio_scanner.dart';
import 'package:music_player_flutter/services/local_library_service.dart';
import 'package:music_player_flutter/services/player_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAudioPlayer extends Mock implements AudioPlayer {}

class MockApiService extends Mock implements ApiService {}

void main() {
  final l10n = AppL10nEn();
  late MockAudioPlayer mockPlayer;
  late PlayerService player;
  late LocalLibraryService library;
  late bool permission;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    permission = true;
    mockPlayer = MockAudioPlayer();
    when(() => mockPlayer.playerStateStream)
        .thenAnswer((_) => const Stream.empty());
    when(() => mockPlayer.positionStream)
        .thenAnswer((_) => const Stream.empty());
    when(() => mockPlayer.durationStream)
        .thenAnswer((_) => const Stream.empty());
    when(() => mockPlayer.playing).thenReturn(false);
    when(() => mockPlayer.position).thenReturn(Duration.zero);
    when(() => mockPlayer.duration).thenReturn(null);
    when(() => mockPlayer.bufferedPosition).thenReturn(Duration.zero);
    when(() => mockPlayer.playerState)
        .thenReturn(PlayerState(false, ProcessingState.idle));
    when(() => mockPlayer.setFilePath(any())).thenAnswer((_) async => null);
    when(() => mockPlayer.setVolume(any())).thenAnswer((_) async {});
    when(() => mockPlayer.play()).thenAnswer((_) async {});
    when(() => mockPlayer.dispose()).thenAnswer((_) async {});
    player = PlayerService(handler: MusicAudioHandler(player: mockPlayer));

    library = LocalLibraryService(
      requestPermission: () async => permission,
      roots: () async => ['/fake'],
      scanner: (_) async => const [
        ScannedFile('/fake/Band - Lied.mp3', 2 * 1024 * 1024),
        ScannedFile('/fake/opname.m4a', 50 * 1024),
      ],
    );
    await library.init();
  });

  tearDown(() => player.dispose());

  Widget wrap(Widget child) => MultiProvider(
        providers: [
          ChangeNotifierProvider<PlayerService>.value(value: player),
          ChangeNotifierProvider<LocalLibraryService>.value(value: library),
          ChangeNotifierProvider<AuthService>(
              create: (_) => AuthService(MockApiService())),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          home: child,
        ),
      );

  testWidgets('toont lege staat met scanknop', (tester) async {
    await tester.pumpWidget(wrap(const LocalMusicScreen()));
    expect(find.text(l10n.localEmptyTitle), findsOneWidget);
    expect(find.byKey(const Key('localEmptyScanButton')), findsOneWidget);
  });

  testWidgets('scannen vult de lijst met lokale nummers', (tester) async {
    await tester.pumpWidget(wrap(const LocalMusicScreen()));
    await tester.tap(find.byKey(const Key('localEmptyScanButton')));
    await tester.pumpAndSettle();

    expect(find.text('Lied'), findsOneWidget);
    expect(find.text('Band · 2.0 MB'), findsOneWidget);
    expect(find.text('opname'), findsOneWidget);
    expect(find.text('${l10n.localUnknownArtist} · 50.0 KB'), findsOneWidget);
    expect(find.text(l10n.localScanDone(2)), findsOneWidget);
  });

  testWidgets('zonder toestemming verschijnt een melding', (tester) async {
    permission = false;
    await tester.pumpWidget(wrap(const LocalMusicScreen()));
    await tester.tap(find.byKey(const Key('localEmptyScanButton')));
    await tester.pumpAndSettle();
    expect(find.text(l10n.localPermissionDenied), findsOneWidget);
    expect(find.text(l10n.localEmptyTitle), findsOneWidget);
  });

  testWidgets('zoeken filtert de lijst', (tester) async {
    await library.scan();
    await tester.pumpWidget(wrap(const LocalMusicScreen()));
    await tester.enterText(find.byKey(const Key('localSearchField')), 'band');
    await tester.pump();
    expect(find.text('Lied'), findsOneWidget);
    expect(find.text('opname'), findsNothing);
  });

  testWidgets('tik op een nummer speelt het lokale bestand af',
      (tester) async {
    await library.scan();
    await tester.pumpWidget(wrap(const LocalMusicScreen()));
    await tester.tap(find.text('Lied'));
    await tester.pump();
    verify(() => mockPlayer.setFilePath('/fake/Band - Lied.mp3')).called(1);
    expect(player.currentSong?.isLocal, true);
  });

  testWidgets('naam van een lokaal nummer wijzigen', (tester) async {
    await library.scan();
    await tester.pumpWidget(wrap(const LocalMusicScreen()));

    await tester.tap(find.byKey(const ValueKey('localMenu_/fake/opname.m4a')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('localMenuItem_rename')));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const Key('localRenameTitle')), 'Mijn liedje');
    await tester.enterText(find.byKey(const Key('localRenameArtist')), 'Ik');
    await tester.tap(find.byKey(const Key('localRenameSave')));
    await tester.pumpAndSettle();

    expect(find.text('Mijn liedje'), findsOneWidget);
    expect(find.text(l10n.localRenameDone), findsOneWidget);
    expect(library.trackByPath('/fake/opname.m4a')!.artist, 'Ik');
  });

  testWidgets('lokale playlist aanmaken toont dat hij niet deelbaar is',
      (tester) async {
    await tester.pumpWidget(wrap(const LocalMusicScreen()));
    await tester.tap(find.text(l10n.localPlaylistsTab));
    await tester.pumpAndSettle();

    expect(find.text(l10n.localNoPlaylists), findsOneWidget);
    expect(find.text(l10n.localNotShareable), findsOneWidget);

    await tester.tap(find.byKey(const Key('localCreatePlaylist')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('localPlaylistNameField')), 'Roadtrip');
    await tester.tap(find.byKey(const Key('localPlaylistNameConfirm')));
    await tester.pumpAndSettle();

    expect(find.text('Roadtrip'), findsOneWidget);
    expect(library.playlists.single.name, 'Roadtrip');
  });

  testWidgets('nummer aan lokale playlist toevoegen via het menu',
      (tester) async {
    await library.scan();
    final p = await library.createPlaylist('Favoriet');
    await tester.pumpWidget(wrap(const LocalMusicScreen()));

    await tester
        .tap(find.byKey(const ValueKey('localMenu_/fake/Band - Lied.mp3')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('localMenuItem_playlist')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Favoriet (0)'));
    await tester.pumpAndSettle();

    expect(library.tracksForPlaylist(p.id).single.title, 'Lied');
    expect(find.text(l10n.localAddedToPlaylist('Favoriet')), findsOneWidget);
  });

  testWidgets('menu rechtsboven is het algemene app-menu met lokale acties',
      (tester) async {
    await library.scan();
    await tester.pumpWidget(wrap(const LocalMusicScreen()));
    await tester.tap(find.descendant(
        of: find.byType(AppBar), matching: find.byIcon(Icons.more_vert)));
    await tester.pumpAndSettle();
    expect(find.text(l10n.navSettings), findsOneWidget);
    expect(find.text(l10n.localScan), findsOneWidget);
    expect(find.text(l10n.tooltipShuffleAll), findsOneWidget);
    expect(find.text(l10n.localFolders), findsOneWidget);
  });

  testWidgets('nummer-menu is een bottom sheet met alle opties',
      (tester) async {
    await library.scan();
    await tester.pumpWidget(wrap(const LocalMusicScreen()));
    await tester.tap(find.byKey(const ValueKey('localMenu_/fake/opname.m4a')));
    await tester.pumpAndSettle();
    for (final v in ['queue', 'playlist', 'rename', 'exclude', 'delete']) {
      expect(find.byKey(ValueKey('localMenuItem_$v')), findsOneWidget);
    }
    // "Uit afspeellijst verwijderen" alleen binnen een playlist
    expect(find.byKey(const ValueKey('localMenuItem_remove')), findsNothing);
  });

  testWidgets('nummer uit de bibliotheek verwijderen', (tester) async {
    await library.scan();
    await tester.pumpWidget(wrap(const LocalMusicScreen()));
    await tester.tap(find.byKey(const ValueKey('localMenu_/fake/opname.m4a')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('localMenuItem_delete')));
    await tester.pumpAndSettle();
    expect(find.text(l10n.localDeleteTitle('opname')), findsOneWidget);
    await tester.tap(find.byKey(const Key('localDeleteLibrary')));
    await tester.pumpAndSettle();

    expect(find.text('opname'), findsNothing);
    expect(library.hiddenPaths, ['/fake/opname.m4a']);
    expect(find.text(l10n.localRemovedFromLibrary), findsOneWidget);
  });

  testWidgets('map uitsluiten via het nummer-menu', (tester) async {
    await library.scan();
    await tester.pumpWidget(wrap(const LocalMusicScreen()));
    await tester.tap(find.byKey(const ValueKey('localMenu_/fake/opname.m4a')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('localMenuItem_exclude')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('localExcludeConfirm')));
    await tester.pumpAndSettle();

    expect(library.excludedFolders, ['/fake']);
    expect(library.tracks, isEmpty);
    expect(find.text(l10n.localFolderExcluded(2)), findsOneWidget);
  });

  group('LocalFoldersScreen', () {
    testWidgets('toont mappen en kan een map uitsluiten en weer meenemen',
        (tester) async {
      await library.scan();
      await tester.pumpWidget(wrap(const LocalFoldersScreen()));
      expect(find.text('fake'), findsOneWidget);
      expect(find.textContaining(l10n.songCount(2)), findsOneWidget);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('localExcludeConfirm')));
      await tester.pumpAndSettle();
      expect(library.excludedFolders, ['/fake']);
      expect(find.textContaining(l10n.localExcludedLabel), findsOneWidget);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(library.excludedFolders, isEmpty);
      expect(library.tracks, hasLength(2)); // opnieuw gescand
    });

    testWidgets('lege staat zonder mappen', (tester) async {
      await tester.pumpWidget(wrap(const LocalFoldersScreen()));
      expect(find.text(l10n.localFoldersEmpty), findsOneWidget);
    });
  });

  group('LocalHiddenSongsScreen', () {
    testWidgets('verborgen nummer terugzetten', (tester) async {
      await library.scan();
      await library.removeFromLibrary('/fake/opname.m4a');
      await tester.pumpWidget(wrap(const LocalHiddenSongsScreen()));
      expect(find.text('opname'), findsOneWidget);

      await tester
          .tap(find.byKey(const ValueKey('localRestore_/fake/opname.m4a')));
      await tester.pumpAndSettle();
      expect(library.hiddenPaths, isEmpty);
      expect(find.text(l10n.localHiddenEmpty), findsOneWidget);
    });
  });

  group('LocalPlaylistDetailScreen', () {
    testWidgets('toont nummers, geen deelknop en kan nummer verwijderen',
        (tester) async {
      await library.scan();
      final p = await library.createPlaylist('Mix');
      await library.addToPlaylist(p.id, '/fake/Band - Lied.mp3');
      await tester.pumpWidget(wrap(LocalPlaylistDetailScreen(playlistId: p.id)));

      expect(find.text('Mix'), findsOneWidget);
      expect(find.text('Lied'), findsOneWidget);
      expect(find.byIcon(Icons.share), findsNothing);
      expect(find.byIcon(Icons.share_outlined), findsNothing);

      await tester
          .tap(find.byKey(const ValueKey('localMenu_/fake/Band - Lied.mp3')));
      await tester.pumpAndSettle();
      await tester
          .tap(find.byKey(const ValueKey('localMenuItem_remove')));
      await tester.pumpAndSettle();

      expect(find.text(l10n.localPlaylistEmpty), findsOneWidget);
      expect(library.trackByPath('/fake/Band - Lied.mp3'), isNotNull);
    });

    testWidgets('afspelen start bij het eerste nummer', (tester) async {
      await library.scan();
      final p = await library.createPlaylist('Mix');
      await library.addToPlaylist(p.id, '/fake/opname.m4a');
      await tester.pumpWidget(wrap(LocalPlaylistDetailScreen(playlistId: p.id)));
      await tester.tap(find.byKey(const Key('localPlaylistPlay')));
      await tester.pump();
      verify(() => mockPlayer.setFilePath('/fake/opname.m4a')).called(1);
    });

    testWidgets('playlist verwijderen na bevestiging', (tester) async {
      final p = await library.createPlaylist('Weg');
      await tester.pumpWidget(wrap(Builder(
        builder: (ctx) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.push(
              ctx,
              MaterialPageRoute(
                  builder: (_) => LocalPlaylistDetailScreen(playlistId: p.id)),
            ),
            child: const Text('open'),
          ),
        ),
      )));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('localPlaylistMenu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.localDeletePlaylist));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('localDeletePlaylistConfirm')));
      await tester.pumpAndSettle();

      expect(library.playlists, isEmpty);
      expect(find.text('open'), findsOneWidget);
    });
  });
}
