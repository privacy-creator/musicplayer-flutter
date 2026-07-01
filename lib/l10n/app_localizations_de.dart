// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppL10nDe extends AppL10n {
  AppL10nDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Music Player';

  @override
  String get navSongs => 'Titel';

  @override
  String get navPlaylists => 'Wiedergabelisten';

  @override
  String get tooltipRefresh => 'Aktualisieren';

  @override
  String get tooltipShuffleAll => 'Alle mischen';

  @override
  String get searchHint => 'Titel suchen...';

  @override
  String get filterLanguage => 'Sprache';

  @override
  String get filterGenre => 'Genre';

  @override
  String get allLanguage => 'Alle Sprachen';

  @override
  String get allGenre => 'Alle Genres';

  @override
  String get noSongsFound => 'Keine Titel gefunden';

  @override
  String get offlineBanner => 'Offline — gecachte Titel';

  @override
  String get noInternet => 'Keine Internetverbindung';

  @override
  String addedToQueue(String title) {
    return '$title zur Warteschlange hinzugefügt';
  }

  @override
  String get tooltipDownload => 'Offline speichern';

  @override
  String get tooltipDeleteDownload => 'Download löschen';

  @override
  String get offlineBadge => 'Offline verfügbar';

  @override
  String get btnAddToQueue => 'Zur Warteschlange hinzufügen';

  @override
  String songAdded(String title) {
    return '$title hinzugefügt';
  }

  @override
  String get queue => 'Warteschlange';

  @override
  String get lyrics => 'Liedtext';

  @override
  String get btnPlay => 'Abspielen';

  @override
  String get btnPause => 'Pause';

  @override
  String get nowPlaying => 'Läuft gerade';

  @override
  String get tooltipQueue => 'Warteschlange';

  @override
  String get clearQueue => 'Warteschlange leeren';

  @override
  String get emptyQueue => 'Keine Titel in der Warteschlange';

  @override
  String get sectionNowPlaying => 'Läuft gerade';

  @override
  String sectionQueue(int count) {
    return 'Warteschlange ($count)';
  }

  @override
  String get sectionUpNext => 'Als nächstes';

  @override
  String get adminLogin => 'Admin-Login';

  @override
  String get adminSubtitle => 'Nur für Administratoren';

  @override
  String get tooltipAdminLogout => 'Admin abmelden';

  @override
  String get tooltipAdminLogin => 'Admin-Login';

  @override
  String get hintEmail => 'E-Mail';

  @override
  String get hintPassword => 'Passwort';

  @override
  String get btnSignIn => 'Anmelden';

  @override
  String get errorFillAll => 'Bitte alle Felder ausfüllen';

  @override
  String get mfaTotp => 'Authenticator-Code eingeben';

  @override
  String get mfaEmail => 'Code aus der E-Mail eingeben';

  @override
  String get hint6digit => '6-stelliger Code';

  @override
  String get btnVerify => 'Bestätigen';

  @override
  String get backToLogin => '← Zurück zur Anmeldung';

  @override
  String get noPlaylists => 'Noch keine Wiedergabelisten';

  @override
  String songCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Titel',
      one: '1 Titel',
    );
    return '$_temp0';
  }

  @override
  String get tooltipPlayAll => 'Alle abspielen';

  @override
  String get tooltipShuffle => 'Mischen';

  @override
  String get noSongsInPlaylist => 'Keine Titel in dieser Wiedergabeliste';

  @override
  String get errorCannotLoad => 'Titel konnte nicht geladen werden';

  @override
  String get languagePicker => 'Sprache';

  @override
  String get langNl => 'Niederländisch';

  @override
  String get langEn => 'Englisch';

  @override
  String get langEs => 'Spanisch';

  @override
  String get langDe => 'Deutsch';

  @override
  String get langIt => 'Italienisch';

  @override
  String get navSettings => 'Einstellungen';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get appearanceSection => 'Darstellung';

  @override
  String get languageSection => 'Sprache';

  @override
  String get storageSection => 'Speicher';

  @override
  String get themeMode => 'Design';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeSystem => 'Systemstandard';

  @override
  String get translateLyrics => 'Übersetzen';

  @override
  String get translating => 'Übersetze...';

  @override
  String get translateTo => 'Übersetzen in';

  @override
  String get translateError => 'Übersetzung fehlgeschlagen';

  @override
  String get originalLyrics => 'Original';

  @override
  String get translatedLyrics => 'Übersetzung';

  @override
  String get clearCache => 'Cache leeren';

  @override
  String get cacheCleared => 'Cache geleert';

  @override
  String get showOriginal => 'Original anzeigen';

  @override
  String get translationDisclaimer =>
      'Die Übersetzung kann ungenau sein und Fehler enthalten';

  @override
  String get tooltipShare => 'Teilen';

  @override
  String get shareLinkCopied => 'Link kopiert!';

  @override
  String get downloadsHeader => 'Downloads';

  @override
  String get noDownloads => 'Keine heruntergeladenen Titel';

  @override
  String get downloadRemoved => 'Aus Downloads entfernt';

  @override
  String get navLive => 'Live';

  @override
  String get liveListening => 'Live zuhören';

  @override
  String get createRoom => 'Hörabend starten';

  @override
  String get joinRoom => 'Raum beitreten';

  @override
  String get roomCode => 'Raumcode';

  @override
  String get enterRoomCode => 'Einladungscode eingeben';

  @override
  String get participants => 'Teilnehmer';

  @override
  String get noParticipants => 'Noch keine Teilnehmer';

  @override
  String get host => 'Gastgeber';

  @override
  String get nowPlayingLabel => 'LÄUFT GERADE';

  @override
  String get noSongPlaying => 'Kein Titel ausgewählt';

  @override
  String get leaveRoom => 'Verlassen';

  @override
  String get endRoom => 'Abend beenden';

  @override
  String get endRoomConfirm => 'Damit wird der Abend für alle Zuhörer beendet.';

  @override
  String get syncNow => 'Jetzt synchronisieren';

  @override
  String get inviteCode => 'EINLADUNGSCODE';

  @override
  String get roomCodeCopied => 'Raumcode kopiert!';

  @override
  String get hostControls => 'GASTGEBER-STEUERUNG';

  @override
  String get transferHost => 'Zum Gastgeber machen';

  @override
  String get roomEnded => 'Der Hörabend ist beendet';

  @override
  String get controlledByHost => 'Wird vom Gastgeber gesteuert';

  @override
  String get menuSongInfo => 'Titelinfo';

  @override
  String get downloadAll => 'Alle herunterladen';

  @override
  String get deleteAllDownloads => 'Alle Downloads löschen';

  @override
  String get allDownloadsRemoved => 'Alle Downloads gelöscht';

  @override
  String get downloadingActive => 'Wird heruntergeladen';

  @override
  String get aboutSection => 'Über';

  @override
  String get githubReleases => 'GitHub Releases';

  @override
  String get updateAvailable => 'Update verfügbar';
}
