import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_nl.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppL10n
/// returned by `AppL10n.of(context)`.
///
/// Applications need to include `AppL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppL10n.localizationsDelegates,
///   supportedLocales: AppL10n.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppL10n.supportedLocales
/// property.
abstract class AppL10n {
  AppL10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppL10n? of(BuildContext context) {
    return Localizations.of<AppL10n>(context, AppL10n);
  }

  static const LocalizationsDelegate<AppL10n> delegate = _AppL10nDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('nl'),
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Music Player'**
  String get appTitle;

  /// No description provided for @navSongs.
  ///
  /// In en, this message translates to:
  /// **'Songs'**
  String get navSongs;

  /// No description provided for @navPlaylists.
  ///
  /// In en, this message translates to:
  /// **'Playlists'**
  String get navPlaylists;

  /// No description provided for @tooltipRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get tooltipRefresh;

  /// No description provided for @tooltipShuffleAll.
  ///
  /// In en, this message translates to:
  /// **'Shuffle all'**
  String get tooltipShuffleAll;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search songs...'**
  String get searchHint;

  /// No description provided for @filterLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get filterLanguage;

  /// No description provided for @filterGenre.
  ///
  /// In en, this message translates to:
  /// **'Genre'**
  String get filterGenre;

  /// No description provided for @allLanguage.
  ///
  /// In en, this message translates to:
  /// **'All languages'**
  String get allLanguage;

  /// No description provided for @allGenre.
  ///
  /// In en, this message translates to:
  /// **'All genres'**
  String get allGenre;

  /// No description provided for @noSongsFound.
  ///
  /// In en, this message translates to:
  /// **'No songs found'**
  String get noSongsFound;

  /// No description provided for @offlineBanner.
  ///
  /// In en, this message translates to:
  /// **'Offline — cached songs'**
  String get offlineBanner;

  /// No description provided for @noInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get noInternet;

  /// No description provided for @addedToQueue.
  ///
  /// In en, this message translates to:
  /// **'{title} added to queue'**
  String addedToQueue(String title);

  /// No description provided for @tooltipDownload.
  ///
  /// In en, this message translates to:
  /// **'Save offline'**
  String get tooltipDownload;

  /// No description provided for @tooltipDeleteDownload.
  ///
  /// In en, this message translates to:
  /// **'Remove download'**
  String get tooltipDeleteDownload;

  /// No description provided for @offlineBadge.
  ///
  /// In en, this message translates to:
  /// **'Available offline'**
  String get offlineBadge;

  /// No description provided for @btnAddToQueue.
  ///
  /// In en, this message translates to:
  /// **'Add to queue'**
  String get btnAddToQueue;

  /// No description provided for @songAdded.
  ///
  /// In en, this message translates to:
  /// **'{title} added'**
  String songAdded(String title);

  /// No description provided for @queue.
  ///
  /// In en, this message translates to:
  /// **'Queue'**
  String get queue;

  /// No description provided for @lyrics.
  ///
  /// In en, this message translates to:
  /// **'Lyrics'**
  String get lyrics;

  /// No description provided for @btnPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get btnPlay;

  /// No description provided for @btnPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get btnPause;

  /// No description provided for @nowPlaying.
  ///
  /// In en, this message translates to:
  /// **'Now playing'**
  String get nowPlaying;

  /// No description provided for @tooltipQueue.
  ///
  /// In en, this message translates to:
  /// **'Queue'**
  String get tooltipQueue;

  /// No description provided for @clearQueue.
  ///
  /// In en, this message translates to:
  /// **'Clear queue'**
  String get clearQueue;

  /// No description provided for @emptyQueue.
  ///
  /// In en, this message translates to:
  /// **'No songs in the queue'**
  String get emptyQueue;

  /// No description provided for @sectionNowPlaying.
  ///
  /// In en, this message translates to:
  /// **'Now playing'**
  String get sectionNowPlaying;

