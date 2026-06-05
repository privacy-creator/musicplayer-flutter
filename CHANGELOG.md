# Changelog

All release notes are written in English.

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
