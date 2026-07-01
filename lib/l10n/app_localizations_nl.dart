// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppL10nNl extends AppL10n {
  AppL10nNl([String locale = 'nl']) : super(locale);

  @override
  String get appTitle => 'Music Player';

  @override
  String get navSongs => 'Nummers';

  @override
  String get navPlaylists => 'Afspeellijsten';

  @override
  String get tooltipRefresh => 'Vernieuwen';

  @override
  String get tooltipShuffleAll => 'Alles shuffelen';

  @override
  String get searchHint => 'Zoek nummers...';

  @override
  String get filterLanguage => 'Taal';

  @override
  String get filterGenre => 'Genre';

  @override
  String get allLanguage => 'Alle talen';

  @override
  String get allGenre => 'Alle genres';

  @override
  String get noSongsFound => 'Geen nummers gevonden';

  @override
  String get offlineBanner => 'Offline — gecachede nummers';

  @override
  String get noInternet => 'Geen internetverbinding';

  @override
  String addedToQueue(String title) {
    return '$title toegevoegd aan wachtrij';
  }

  @override
  String get tooltipDownload => 'Offline opslaan';

  @override
  String get tooltipDeleteDownload => 'Download verwijderen';

  @override
  String get offlineBadge => 'Offline beschikbaar';

  @override
  String get btnAddToQueue => 'Aan wachtrij toevoegen';

  @override
  String songAdded(String title) {
    return '$title toegevoegd';
  }

  @override
  String get queue => 'Wachtrij';

  @override
  String get lyrics => 'Tekst';

  @override
  String get btnPlay => 'Play';

  @override
  String get btnPause => 'Pause';

  @override
  String get nowPlaying => 'Nu aan het afspelen';

  @override
  String get tooltipQueue => 'Wachtrij';

  @override
  String get clearQueue => 'Wis wachtrij';

  @override
  String get emptyQueue => 'Geen nummers in de wachtrij';

  @override
  String get sectionNowPlaying => 'Nu aan het afspelen';

  @override
  String sectionQueue(int count) {
    return 'Wachtrij ($count)';
  }

  @override
  String get sectionUpNext => 'Hierna';

  @override
  String get adminLogin => 'Admin Login';

  @override
  String get adminSubtitle => 'Alleen voor beheerders';

  @override
  String get tooltipAdminLogout => 'Admin uitloggen';

  @override
  String get tooltipAdminLogin => 'Admin login';

  @override
  String get hintEmail => 'E-mail';

  @override
  String get hintPassword => 'Wachtwoord';

  @override
  String get btnSignIn => 'Inloggen';

  @override
  String get errorFillAll => 'Vul alle velden in';

  @override
  String get mfaTotp => 'Voer je authenticator code in';

  @override
  String get mfaEmail => 'Voer de code in die naar je e-mail is gestuurd';

  @override
  String get hint6digit => '6-cijferige code';

  @override
  String get btnVerify => 'Verificeren';

  @override
  String get backToLogin => '← Terug naar login';

  @override
  String get noPlaylists => 'Nog geen afspeellijsten';

  @override
  String songCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nummers',
      one: '1 nummer',
    );
    return '$_temp0';
  }

  @override
  String get tooltipPlayAll => 'Alles afspelen';

  @override
  String get tooltipShuffle => 'Shuffelen';

  @override
  String get noSongsInPlaylist => 'Geen nummers in deze afspeellijst';

  @override
  String get errorCannotLoad => 'Nummer kan niet worden geladen';

  @override
  String get languagePicker => 'Taal';

  @override
  String get langNl => 'Nederlands';

  @override
  String get langEn => 'Engels';

  @override
  String get langEs => 'Spaans';

  @override
  String get navSettings => 'Instellingen';

  @override
  String get settingsTitle => 'Instellingen';

  @override
  String get appearanceSection => 'Weergave';

  @override
  String get languageSection => 'Taal';

  @override
  String get storageSection => 'Opslag';

  @override
  String get themeMode => 'Thema';

  @override
  String get themeDark => 'Donker';

  @override
  String get themeLight => 'Licht';

  @override
  String get themeSystem => 'Systeemstandaard';

  @override
  String get translateLyrics => 'Vertalen';

  @override
  String get translating => 'Vertalen...';

  @override
  String get translateTo => 'Vertalen naar';

  @override
  String get translateError => 'Vertaling mislukt';

  @override
  String get originalLyrics => 'Origineel';

  @override
  String get translatedLyrics => 'Vertaling';

  @override
  String get clearCache => 'Cache wissen';

  @override
  String get cacheCleared => 'Cache gewist';

  @override
  String get showOriginal => 'Origineel tonen';

  @override
  String get translationDisclaimer =>
      'Vertaling kan onnauwkeurig zijn en fouten bevatten';

  @override
  String get tooltipShare => 'Delen';

  @override
  String get shareLinkCopied => 'Link gekopieerd!';

  @override
  String get downloadsHeader => 'Downloads';

  @override
  String get noDownloads => 'Geen gedownloade nummers';

  @override
  String get downloadRemoved => 'Verwijderd uit downloads';

  @override
  String get navLive => 'Live';

  @override
  String get liveListening => 'Live Luisteren';

  @override
  String get createRoom => 'Luisterfeestje starten';

  @override
  String get joinRoom => 'Kamer joinen';

  @override
  String get roomCode => 'Kamercode';

  @override
  String get enterRoomCode => 'Voer uitnodigingscode in';

  @override
  String get participants => 'Deelnemers';

  @override
  String get noParticipants => 'Nog geen deelnemers';

  @override
  String get host => 'Host';

  @override
  String get nowPlayingLabel => 'NU BEZIG';

  @override
  String get noSongPlaying => 'Geen nummer geselecteerd';

  @override
  String get leaveRoom => 'Verlaten';

  @override
  String get endRoom => 'Feestje beëindigen';

  @override
  String get endRoomConfirm =>
      'Dit beëindigt het feestje voor alle luisteraars.';

  @override
  String get syncNow => 'Nu synchroniseren';

  @override
  String get inviteCode => 'UITNODIGINGSCODE';

  @override
  String get roomCodeCopied => 'Kamercode gekopieerd!';

  @override
  String get hostControls => 'HOSTBEDIENING';

  @override
  String get transferHost => 'Maak host';

  @override
  String get roomEnded => 'Het luisterfeestje is beëindigd';

  @override
  String get controlledByHost => 'Bestuurd door host';

  @override
  String get menuSongInfo => 'Nummer info';

  @override
  String get downloadAll => 'Alles downloaden';
}