  /// No description provided for @sectionQueue.
  ///
  /// In en, this message translates to:
  /// **'Queue ({count})'**
  String sectionQueue(int count);

  /// No description provided for @sectionUpNext.
  ///
  /// In en, this message translates to:
  /// **'Up next'**
  String get sectionUpNext;

  /// No description provided for @adminLogin.
  ///
  /// In en, this message translates to:
  /// **'Admin Login'**
  String get adminLogin;

  /// No description provided for @adminSubtitle.
  ///
  /// In en, this message translates to:
  /// **'For administrators only'**
  String get adminSubtitle;

  /// No description provided for @tooltipAdminLogout.
  ///
  /// In en, this message translates to:
  /// **'Admin logout'**
  String get tooltipAdminLogout;

  /// No description provided for @tooltipAdminLogin.
  ///
  /// In en, this message translates to:
  /// **'Admin login'**
  String get tooltipAdminLogin;

  /// No description provided for @hintEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get hintEmail;

  /// No description provided for @hintPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get hintPassword;

  /// No description provided for @btnSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get btnSignIn;

  /// No description provided for @errorFillAll.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields'**
  String get errorFillAll;

  /// No description provided for @mfaTotp.
  ///
  /// In en, this message translates to:
  /// **'Enter your authenticator app code'**
  String get mfaTotp;

  /// No description provided for @mfaEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter the code sent to your email'**
  String get mfaEmail;

  /// No description provided for @hint6digit.
  ///
  /// In en, this message translates to:
  /// **'6-digit code'**
  String get hint6digit;

  /// No description provided for @btnVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get btnVerify;

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'← Back to login'**
  String get backToLogin;

  /// No description provided for @noPlaylists.
  ///
  /// In en, this message translates to:
  /// **'No playlists yet'**
  String get noPlaylists;

  /// No description provided for @songCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 song} other{{count} songs}}'**
  String songCount(int count);

  /// No description provided for @tooltipPlayAll.
  ///
  /// In en, this message translates to:
  /// **'Play all'**
  String get tooltipPlayAll;

  /// No description provided for @tooltipShuffle.
  ///
  /// In en, this message translates to:
  /// **'Shuffle'**
  String get tooltipShuffle;

  /// No description provided for @noSongsInPlaylist.
  ///
  /// In en, this message translates to:
  /// **'No songs in this playlist'**
  String get noSongsInPlaylist;

  /// No description provided for @errorCannotLoad.
  ///
  /// In en, this message translates to:
  /// **'Song could not be loaded'**
  String get errorCannotLoad;

  /// No description provided for @languagePicker.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languagePicker;

  /// No description provided for @langNl.
  ///
  /// In en, this message translates to:
  /// **'Dutch'**
  String get langNl;

  /// No description provided for @langEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get langEn;

  /// No description provided for @langEs.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get langEs;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @appearanceSection.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceSection;

  /// No description provided for @languageSection.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSection;

  /// No description provided for @storageSection.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get storageSection;

  /// No description provided for @themeMode.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeMode;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get themeSystem;

  /// No description provided for @translateLyrics.
  ///
  /// In en, this message translates to:
  /// **'Translate'**
  String get translateLyrics;

  /// No description provided for @translating.
  ///
  /// In en, this message translates to:
  /// **'Translating...'**
  String get translating;

  /// No description provided for @translateTo.
  ///
  /// In en, this message translates to:
  /// **'Translate to'**
  String get translateTo;

  /// No description provided for @translateError.
  ///
  /// In en, this message translates to:
  /// **'Translation failed'**
  String get translateError;

  /// No description provided for @originalLyrics.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get originalLyrics;

  /// No description provided for @translatedLyrics.
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get translatedLyrics;

  /// No description provided for @clearCache.
  ///
  /// In en, this message translates to:
  /// **'Clear cache'**
  String get clearCache;

