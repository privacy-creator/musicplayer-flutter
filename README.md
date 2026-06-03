# Music Player — Flutter App

Een Flutter muziekspeler app voor Android en iOS, gekoppeld aan een PHP/MySQL backend. Gebruikers kunnen nummers en playlists bladeren en afspelen zonder account. Beheerders kunnen inloggen via een verborgen adminknop.

---

## Functies

- **Nummers bladeren** — zoeken op titel/artiest, filteren op taal en genre
- **Playlists** — overzicht en detail met alle nummers
- **Muziek afspelen** — via `just_audio` met seekbare voortgangsbalk
- **Mini-player** — altijd zichtbaar onderaan met vorige/play/volgende/shuffle
- **Player detail** — groot albumplaatje, voortgang met tijdweergave, liedtekst
- **Shuffle mode** — willekeurige afspeelvolgorde
- **Song detail** — albumhoes, metadata en liedtekst
- **Admin login** — verborgen knop rechtsbovenin, alleen voor beheerders
- **Sessie persistentie** — PHP-sessiecookies worden opgeslagen zodat admins ingelogd blijven

---

## Vereisten

- [Flutter SDK](https://docs.flutter.dev/get-started/install) ≥ 3.11
- Android emulator of fysiek apparaat (Android 6+)
- XAMPP (of andere LAMP/WAMP stack) met de bijbehorende PHP backend actief

---

## Installatie

```bash
git clone https://github.com/privacy-creator/musicplayer-flutter.git
cd musicplayer-flutter
flutter pub get
```

---

## Configuratie

Open [lib/constants.dart](lib/constants.dart) en stel de juiste URL in:

```dart
class AppConstants {
  // Android emulator → 10.0.2.2 wijst naar de host-machine
  static const String baseUrl = 'http://10.0.2.2/backend';

  // Fysiek apparaat → gebruik het LAN-IP van je PC
  // static const String baseUrl = 'http://192.168.1.x/backend';
}
```

| Scenario | URL |
|---|---|
| Android emulator | `http://10.0.2.2/backend` |
| Fysiek apparaat (zelfde wifi) | `http://192.168.1.x/backend` |
| iOS simulator | `http://localhost/backend` |

> **Let op:** vervang `192.168.1.x` door het werkelijke IP-adres van je PC (te vinden via `ipconfig`).

---

## Backend

Deze app vereist de bijbehorende PHP backend:

- **Locatie:** `C:\xampp\htdocs\backend` (of vergelijkbaar)
- **Database:** MySQL met tabellen `songs`, `playlists`, `playlist_songs`, `users`
- **Uploads:** audiobestanden in `backend/uploads/`

De backend verzorgt authenticatie via PHP-sessies. Zorg dat XAMPP/Apache draait voordat je de app start.

---

## App starten

```bash
# Lijst van beschikbare apparaten
flutter devices

# Starten op een specifiek apparaat
flutter run -d <device-id>

# Of gewoon (pakt het eerste beschikbare apparaat)
flutter run
```

### Windows Developer Mode

Flutter vereist op Windows Developer Mode voor symlink-ondersteuning:

**Instellingen → Systeem → Ontwikkelaars → Developer Mode aan**

---

## Projectstructuur

```
lib/
├── constants.dart                  # Base URL configuratie
├── main.dart                       # App entry point, providers, navigatie shell
├── models/
│   ├── song.dart                   # Song model (URL rewriting ingebouwd)
│   └── playlist.dart               # Playlist model
├── services/
│   ├── api_service.dart            # Dio HTTP client met cookie persistentie
│   ├── auth_service.dart           # Login, MFA, sessie check
│   └── player_service.dart         # just_audio wrapper, shuffle, queue
├── screens/
│   ├── songs_screen.dart           # Nummers grid met zoeken en filters
│   ├── song_detail_screen.dart     # Nummer detail met liedtekst
│   ├── playlists_screen.dart       # Playlists overzicht
│   ├── playlist_detail_screen.dart # Playlist detail met nummers
│   ├── player_detail_screen.dart   # Volledig scherm player met lyrics
│   └── login_screen.dart           # Admin login (MFA ondersteund)
└── widgets/
    └── player_bar.dart             # Mini-player onderaan het scherm
```

---

## Tech stack

| Pakket | Gebruik |
|---|---|
| `just_audio` | Audio afspelen (ExoPlayer op Android) |
| `audio_session` | Audio focus beheer |
| `provider` | State management |
| `dio` | HTTP requests |
| `dio_cookie_manager` + `cookie_jar` | Persistente PHP-sessiecookies |
| `path_provider` | Opslag voor cookies op het apparaat |

---

## Android configuratie

Het project is geconfigureerd voor cleartext HTTP-verkeer (vereist voor lokale XAMPP):

- `android/app/src/main/res/xml/network_security_config.xml` — staat HTTP toe naar `10.0.2.2` en `localhost`
- `AndroidManifest.xml` — `INTERNET` permissie en `networkSecurityConfig` gekoppeld
