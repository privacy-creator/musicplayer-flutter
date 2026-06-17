# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Run all tests
flutter test

# Run a single test file
flutter test test/services/download_service_test.dart

# Run tests with coverage
flutter test --coverage

# Analyze for lint/type errors
flutter analyze

# Build release APK
flutter build apk --release
```

## Architecture

Provider pattern throughout. All services are instantiated in `main()` and injected via `MultiProvider`. The widget tree consumes them with `context.watch<T>()` / `context.read<T>()`.

**Service layer** (`lib/services/`):
- `PlayerService` — playback, queue, shuffle; wraps `MusicAudioHandler` (audio_service)
- `DownloadService` — downloads songs to `getApplicationDocumentsDirectory()/song_downloads/<id>.mp3`; persists a `{songId: localPath}` map in SharedPreferences under key `downloaded_songs_v1`
- `TranslationService` — calls MyMemory REST API, caches per `lyrics_translation_{songId}_{lang}` in SharedPreferences
- `ApiService` — Dio HTTP client to `hiddebalestra.nl`
- `AuthService` — cookie-based admin auth via `ChangeNotifierProxyProvider<ApiService, AuthService>`
- `LanguageService` / `ThemeService` — persist locale (`app_locale`) and theme mode (`app_theme_mode`) in SharedPreferences; NL is default locale

**Localization**: ARB-generated via `flutter gen-l10n` (configured in `l10n.yaml`). When adding a string key, add it to the 3 ARB files in `lib/l10n/` and run `flutter analyze` to regenerate the Dart files:
- `lib/l10n/app_en.arb` — template (English)
- `lib/l10n/app_nl.arb` — Dutch
- `lib/l10n/app_es.arb` — Spanish

Do NOT edit the generated `app_localizations*.dart` files directly — they will be overwritten.

**Navigation shell** (`main.dart`): `_AuthWrapper` checks admin cookie on startup, then shows `_MainShell` with a `NavigationBar` (Songs / Playlists) and a persistent `PlayerBar` above it.

**SharedPreferences keys**: `app_locale`, `app_theme_mode`, `shuffle_mode`, `songs_cache_v1`, `downloaded_songs_v1`, `lyrics_translation_{songId}_{lang}`

## Testing conventions

- Use `mocktail` for mocks (not `mockito`)
- `DownloadService` accepts a `testBaseDir` constructor param to avoid hitting the real filesystem
- `SharedPreferences.setMockInitialValues({})` in `setUp` to reset state
- Test descriptions are written in Dutch
- Widget tests use `AppL10nEn` for localization; wrap the widget under test in a `MaterialApp` with the localizations delegates
- no tests because the work flow takes care of it