  /// No description provided for @cacheCleared.
  ///
  /// In en, this message translates to:
  /// **'Cache cleared'**
  String get cacheCleared;

  /// No description provided for @showOriginal.
  ///
  /// In en, this message translates to:
  /// **'Show original'**
  String get showOriginal;

  /// No description provided for @translationDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Translation may be inaccurate and contain errors'**
  String get translationDisclaimer;

  /// No description provided for @tooltipShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get tooltipShare;

  /// No description provided for @shareLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied!'**
  String get shareLinkCopied;

  /// No description provided for @downloadsHeader.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get downloadsHeader;

  /// No description provided for @noDownloads.
  ///
  /// In en, this message translates to:
  /// **'No downloaded songs'**
  String get noDownloads;

  /// No description provided for @downloadRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed from downloads'**
  String get downloadRemoved;

  /// No description provided for @navLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get navLive;

  /// No description provided for @liveListening.
  ///
  /// In en, this message translates to:
  /// **'Live Listening'**
  String get liveListening;

  /// No description provided for @createRoom.
  ///
  /// In en, this message translates to:
  /// **'Start Listening Party'**
  String get createRoom;

  /// No description provided for @joinRoom.
  ///
  /// In en, this message translates to:
  /// **'Join a Room'**
  String get joinRoom;

  /// No description provided for @roomCode.
  ///
  /// In en, this message translates to:
  /// **'Room Code'**
  String get roomCode;

  /// No description provided for @enterRoomCode.
  ///
  /// In en, this message translates to:
  /// **'Enter invite code'**
  String get enterRoomCode;

  /// No description provided for @participants.
  ///
  /// In en, this message translates to:
  /// **'Participants'**
  String get participants;

  /// No description provided for @noParticipants.
  ///
  /// In en, this message translates to:
  /// **'No participants yet'**
  String get noParticipants;

  /// No description provided for @host.
  ///
  /// In en, this message translates to:
  /// **'Host'**
  String get host;

  /// No description provided for @nowPlayingLabel.
  ///
  /// In en, this message translates to:
  /// **'NOW PLAYING'**
  String get nowPlayingLabel;

  /// No description provided for @noSongPlaying.
  ///
  /// In en, this message translates to:
  /// **'No song selected'**
  String get noSongPlaying;

  /// No description provided for @leaveRoom.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leaveRoom;

  /// No description provided for @endRoom.
  ///
  /// In en, this message translates to:
  /// **'End Party'**
  String get endRoom;

  /// No description provided for @endRoomConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will end the party for all listeners.'**
  String get endRoomConfirm;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get syncNow;

  /// No description provided for @inviteCode.
  ///
  /// In en, this message translates to:
  /// **'INVITE CODE'**
  String get inviteCode;

  /// No description provided for @roomCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Room code copied!'**
  String get roomCodeCopied;

  /// No description provided for @hostControls.
  ///
  /// In en, this message translates to:
  /// **'HOST CONTROLS'**
  String get hostControls;

  /// No description provided for @transferHost.
  ///
  /// In en, this message translates to:
  /// **'Make host'**
  String get transferHost;

  /// No description provided for @roomEnded.
  ///
  /// In en, this message translates to:
  /// **'The listening party has ended'**
  String get roomEnded;

  /// No description provided for @controlledByHost.
  ///
  /// In en, this message translates to:
  /// **'Controlled by host'**
  String get controlledByHost;
}

class _AppL10nDelegate extends LocalizationsDelegate<AppL10n> {
  const _AppL10nDelegate();

  @override
  Future<AppL10n> load(Locale locale) {
    return SynchronousFuture<AppL10n>(lookupAppL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'nl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppL10nDelegate old) => false;
}

AppL10n lookupAppL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppL10nEn();
    case 'es':
      return AppL10nEs();
    case 'nl':
      return AppL10nNl();
  }

  throw FlutterError(
    'AppL10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
