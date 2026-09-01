# Changelog

All release notes are written in English.

---

## [2.3.1] — 2026-08-06

### Changed
- **Recently played moved to the Queue screen** — it was crowding the Songs screen alongside search, filters, and search history; it now lives on the Queue tab instead, which shows it even when the queue itself is empty.

---

## [2.3.0] — 2026-08-06

### Added
- **Liked songs** — tap the heart on a song card, song detail, or the player to like it. Liked songs get their own pinned "Liked Songs" playlist on the Playlists tab.
- **Recently played** — shows songs you've recently played so you can jump back to them.
- **Sleep timer** — new moon icon in the full-screen player; pick a preset (5/15/30/45/60 min) and playback pauses automatically when it runs out.
- **Search history** — recent search terms show as tappable chips when you focus the (empty) search field.
- **Crossfade** — new Settings → Playback section. When enabled, the end of a track fades out and the next fades in, with a configurable duration (2/4/6/8s). This is a fade transition, not a true overlapping crossfade — the audio player is tied to a single lock-screen/notification session, so only one track plays at a time.

### Tests
- New test coverage for liked songs, recently played, search history, and the player's sleep timer and crossfade volume ramp (using `fake_async` to drive timers deterministically).

---

## [2.2.2] — 2026-07-14

### Fixed
- **Android updates failing with "App not installed"** — release APKs were signed with a throwaway debug key that changed on every CI run, so Android rejected each new version as an update. Releases are now signed with a fixed upload keystore (via GitHub secrets), so future updates install normally.
  - **One-time action required:** because the signing key changed, updating from any older version requires uninstalling the app once and installing v2.2.2 fresh. Downloads and settings on the device are reset by the uninstall. After that, updates work in place again.

---

## [2.2.0] — 2026-07-13

### Added
- **Shuffle history** — pressing "previous" in shuffle mode now returns to the songs that actually played, in reverse order. Pressing "next" afterwards takes you forward again to where you were.
- **Download a whole playlist** — new download button in the playlist screen saves every song in the playlist for offline playback; it shows a spinner while downloading and a checkmark once everything is stored.
- **Song cache toggle** — new switch in Settings → Storage to disable the offline song list cache. Turning it off also wipes the stored cache.
- **Daily cache refresh** — the cached song list is refreshed automatically once a day, so offline data stays at most a day behind the server.
- **Progress bar on the home-screen widget** — a slim progress bar below the controls shows the playback position, updated every few seconds while playing.

### Changed
- **Lock-screen artwork fallback** — songs without artwork now show the app logo on the lock screen and in the media notification instead of a blank square. The home-screen widget uses the app logo as placeholder too.
- **Lock-screen progress** — the media notification now picks up the real track duration from the player, so the progress bar and seeking stay accurate even when the server reports a wrong duration.
- **Widget artwork refresh** — the home-screen widget no longer keeps showing the artwork of the first played song; art is cached per song.

### Fixed
- **macOS release build** — the macOS CI job now selects the latest stable Xcode, fixing the `connectivity_plus` build failure (`NWPath.isUltraConstrained`).

### Tests
- New test coverage for shuffle history, playlist download-all, the songs cache (toggle, staleness, offline fallback), lock-screen media item updates, and the widget progress data.

---

## [1.9.0] — 2026-07-01

### Changed
- **Spotify-style bottom sheets** — all action menus (song cards, song detail, player, global app bar) now open as a full-width bottom sheet instead of a small popup. Each sheet shows a song header with thumbnail, title, and artist.
- **Song card menu** — the three separate overlay buttons (share, queue, info) on each song card are replaced by a single ⋮ button that opens the new bottom sheet.

### Added
- **Download option in song card menu** — save or remove a song from offline storage directly from the song card bottom sheet.
- **"Download all" in the global menu** — download all currently visible songs in one tap. When a filter is active the label shows the count, e.g. *Download all (5)*.
- **Download progress banner** — a slim banner with a progress bar appears at the top of the Songs screen while downloads are in progress, and disappears automatically when all downloads finish.
- **Delete all downloads** — new option in Settings → Downloads to remove all downloaded songs at once, with a confirmation dialog.

---

## [1.8.0] — 2026-06-17

### Added
- **Share function** — share songs directly from the player and song detail screen.
- **Translation disclaimer** — disclaimer shown when using the lyrics translation feature.

### Tests
- Increased test coverage to 85%+.

---

## [0.6.0-alpha] — 2026-06-05

### Added
- **Settings screen** — accessible via the ⋮ menu in the app bar. Houses language selection, theme mode, and storage options.
- **Theme mode** — choose between System default, Light, and Dark inside Settings. The chosen mode is persisted across restarts.
- **Light theme** — full Material 3 light theme alongside the existing dark theme.
- **Lyrics translation** — tap the "Translate" button in the lyrics section of the song detail screen or the full-screen player to translate lyrics into the current app language. Uses the free [MyMemory](https://mymemory.translated.net/) REST API — no Google Play Services required.
  - Translations are cached in SharedPreferences and can be cleared from Settings → Storage → Clear cache.
  - A "Show original" toggle switches back to the original lyrics without re-fetching.
- **Shared `LyricsSection` widget** — lyrics display (including translation controls) is now a reusable widget shared between `SongDetailScreen` and `PlayerDetailScreen`.
- **`ThemeService`** — new `ChangeNotifier`-based service for persisting and broadcasting the selected `ThemeMode`.
- **`TranslationService`** — service wrapping the MyMemory translation API with per-song/per-language caching.

### Changed
- Language picker moved from the ⋮ popup menu into the Settings screen.
- App bar actions (⋮ menu) now shows "Settings" and "Admin login/logout" only — cleaner and less crowded.
- Hardcoded dark theme colors replaced with a proper `ThemeData` system (`theme` + `darkTheme` + `themeMode`) — colors now adapt to the active theme.
- Splash/loading screen spinner and icon now use theme primary color instead of hardcoded green.
- Navigation bar selected icon now uses `Theme.colorScheme.primary` instead of hardcoded `#1DB954`.
- Version bumped to `0.6.0+6`.

### Tests
- Added `test/services/theme_service_test.dart` (10 cases).
- Added `test/services/translation_service_test.dart` (4 cases).
- Added `test/screens/settings_screen_test.dart` (10 widget tests).

---

## [0.5.0] — 2026-05-xx

Initial tracked release. Core music player functionality with Dutch/English/Spanish localization, offline download support, playlist management, queue, and admin login.
