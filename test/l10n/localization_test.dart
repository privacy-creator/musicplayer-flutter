import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_player_flutter/l10n/app_localizations.dart';

Widget _wrap(Widget child, Locale locale) => MaterialApp(
      locale: locale,
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      home: Scaffold(body: child),
    );

Future<AppL10n> _l10n(WidgetTester tester, Locale locale) async {
  late AppL10n result;
  await tester.pumpWidget(_wrap(
    Builder(builder: (ctx) {
      result = AppL10n.of(ctx)!;
      return const SizedBox();
    }),
    locale,
  ));
  return result;
}

void main() {
  group('Nederlands (nl)', () {
    testWidgets('navSongs is Nummers', (tester) async {
      final l = await _l10n(tester, const Locale('nl'));
      expect(l.navSongs, 'Nummers');
    });

    testWidgets('navPlaylists is Afspeellijsten', (tester) async {
      final l = await _l10n(tester, const Locale('nl'));
      expect(l.navPlaylists, 'Afspeellijsten');
    });

    testWidgets('nowPlaying is Nu aan het afspelen', (tester) async {
      final l = await _l10n(tester, const Locale('nl'));
      expect(l.nowPlaying, 'Nu aan het afspelen');
    });

    testWidgets('clearQueue is Wis wachtrij', (tester) async {
      final l = await _l10n(tester, const Locale('nl'));
      expect(l.clearQueue, 'Wis wachtrij');
    });

    testWidgets('emptyQueue is correct', (tester) async {
      final l = await _l10n(tester, const Locale('nl'));
      expect(l.emptyQueue, 'Geen nummers in de wachtrij');
    });

    testWidgets('errorCannotLoad is correct', (tester) async {
      final l = await _l10n(tester, const Locale('nl'));
      expect(l.errorCannotLoad, 'Nummer kan niet worden geladen');
    });

    testWidgets('songCount enkelvoud', (tester) async {
      final l = await _l10n(tester, const Locale('nl'));
      expect(l.songCount(1), '1 nummer');
    });

    testWidgets('songCount meervoud', (tester) async {
      final l = await _l10n(tester, const Locale('nl'));
      expect(l.songCount(5), '5 nummers');
    });

    testWidgets('sectionQueue met count', (tester) async {
      final l = await _l10n(tester, const Locale('nl'));
      expect(l.sectionQueue(3), 'Wachtrij (3)');
    });

    testWidgets('addedToQueue met titel', (tester) async {
      final l = await _l10n(tester, const Locale('nl'));
      expect(l.addedToQueue('Test Song'), 'Test Song toegevoegd aan wachtrij');
    });
  });

  group('English (en)', () {
    testWidgets('navSongs is Songs', (tester) async {
      final l = await _l10n(tester, const Locale('en'));
      expect(l.navSongs, 'Songs');
    });

    testWidgets('navPlaylists is Playlists', (tester) async {
      final l = await _l10n(tester, const Locale('en'));
      expect(l.navPlaylists, 'Playlists');
    });

    testWidgets('nowPlaying is Now playing', (tester) async {
      final l = await _l10n(tester, const Locale('en'));
      expect(l.nowPlaying, 'Now playing');
    });

    testWidgets('clearQueue is Clear queue', (tester) async {
      final l = await _l10n(tester, const Locale('en'));
      expect(l.clearQueue, 'Clear queue');
    });

    testWidgets('emptyQueue is correct', (tester) async {
      final l = await _l10n(tester, const Locale('en'));
      expect(l.emptyQueue, 'No songs in the queue');
    });

    testWidgets('errorCannotLoad is correct', (tester) async {
      final l = await _l10n(tester, const Locale('en'));
      expect(l.errorCannotLoad, 'Song could not be loaded');
    });

    testWidgets('songCount singular', (tester) async {
      final l = await _l10n(tester, const Locale('en'));
      expect(l.songCount(1), '1 song');
    });

    testWidgets('songCount plural', (tester) async {
      final l = await _l10n(tester, const Locale('en'));
      expect(l.songCount(3), '3 songs');
    });

    testWidgets('sectionQueue with count', (tester) async {
      final l = await _l10n(tester, const Locale('en'));
      expect(l.sectionQueue(2), 'Queue (2)');
    });

    testWidgets('addedToQueue with title', (tester) async {
      final l = await _l10n(tester, const Locale('en'));
      expect(l.addedToQueue('My Song'), 'My Song added to queue');
    });
  });

  group('Español (es)', () {
    testWidgets('navSongs is Canciones', (tester) async {
      final l = await _l10n(tester, const Locale('es'));
      expect(l.navSongs, 'Canciones');
    });

    testWidgets('navPlaylists is Listas', (tester) async {
      final l = await _l10n(tester, const Locale('es'));
      expect(l.navPlaylists, 'Listas');
    });

    testWidgets('nowPlaying is Reproduciendo ahora', (tester) async {
      final l = await _l10n(tester, const Locale('es'));
      expect(l.nowPlaying, 'Reproduciendo ahora');
    });

    testWidgets('clearQueue is Vaciar cola', (tester) async {
      final l = await _l10n(tester, const Locale('es'));
      expect(l.clearQueue, 'Vaciar cola');
    });

    testWidgets('emptyQueue is correct', (tester) async {
      final l = await _l10n(tester, const Locale('es'));
      expect(l.emptyQueue, 'No hay canciones en la cola');
    });

    testWidgets('errorCannotLoad is correct', (tester) async {
      final l = await _l10n(tester, const Locale('es'));
      expect(l.errorCannotLoad, 'No se pudo cargar la canción');
    });

    testWidgets('songCount singular', (tester) async {
      final l = await _l10n(tester, const Locale('es'));
      expect(l.songCount(1), '1 canción');
    });

    testWidgets('songCount plural', (tester) async {
      final l = await _l10n(tester, const Locale('es'));
      expect(l.songCount(4), '4 canciones');
    });

    testWidgets('sectionQueue con cuenta', (tester) async {
      final l = await _l10n(tester, const Locale('es'));
      expect(l.sectionQueue(1), 'Cola (1)');
    });

    testWidgets('addedToQueue con título', (tester) async {
      final l = await _l10n(tester, const Locale('es'));
      expect(l.addedToQueue('Mi Canción'), 'Mi Canción añadida a la cola');
    });
  });

  group('Consistentie: alle strings aanwezig in alle talen', () {
    testWidgets('btnAddToQueue aanwezig in alle talen', (tester) async {
      for (final locale in [const Locale('nl'), const Locale('en'), const Locale('es')]) {
        final l = await _l10n(tester, locale);
        expect(l.btnAddToQueue, isNotEmpty,
            reason: '${locale.languageCode}: btnAddToQueue leeg');
      }
    });

    testWidgets('tooltipDownload aanwezig in alle talen', (tester) async {
      for (final locale in [const Locale('nl'), const Locale('en'), const Locale('es')]) {
        final l = await _l10n(tester, locale);
        expect(l.tooltipDownload, isNotEmpty);
      }
    });

    testWidgets('noSongsFound aanwezig in alle talen', (tester) async {
      for (final locale in [const Locale('nl'), const Locale('en'), const Locale('es')]) {
        final l = await _l10n(tester, locale);
        expect(l.noSongsFound, isNotEmpty);
      }
    });

    testWidgets('talen zijn uniek per string', (tester) async {
      final nl = await _l10n(tester, const Locale('nl'));
      final en = await _l10n(tester, const Locale('en'));
      final es = await _l10n(tester, const Locale('es'));

      // navSongs differs per language
      expect({nl.navSongs, en.navSongs, es.navSongs}.length, 3);
      // nowPlaying differs per language
      expect({nl.nowPlaying, en.nowPlaying, es.nowPlaying}.length, 3);
      // clearQueue differs per language
      expect({nl.clearQueue, en.clearQueue, es.clearQueue}.length, 3);
    });
  });
}
