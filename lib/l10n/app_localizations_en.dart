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
  String get likedSongs => 'Liked Songs';

  @override
  String get noLikedSongs => 'No liked songs yet';

  @override
  String get tooltipLike => 'Like';

  @override
  String get tooltipUnlike => 'Remove like';

  @override
  String get recentlyPlayed => 'Recently played';

  @override
  String get tooltipSleepTimer => 'Sleep timer';

  @override
  String get sleepTimerOff => 'Turn off timer';

  @override
  String get playbackSection => 'Playback';

  @override
  String get crossfade => 'Crossfade';

  @override
  String get crossfadeSubtitle =>
      'Fade out the end of a track and fade in the next';

  @override
  String get crossfadeDuration => 'Crossfade duration';

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
  String get langDe => 'German';

  @override
  String get langIt => 'Italian';

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
  String get songCache => 'Song list cache';

  @override
  String get songCacheSubtitle => 'Refreshed once a day and used when offline';

  @override
  String get showOriginal => 'Show original';

  @override
  String get translationDisclaimer =>
      'Translation may be inaccurate and contain errors';

  @override
  String get tooltipShare => 'Share';

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

  @override
  String get menuSongInfo => 'Song info';

  @override
  String get downloadAll => 'Download all';

  @override
  String get deleteAllDownloads => 'Delete all downloads';

  @override
  String get allDownloadsRemoved => 'All downloads removed';

  @override
  String get downloadingActive => 'Downloading';

  @override
  String get aboutSection => 'About';

  @override
  String get githubReleases => 'GitHub Releases';

  @override
  String get updateAvailable => 'Update available';

  @override
  String get roomChat => 'Chat';

  @override
  String get chatHint => 'Message…';

  @override
  String get chatSend => 'Send';

  @override
  String get recentRooms => 'Recent rooms';

  @override
  String get rejoin => 'Rejoin';

  @override
  String get continueListening => 'Continue listening';

  @override
  String get onThisDay => 'On this day';

  @override
  String get editLyricsLrc => 'Edit synced lyrics (LRC)';

  @override
  String get lyricsLrcHint =>
      'Paste LRC-formatted lyrics here, e.g.\n[00:12.30] First line';

  @override
  String get save => 'Save';

  @override
  String get shareAsImage => 'Share as image';

  @override
  String get lyricsSaved => 'Lyrics saved';

  @override
  String get lyricsSaveError => 'Couldn\'t save lyrics';

  @override
  String get syncLyricsTool => 'Sync line by line';

  @override
  String get syncLyricsHelp =>
      'Play the song and tap the button exactly when each line starts. Tap a line to select it, tap its time to jump there.';

  @override
  String get syncSetTime => 'Set time';

  @override
  String get syncUndo => 'Undo';

  @override
  String get syncDone => 'Done';

  @override
  String get syncPlaySongHint => 'Play this song to sync along with it';

  @override
  String get syncPlaySong => 'Play song';

  @override
  String get syncNoLines =>
      'Type or paste the lyric lines first (one per line), then open the sync tool.';

  @override
  String syncProgress(int done, int total) {
    return '$done of $total lines synced';
  }

  @override
  String get syncClearTime => 'Clear time';

  @override
  String get smartPlaylists => 'Made for you';

  @override
  String get smartMostPlayed => 'Most played';

  @override
  String get smartMostPlayedDesc => 'The songs you play the most';

  @override
  String get smartForgottenFavorites => 'Forgotten favorites';

  @override
  String get smartForgottenFavoritesDesc =>
      'Liked songs you haven\'t played in a month';

  @override
  String get smartNeverPlayed => 'Never played';

  @override
  String get smartNeverPlayedDesc => 'Songs you haven\'t heard yet';

  @override
  String smartNewThisYear(String year) {
    return 'New in $year';
  }

  @override
  String get smartNewThisYearDesc => 'Songs released this year';

  @override
  String smartGenreMix(String genre) {
    return '$genre mix';
  }

  @override
  String get smartGenreMixDesc => 'Everything from your most played genre';

  @override
  String get navLocal => 'On device';

  @override
  String get localSongsTab => 'Songs';

  @override
  String get localPlaylistsTab => 'Playlists';

  @override
  String get localScan => 'Scan device';

  @override
  String get localScanning => 'Scanning…';

  @override
  String localScanDone(int count) {
    return '$count new songs found';
  }

  @override
  String get localPermissionDenied =>
      'No access to storage. Allow access in the system settings.';

  @override
  String get localScanError => 'Scanning failed';

  @override
  String get localEmptyTitle => 'No local music yet';

  @override
  String get localEmptyBody =>
      'Scan your device to find audio files. They stay on your device and are kept separate from the cloud music.';

  @override
  String get localSearchHint => 'Search on device…';

  @override
  String get localUnknownArtist => 'Unknown artist';

  @override
  String get localRename => 'Rename';

  @override
  String get localFieldTitle => 'Title';

  @override
  String get localFieldArtist => 'Artist';

  @override
  String get localRenameFile => 'Also rename the file on the device';

  @override
  String get localRenameDone => 'Name changed';

  @override
  String get localRenameExists => 'A file with this name already exists';

  @override
  String get localRenameFailed => 'The file could not be renamed';

  @override
  String get localAddToPlaylist => 'Add to playlist';

  @override
  String get localNewPlaylist => 'New playlist';

  @override
  String get localPlaylistName => 'Playlist name';

  @override
  String get localCreate => 'Create';

  @override
  String get localCancel => 'Cancel';

  @override
  String localAddedToPlaylist(String name) {
    return 'Added to $name';
  }

  @override
  String localAlreadyInPlaylist(String name) {
    return 'Already in $name';
  }

  @override
  String get localNoPlaylists => 'No local playlists yet';

  @override
  String get localPlaylistEmpty =>
      'This playlist is empty. Add songs from the Songs tab.';

  @override
  String get localNotShareable =>
      'Only on this device — local playlists can\'t be shared';

  @override
  String get localRenamePlaylist => 'Rename playlist';

  @override
  String get localDeletePlaylist => 'Delete playlist';

  @override
  String localDeletePlaylistConfirm(String name) {
    return 'Delete \"$name\"? The audio files stay on your device.';
  }

  @override
  String get localRemoveFromPlaylist => 'Remove from playlist';

  @override
  String get localPlay => 'Play';

  @override
  String get localShuffle => 'Shuffle';

  @override
  String get localOnDevice => 'On this device';

  @override
  String get localIosHint =>
      'Put audio files in the Music Player folder via the Files app, then scan.';

  @override
  String get localExcludeFolder => 'Exclude folder';

  @override
  String localExcludeFolderConfirm(String folder) {
    return 'Exclude \"$folder\"? Songs in this folder and its subfolders will no longer be shown. The files stay on your device.';
  }

  @override
  String localFolderExcluded(int count) {
    return 'Folder excluded — $count songs hidden';
  }

  @override
  String get localDelete => 'Delete';

  @override
  String localDeleteTitle(String title) {
    return 'Delete \"$title\"?';
  }

  @override
  String get localRemoveFromLibrary => 'Remove from library';

  @override
  String get localRemoveFromLibraryDesc => 'The file stays on your device';

  @override
  String get localDeleteFromDevice => 'Delete from device';

  @override
  String get localDeleteFromDeviceDesc => 'The file is permanently deleted';

  @override
  String get localRemovedFromLibrary => 'Removed from library';

  @override
  String get localDeletedFromDevice => 'File deleted from device';

  @override
  String get localDeleteFailed => 'The file could not be deleted';

  @override
  String get localSettingsSection => 'Local music';

  @override
  String get localFolders => 'Folders';

  @override
  String localFoldersDesc(int count) {
    return '$count excluded';
  }

  @override
  String get localFoldersEmpty => 'No folders yet — scan your device first';

  @override
  String get localExcludedLabel => 'Excluded';

  @override
  String get localHiddenSongs => 'Hidden songs';

  @override
  String localHiddenSongsDesc(int count) {
    return '$count hidden';
  }

  @override
  String get localHiddenEmpty => 'No hidden songs';

  @override
  String get localRestore => 'Restore';

  @override
  String get localRestored =>
      'Restored — the song comes back after the next scan';
}
