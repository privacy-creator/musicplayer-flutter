// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppL10nIt extends AppL10n {
  AppL10nIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Music Player';

  @override
  String get navSongs => 'Brani';

  @override
  String get navPlaylists => 'Playlist';

  @override
  String get tooltipRefresh => 'Aggiorna';

  @override
  String get tooltipShuffleAll => 'Mescola tutto';

  @override
  String get searchHint => 'Cerca brani...';

  @override
  String get filterLanguage => 'Lingua';

  @override
  String get filterGenre => 'Genere';

  @override
  String get allLanguage => 'Tutte le lingue';

  @override
  String get allGenre => 'Tutti i generi';

  @override
  String get noSongsFound => 'Nessun brano trovato';

  @override
  String get offlineBanner => 'Offline — brani in cache';

  @override
  String get noInternet => 'Nessuna connessione internet';

  @override
  String addedToQueue(String title) {
    return '$title aggiunto alla coda';
  }

  @override
  String get tooltipDownload => 'Salva offline';

  @override
  String get tooltipDeleteDownload => 'Rimuovi download';

  @override
  String get offlineBadge => 'Disponibile offline';

  @override
  String get btnAddToQueue => 'Aggiungi alla coda';

  @override
  String songAdded(String title) {
    return '$title aggiunto';
  }

  @override
  String get queue => 'Coda';

  @override
  String get lyrics => 'Testo';

  @override
  String get btnPlay => 'Riproduci';

  @override
  String get btnPause => 'Pausa';

  @override
  String get nowPlaying => 'In riproduzione';

  @override
  String get tooltipQueue => 'Coda';

  @override
  String get clearQueue => 'Svuota coda';

  @override
  String get emptyQueue => 'Nessun brano nella coda';

  @override
  String get sectionNowPlaying => 'In riproduzione';

  @override
  String sectionQueue(int count) {
    return 'Coda ($count)';
  }

  @override
  String get sectionUpNext => 'Successivo';

  @override
  String get adminLogin => 'Accesso admin';

  @override
  String get adminSubtitle => 'Solo per amministratori';

  @override
  String get tooltipAdminLogout => 'Disconnetti admin';

  @override
  String get tooltipAdminLogin => 'Accesso admin';

  @override
  String get hintEmail => 'Email';

  @override
  String get hintPassword => 'Password';

  @override
  String get btnSignIn => 'Accedi';

  @override
  String get errorFillAll => 'Compila tutti i campi';

  @override
  String get mfaTotp => 'Inserisci il codice dell\'app di autenticazione';

  @override
  String get mfaEmail => 'Inserisci il codice inviato alla tua email';

  @override
  String get hint6digit => 'Codice a 6 cifre';

  @override
  String get btnVerify => 'Verifica';

  @override
  String get backToLogin => '← Torna al login';

  @override
  String get noPlaylists => 'Nessuna playlist ancora';

  @override
  String songCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count brani',
      one: '1 brano',
    );
    return '$_temp0';
  }

  @override
  String get tooltipPlayAll => 'Riproduci tutto';

  @override
  String get tooltipShuffle => 'Mescola';

  @override
  String get noSongsInPlaylist => 'Nessun brano in questa playlist';

  @override
  String get errorCannotLoad => 'Impossibile caricare il brano';

  @override
  String get languagePicker => 'Lingua';

  @override
  String get langNl => 'Olandese';

  @override
  String get langEn => 'Inglese';

  @override
  String get langEs => 'Spagnolo';

  @override
  String get langDe => 'Tedesco';

  @override
  String get langIt => 'Italiano';

  @override
  String get navSettings => 'Impostazioni';

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String get appearanceSection => 'Aspetto';

  @override
  String get languageSection => 'Lingua';

  @override
  String get storageSection => 'Archiviazione';

  @override
  String get themeMode => 'Tema';

  @override
  String get themeDark => 'Scuro';

  @override
  String get themeLight => 'Chiaro';

  @override
  String get themeSystem => 'Predefinito di sistema';

  @override
  String get translateLyrics => 'Traduci';

  @override
  String get translating => 'Traduzione in corso...';

  @override
  String get translateTo => 'Traduci in';

  @override
  String get translateError => 'Traduzione fallita';

  @override
  String get originalLyrics => 'Originale';

  @override
  String get translatedLyrics => 'Traduzione';

  @override
  String get clearCache => 'Svuota cache';

  @override
  String get cacheCleared => 'Cache svuotata';

  @override
  String get showOriginal => 'Mostra originale';

  @override
  String get translationDisclaimer =>
      'La traduzione potrebbe essere imprecisa e contenere errori';

  @override
  String get tooltipShare => 'Condividi';

  @override
  String get shareLinkCopied => 'Link copiato!';

  @override
  String get downloadsHeader => 'Download';

  @override
  String get noDownloads => 'Nessun brano scaricato';

  @override
  String get downloadRemoved => 'Rimosso dai download';

  @override
  String get navLive => 'Live';

  @override
  String get liveListening => 'Ascolto dal vivo';

  @override
  String get createRoom => 'Avvia party di ascolto';

  @override
  String get joinRoom => 'Unisciti a una stanza';

  @override
  String get roomCode => 'Codice stanza';

  @override
  String get enterRoomCode => 'Inserisci il codice invito';

  @override
  String get participants => 'Partecipanti';

  @override
  String get noParticipants => 'Nessun partecipante ancora';

  @override
  String get host => 'Host';

  @override
  String get nowPlayingLabel => 'IN RIPRODUZIONE';

  @override
  String get noSongPlaying => 'Nessun brano selezionato';

  @override
  String get leaveRoom => 'Esci';

  @override
  String get endRoom => 'Termina party';

  @override
  String get endRoomConfirm =>
      'Questo terminerà il party per tutti gli ascoltatori.';

  @override
  String get syncNow => 'Sincronizza ora';

  @override
  String get inviteCode => 'CODICE INVITO';

  @override
  String get roomCodeCopied => 'Codice copiato!';

  @override
  String get hostControls => 'CONTROLLI HOST';

  @override
  String get transferHost => 'Rendi host';

  @override
  String get roomEnded => 'Il party di ascolto è terminato';

  @override
  String get controlledByHost => 'Controllato dall\'host';

  @override
  String get menuSongInfo => 'Info brano';

  @override
  String get downloadAll => 'Scarica tutto';

  @override
  String get deleteAllDownloads => 'Elimina tutti i download';

  @override
  String get allDownloadsRemoved => 'Tutti i download eliminati';

  @override
  String get downloadingActive => 'Download in corso';

  @override
  String get aboutSection => 'Informazioni';

  @override
  String get githubReleases => 'GitHub Releases';

  @override
  String get updateAvailable => 'Aggiornamento disponibile';
}
