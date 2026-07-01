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

  group('NL — alle getters gedekt', () {
    testWidgets('alle NL strings bereikbaar', (tester) async {
      final l = await _l10n(tester, const Locale('nl'));
      expect(l.appTitle, isNotEmpty);
      expect(l.tooltipRefresh, isNotEmpty);
      expect(l.tooltipShuffleAll, isNotEmpty);
      expect(l.searchHint, isNotEmpty);
      expect(l.filterLanguage, isNotEmpty);
      expect(l.filterGenre, isNotEmpty);
      expect(l.allLanguage, isNotEmpty);
      expect(l.allGenre, isNotEmpty);
      expect(l.offlineBanner, isNotEmpty);
      expect(l.noInternet, isNotEmpty);
      expect(l.tooltipDeleteDownload, isNotEmpty);
      expect(l.offlineBadge, isNotEmpty);
      expect(l.songAdded('T'), contains('T'));
      expect(l.queue, isNotEmpty);
      expect(l.lyrics, isNotEmpty);
      expect(l.btnPlay, isNotEmpty);
      expect(l.btnPause, isNotEmpty);
      expect(l.tooltipQueue, isNotEmpty);
      expect(l.sectionNowPlaying, isNotEmpty);
      expect(l.sectionUpNext, isNotEmpty);
      expect(l.adminLogin, isNotEmpty);
      expect(l.adminSubtitle, isNotEmpty);
      expect(l.tooltipAdminLogout, isNotEmpty);
      expect(l.tooltipAdminLogin, isNotEmpty);
      expect(l.hintEmail, isNotEmpty);
      expect(l.hintPassword, isNotEmpty);
      expect(l.btnSignIn, isNotEmpty);
      expect(l.errorFillAll, isNotEmpty);
      expect(l.mfaTotp, isNotEmpty);
      expect(l.mfaEmail, isNotEmpty);
      expect(l.hint6digit, isNotEmpty);
      expect(l.btnVerify, isNotEmpty);
      expect(l.backToLogin, isNotEmpty);
      expect(l.noPlaylists, isNotEmpty);
      expect(l.tooltipPlayAll, isNotEmpty);
      expect(l.tooltipShuffle, isNotEmpty);
      expect(l.noSongsInPlaylist, isNotEmpty);
      expect(l.languagePicker, isNotEmpty);
      expect(l.langNl, isNotEmpty);
      expect(l.langEn, isNotEmpty);
      expect(l.langEs, isNotEmpty);
      expect(l.navSettings, isNotEmpty);
      expect(l.settingsTitle, isNotEmpty);
      expect(l.appearanceSection, isNotEmpty);
      expect(l.languageSection, isNotEmpty);
      expect(l.storageSection, isNotEmpty);
      expect(l.themeMode, isNotEmpty);
      expect(l.themeDark, isNotEmpty);
      expect(l.themeLight, isNotEmpty);
      expect(l.themeSystem, isNotEmpty);
      expect(l.translateLyrics, isNotEmpty);
      expect(l.translating, isNotEmpty);
      expect(l.translateTo, isNotEmpty);
      expect(l.translateError, isNotEmpty);
      expect(l.originalLyrics, isNotEmpty);
      expect(l.translatedLyrics, isNotEmpty);
      expect(l.clearCache, isNotEmpty);
      expect(l.cacheCleared, isNotEmpty);
      expect(l.showOriginal, isNotEmpty);
      expect(l.translationDisclaimer, isNotEmpty);
      expect(l.tooltipShare, isNotEmpty);
      expect(l.shareLinkCopied, isNotEmpty);
    });
  });

  group('EN — alle getters gedekt', () {
    testWidgets('alle EN strings bereikbaar', (tester) async {
      final l = await _l10n(tester, const Locale('en'));
      expect(l.appTitle, isNotEmpty);
      expect(l.tooltipRefresh, isNotEmpty);
      expect(l.tooltipShuffleAll, isNotEmpty);
      expect(l.searchHint, isNotEmpty);
      expect(l.filterLanguage, isNotEmpty);
      expect(l.filterGenre, isNotEmpty);
      expect(l.allLanguage, isNotEmpty);
      expect(l.allGenre, isNotEmpty);
      expect(l.offlineBanner, isNotEmpty);
      expect(l.noInternet, isNotEmpty);
      expect(l.tooltipDeleteDownload, isNotEmpty);
      expect(l.offlineBadge, isNotEmpty);
      expect(l.songAdded('T'), contains('T'));
      expect(l.queue, isNotEmpty);
      expect(l.lyrics, isNotEmpty);
      expect(l.btnPlay, isNotEmpty);
      expect(l.btnPause, isNotEmpty);
      expect(l.tooltipQueue, isNotEmpty);
      expect(l.sectionNowPlaying, isNotEmpty);
      expect(l.sectionUpNext, isNotEmpty);
      expect(l.adminLogin, isNotEmpty);
      expect(l.adminSubtitle, isNotEmpty);
      expect(l.tooltipAdminLogout, isNotEmpty);
      expect(l.tooltipAdminLogin, isNotEmpty);
      expect(l.hintEmail, isNotEmpty);
      expect(l.hintPassword, isNotEmpty);
      expect(l.btnSignIn, isNotEmpty);
      expect(l.errorFillAll, isNotEmpty);
      expect(l.mfaTotp, isNotEmpty);
      expect(l.mfaEmail, isNotEmpty);
      expect(l.hint6digit, isNotEmpty);
      expect(l.btnVerify, isNotEmpty);
      expect(l.backToLogin, isNotEmpty);
      expect(l.noPlaylists, isNotEmpty);
      expect(l.tooltipPlayAll, isNotEmpty);
      expect(l.tooltipShuffle, isNotEmpty);
      expect(l.noSongsInPlaylist, isNotEmpty);
      expect(l.languagePicker, isNotEmpty);
      expect(l.langNl, isNotEmpty);
      expect(l.langEn, isNotEmpty);
      expect(l.langEs, isNotEmpty);
      expect(l.navSettings, isNotEmpty);
      expect(l.settingsTitle, isNotEmpty);
      expect(l.appearanceSection, isNotEmpty);
      expect(l.languageSection, isNotEmpty);
      expect(l.storageSection, isNotEmpty);
      expect(l.themeMode, isNotEmpty);
      expect(l.themeDark, isNotEmpty);
      expect(l.themeLight, isNotEmpty);
      expect(l.themeSystem, isNotEmpty);
      expect(l.translateLyrics, isNotEmpty);
      expect(l.translating, isNotEmpty);
      expect(l.translateTo, isNotEmpty);
      expect(l.translateError, isNotEmpty);
      expect(l.originalLyrics, isNotEmpty);
      expect(l.translatedLyrics, isNotEmpty);
      expect(l.clearCache, isNotEmpty);
      expect(l.cacheCleared, isNotEmpty);
      expect(l.showOriginal, isNotEmpty);
      expect(l.translationDisclaimer, isNotEmpty);
      expect(l.tooltipShare, isNotEmpty);
      expect(l.shareLinkCopied, isNotEmpty);
    });
  });

  group('ES — alle getters gedekt', () {
    testWidgets('alle ES strings bereikbaar', (tester) async {
      final l = await _l10n(tester, const Locale('es'));
      expect(l.appTitle, isNotEmpty);
      expect(l.tooltipRefresh, isNotEmpty);
      expect(l.tooltipShuffleAll, isNotEmpty);
      expect(l.searchHint, isNotEmpty);
      expect(l.filterLanguage, isNotEmpty);
      expect(l.filterGenre, isNotEmpty);
      expect(l.allLanguage, isNotEmpty);
      expect(l.allGenre, isNotEmpty);
      expect(l.offlineBanner, isNotEmpty);
      expect(l.noInternet, isNotEmpty);
      expect(l.tooltipDeleteDownload, isNotEmpty);
      expect(l.offlineBadge, isNotEmpty);
      expect(l.songAdded('T'), contains('T'));
      expect(l.queue, isNotEmpty);
      expect(l.lyrics, isNotEmpty);
      expect(l.btnPlay, isNotEmpty);
      expect(l.btnPause, isNotEmpty);
      expect(l.tooltipQueue, isNotEmpty);
      expect(l.sectionNowPlaying, isNotEmpty);
      expect(l.sectionUpNext, isNotEmpty);
      expect(l.adminLogin, isNotEmpty);
      expect(l.adminSubtitle, isNotEmpty);
      expect(l.tooltipAdminLogout, isNotEmpty);
      expect(l.tooltipAdminLogin, isNotEmpty);
      expect(l.hintEmail, isNotEmpty);
      expect(l.hintPassword, isNotEmpty);
      expect(l.btnSignIn, isNotEmpty);
      expect(l.errorFillAll, isNotEmpty);
      expect(l.mfaTotp, isNotEmpty);
      expect(l.mfaEmail, isNotEmpty);
      expect(l.hint6digit, isNotEmpty);
      expect(l.btnVerify, isNotEmpty);
      expect(l.backToLogin, isNotEmpty);
      expect(l.noPlaylists, isNotEmpty);
      expect(l.tooltipPlayAll, isNotEmpty);
      expect(l.tooltipShuffle, isNotEmpty);
      expect(l.noSongsInPlaylist, isNotEmpty);
      expect(l.languagePicker, isNotEmpty);
      expect(l.langNl, isNotEmpty);
      expect(l.langEn, isNotEmpty);
      expect(l.langEs, isNotEmpty);
      expect(l.navSettings, isNotEmpty);
      expect(l.settingsTitle, isNotEmpty);
      expect(l.appearanceSection, isNotEmpty);
      expect(l.languageSection, isNotEmpty);
      expect(l.storageSection, isNotEmpty);
      expect(l.themeMode, isNotEmpty);
      expect(l.themeDark, isNotEmpty);
      expect(l.themeLight, isNotEmpty);
      expect(l.themeSystem, isNotEmpty);
      expect(l.translateLyrics, isNotEmpty);
      expect(l.translating, isNotEmpty);
      expect(l.translateTo, isNotEmpty);
      expect(l.translateError, isNotEmpty);
      expect(l.originalLyrics, isNotEmpty);
      expect(l.translatedLyrics, isNotEmpty);
      expect(l.clearCache, isNotEmpty);
      expect(l.cacheCleared, isNotEmpty);
      expect(l.showOriginal, isNotEmpty);
      expect(l.translationDisclaimer, isNotEmpty);
      expect(l.tooltipShare, isNotEmpty);
      expect(l.shareLinkCopied, isNotEmpty);
    });
  });

  group('Deutsch (de)', () {
    testWidgets('navSongs is Titel', (tester) async {
      final l = await _l10n(tester, const Locale('de'));
      expect(l.navSongs, 'Titel');
    });

    testWidgets('navPlaylists is Wiedergabelisten', (tester) async {
      final l = await _l10n(tester, const Locale('de'));
      expect(l.navPlaylists, 'Wiedergabelisten');
    });

    testWidgets('nowPlaying is Läuft gerade', (tester) async {
      final l = await _l10n(tester, const Locale('de'));
      expect(l.nowPlaying, 'Läuft gerade');
    });

    testWidgets('clearQueue is Warteschlange leeren', (tester) async {
      final l = await _l10n(tester, const Locale('de'));
      expect(l.clearQueue, 'Warteschlange leeren');
    });

    testWidgets('songCount enkelvoud', (tester) async {
      final l = await _l10n(tester, const Locale('de'));
      expect(l.songCount(1), '1 Titel');
    });

    testWidgets('songCount meervoud', (tester) async {
      final l = await _l10n(tester, const Locale('de'));
      expect(l.songCount(3), '3 Titel');
    });

    testWidgets('langDe is Deutsch', (tester) async {
      final l = await _l10n(tester, const Locale('de'));
      expect(l.langDe, 'Deutsch');
    });

    testWidgets('langIt is Italienisch', (tester) async {
      final l = await _l10n(tester, const Locale('de'));
      expect(l.langIt, 'Italienisch');
    });

    testWidgets('alle DE strings bereikbaar', (tester) async {
      final l = await _l10n(tester, const Locale('de'));
      expect(l.appTitle, isNotEmpty);
      expect(l.tooltipRefresh, isNotEmpty);
      expect(l.searchHint, isNotEmpty);
      expect(l.noSongsFound, isNotEmpty);
      expect(l.queue, isNotEmpty);
      expect(l.lyrics, isNotEmpty);
      expect(l.downloadsHeader, isNotEmpty);
      expect(l.downloadAll, isNotEmpty);
      expect(l.deleteAllDownloads, isNotEmpty);
      expect(l.downloadingActive, isNotEmpty);
      expect(l.menuSongInfo, isNotEmpty);
    });
  });

  group('Italiano (it)', () {
    testWidgets('navSongs is Brani', (tester) async {
      final l = await _l10n(tester, const Locale('it'));
      expect(l.navSongs, 'Brani');
    });

    testWidgets('navPlaylists is Playlist', (tester) async {
      final l = await _l10n(tester, const Locale('it'));
      expect(l.navPlaylists, 'Playlist');
    });

    testWidgets('nowPlaying is In riproduzione', (tester) async {
      final l = await _l10n(tester, const Locale('it'));
      expect(l.nowPlaying, 'In riproduzione');
    });

    testWidgets('clearQueue is Svuota coda', (tester) async {
      final l = await _l10n(tester, const Locale('it'));
      expect(l.clearQueue, 'Svuota coda');
    });

    testWidgets('songCount enkelvoud', (tester) async {
      final l = await _l10n(tester, const Locale('it'));
      expect(l.songCount(1), '1 brano');
    });

    testWidgets('songCount meervoud', (tester) async {
      final l = await _l10n(tester, const Locale('it'));
      expect(l.songCount(4), '4 brani');
    });

    testWidgets('langDe is Tedesco', (tester) async {
      final l = await _l10n(tester, const Locale('it'));
      expect(l.langDe, 'Tedesco');
    });

    testWidgets('langIt is Italiano', (tester) async {
      final l = await _l10n(tester, const Locale('it'));
      expect(l.langIt, 'Italiano');
    });

    testWidgets('alle IT strings bereikbaar', (tester) async {
      final l = await _l10n(tester, const Locale('it'));
      expect(l.appTitle, isNotEmpty);
      expect(l.tooltipRefresh, isNotEmpty);
      expect(l.searchHint, isNotEmpty);
      expect(l.noSongsFound, isNotEmpty);
      expect(l.queue, isNotEmpty);
      expect(l.lyrics, isNotEmpty);
      expect(l.downloadsHeader, isNotEmpty);
      expect(l.downloadAll, isNotEmpty);
      expect(l.deleteAllDownloads, isNotEmpty);
      expect(l.downloadingActive, isNotEmpty);
      expect(l.menuSongInfo, isNotEmpty);
    });
  });

  group('Consistentie: alle strings aanwezig in alle talen', () {
    testWidgets('btnAddToQueue aanwezig in alle talen', (tester) async {
      for (final locale in AppL10n.supportedLocales) {
        final l = await _l10n(tester, locale);
        expect(l.btnAddToQueue, isNotEmpty,
            reason: '${locale.languageCode}: btnAddToQueue leeg');
      }
    });

    testWidgets('tooltipDownload aanwezig in alle talen', (tester) async {
      for (final locale in AppL10n.supportedLocales) {
        final l = await _l10n(tester, locale);
        expect(l.tooltipDownload, isNotEmpty);
      }
    });

    testWidgets('noSongsFound aanwezig in alle talen', (tester) async {
      for (final locale in AppL10n.supportedLocales) {
        final l = await _l10n(tester, locale);
        expect(l.noSongsFound, isNotEmpty);
      }
    });

    testWidgets('langDe en langIt aanwezig in alle talen', (tester) async {
      for (final locale in AppL10n.supportedLocales) {
        final l = await _l10n(tester, locale);
        expect(l.langDe, isNotEmpty,
            reason: '${locale.languageCode}: langDe leeg');
        expect(l.langIt, isNotEmpty,
            reason: '${locale.languageCode}: langIt leeg');
      }
    });

    testWidgets('talen zijn uniek per navSongs string', (tester) async {
      final strings = <String>{};
      for (final locale in AppL10n.supportedLocales) {
        final l = await _l10n(tester, locale);
        strings.add(l.navSongs);
      }
      // All 5 languages should have unique navSongs values
      expect(strings.length, AppL10n.supportedLocales.length);
    });
  });
}
