// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppL10nEn extends AppL10n {
  AppL10nEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Music Player';

  @override
  String get navSongs => 'Songs';

  @override
  String get navPlaylists => 'Playlists';

  @override
  String get tooltipRefresh => 'Refresh';

  @override
  String get tooltipShuffleAll => 'Shuffle all';

  @override
  String get searchHint => 'Search songs...';

  @override
  String get filterLanguage => 'Language';

  @override
  String get filterGenre => 'Genre';

  @override
  String get allLanguage => 'All languages';

  @override
  String get allGenre => 'All genres';

  @override
  String get noSongsFound => 'No songs found';

  @override
  String get offlineBanner => 'Offline — cached songs';

  @override
  String get noInternet => 'No internet connection';

  @override
  String addedToQueue(String title) {
    return '$title added to queue';
  }

  @override
  String get tooltipDownload => 'Save offline';

  @override
  String get tooltipDeleteDownload => 'Remove download';

  @override
  String get offlineBadge => 'Available offline';

  @override
  String get btnAddToQueue => 'Add to queue';

  @override
  String songAdded(String title) {
    return '$title added';
  }

  @override
  String get queue => 'Queue';

  @override
  String get lyrics => 'Lyrics';

  @override
  String get btnPlay => 'Play';

  @override
  String get btnPause => 'Pause';

  @override
  String get nowPlaying => 'Now playing';

  @override
  String get tooltipQueue => 'Queue';

  @override
  String get clearQueue => 'Clear queue';

  @override
  String get emptyQueue => 'No songs in the queue';

  @override
  String get sectionNowPlaying => 'Now playing';

  @override
  String sectionQueue(int count) {
    return 'Queue ($count)';
  }

  @override
  String get sectionUpNext => 'Up next';

  @override
  String get adminLogin => 'Admin Login';

  @override
  String get adminSubtitle => 'For administrators only';

  @override
  String get tooltipAdminLogout => 'Admin logout';

  @override
  String get tooltipAdminLogin => 'Admin login';

  @override
  String get hintEmail => 'Email';

  @override
  String get hintPassword => 'Password';

  @override
  String get btnSignIn => 'Sign In';

  @override
  String get errorFillAll => 'Please fill in all fields';

  @override
  String get mfaTotp => 'Enter your authenticator app code';

  @override
  String get mfaEmail => 'Enter the code sent to your email';

  @override
  String get hint6digit => '6-digit code';

  @override
  String get btnVerify => 'Verify';

  @override
  String get backToLogin => '← Back to login';

  @override
  String get noPlaylists => 'No playlists yet';

  @override
  String songCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs',
      one: '1 song',
    );
    return '$_temp0';
  }

  @override
  String get tooltipPlayAll => 'Play all';

  @override
  String get tooltipShuffle => 'Shuffle';

  @override
  String get noSongsInPlaylist => 'No songs in this playlist';

  @override
  String get errorCannotLoad => 'Song could not be loaded';

  @override
  String get languagePicker => 'Language';

  @override
  String get langNl => 'Dutch';

  @override
  String get langEn => 'English';

  @override
  String get langEs => 'Spanish';

  @override
  String get navSettings => 'Settings';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get appearanceSection => 'Appearance';

  @override
  String get languageSection => 'Language';

  @override
  String get storageSection => 'Storage';

  @override
  String get themeMode => 'Theme';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeLight => 'Light';

  @override
  String get themeSystem => 'System default';

  @override
  String get translateLyrics => 'Translate';

  @override
  String get translating => 'Translating...';

  @override
  String get translateTo => 'Translate to';

  @override
  String get translateError => 'Translation failed';

  @override
  String get originalLyrics => 'Original';

  @override
  String get translatedLyrics => 'Translation';

  @override
  String get clearCache => 'Clear cache';

  @override
  String get cacheCleared => 'Cache cleared';

  @override
  String get showOriginal => 'Show original';

  @override
  String get translationDisclaimer =>
      'Translation may be inaccurate and contain errors';

  @override
  String get tooltipShare => 'Share';

  @override
  String get menuSongInfo => 'Song info';

  @override
  String get shareLinkCopied => 'Link copied!';

  @override
  String get downloadsHeader => 'Downloads';

  @override
  String get noDownloads => 'No downloaded songs';

  @override
  String get downloadRemoved => 'Removed from downloads';

  @override
  String get navLive => 'Live';

  @override
  String get liveListening => 'Live Listening';

  @override
  String get createRoom => 'Start Listening Party';

  @override
  String get joinRoom => 'Join a Room';

  @override
  String get roomCode => 'Room Code';

  @override
  String get enterRoomCode => 'Enter invite code';

  @override
  String get participants => 'Participants';

  @override
  String get noParticipants => 'No participants yet';

  @override
  String get host => 'Host';

  @override
  String get nowPlayingLabel => 'NOW PLAYING';

  @override
  String get noSongPlaying => 'No song selected';

  @override
  String get leaveRoom => 'Leave';

  @override
  String get endRoom => 'End Party';

  @override
  String get endRoomConfirm => 'This will end the party for all listeners.';

  @override
  String get syncNow => 'Sync Now';

  @override
  String get inviteCode => 'INVITE CODE';

  @override
  String get roomCodeCopied => 'Room code copied!';

  @override
  String get hostControls => 'HOST CONTROLS';

  @override
  String get transferHost => 'Make host';

  @override
  String get roomEnded => 'The listening party has ended';

  @override
  String get controlledByHost => 'Controlled by host';
}
