import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'l10n/app_localizations.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/audio_handler.dart';
import 'services/download_service.dart';
import 'services/language_service.dart';
import 'services/player_service.dart';
import 'services/theme_service.dart';
import 'services/translation_service.dart';
import 'screens/listening_room_screen.dart';
import 'screens/songs_screen.dart';
import 'screens/playlists_screen.dart';
import 'services/streaming_service.dart';
import 'widgets/player_bar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Permission.notification.request();

  final downloadService = DownloadService();
  await downloadService.init();

  final prefs = await SharedPreferences.getInstance();
  final languageService = LanguageService(prefs);
  final themeService = ThemeService(prefs);
  final translationService = TranslationService(prefs);

  final handler = await AudioService.init(
    builder: () => MusicAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.music_player_flutter.audio',
      androidNotificationChannelName: 'Muziek',
      androidNotificationIcon: 'mipmap/ic_launcher',
      androidNotificationOngoing: false,
      androidStopForegroundOnPause: false,
      notificationColor: Color(0xFF1DB954),
    ),
  );
  runApp(MusicPlayerApp(
    audioHandler: handler,
    downloadService: downloadService,
    languageService: languageService,
    themeService: themeService,
    translationService: translationService,
  ));
}

class MusicPlayerApp extends StatelessWidget {
  final MusicAudioHandler audioHandler;
  final DownloadService downloadService;
  final LanguageService languageService;
  final ThemeService themeService;
  final TranslationService translationService;

  const MusicPlayerApp({
    super.key,
    required this.audioHandler,
    required this.downloadService,
    required this.languageService,
    required this.themeService,
    required this.translationService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LanguageService>.value(value: languageService),
        ChangeNotifierProvider<ThemeService>.value(value: themeService),
        Provider<TranslationService>.value(value: translationService),
        ChangeNotifierProvider<DownloadService>.value(value: downloadService),
        Provider<ApiService>(create: (_) => ApiService()),
        ChangeNotifierProxyProvider<ApiService, AuthService>(
          create: (ctx) => AuthService(ctx.read<ApiService>()),
          update: (_, api, prev) => prev ?? AuthService(api),
        ),
        ChangeNotifierProvider<PlayerService>(
          create: (_) => PlayerService(
            handler: audioHandler,
            downloadService: downloadService,
          ),
        ),
        ChangeNotifierProxyProvider2<ApiService, PlayerService, StreamingService>(
          create: (ctx) => StreamingService(ctx.read<ApiService>().dio),
          update: (_, api, player, prev) {
            final svc = prev ?? StreamingService(api.dio);
            svc.listenToPlayer(player);
            return svc;
          },
        ),
      ],
      child: Consumer2<LanguageService, ThemeService>(
        builder: (_, lang, theme, _) => MaterialApp(
          title: 'Music Player',
          debugShowCheckedModeBanner: false,
          locale: lang.locale,
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          themeMode: theme.themeMode,
          theme: _lightTheme(),
          darkTheme: _darkTheme(),
          home: const _AuthWrapper(),
        ),
      ),
    );
  }

  static ThemeData _darkTheme() => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF1DB954),
          secondary: Color(0xFF1ED760),
          surface: Color(0xFF1E1E1E),
          surfaceContainerHighest: Color(0xFF282828),
          onSurface: Colors.white,
          onSurfaceVariant: Color(0xFFB3B3B3),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          foregroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Color(0xFF1E1E1E),
          indicatorColor: Color(0x221DB954),
        ),
        listTileTheme: const ListTileThemeData(
          iconColor: Color(0xFFB3B3B3),
          subtitleTextStyle: TextStyle(color: Color(0xFFB3B3B3), fontSize: 13),
        ),
        dividerColor: Colors.white12,
        cardColor: const Color(0xFF1E1E1E),
      );

  static ThemeData _lightTheme() => ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF0F0F0),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF1AA34A),
          secondary: Color(0xFF1DB954),
          surface: Colors.white,
          surfaceContainerHighest: Color(0xFFE4E4E4),
          onSurface: Color(0xFF111111),
          onSurfaceVariant: Color(0xFF555555),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF111111),
          elevation: 0,
          titleTextStyle: TextStyle(
              color: Color(0xFF111111), fontSize: 18, fontWeight: FontWeight.bold),
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: Color(0x221AA34A),
        ),
        listTileTheme: const ListTileThemeData(
          iconColor: Color(0xFF555555),
          subtitleTextStyle: TextStyle(color: Color(0xFF555555), fontSize: 13),
        ),
        dividerColor: Colors.black12,
        cardColor: Colors.white,
      );
}

class _AuthWrapper extends StatefulWidget {
  const _AuthWrapper();

  @override
  State<_AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<_AuthWrapper> {
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await context.read<AuthService>().checkAuth();
    if (mounted) setState(() => _checked = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.music_note,
                  color: Theme.of(context).colorScheme.primary, size: 56),
              const SizedBox(height: 20),
              CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary),
            ],
          ),
        ),
      );
    }
    return const _MainShell();
  }
}

class _MainShell extends StatefulWidget {
  const _MainShell();

  @override
  State<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<_MainShell> {
  int _index = 0;
  static const _pages = [SongsScreen(), PlaylistsScreen(), ListeningRoomScreen()];

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;

    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PlayerBar(),
          NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            surfaceTintColor: Colors.transparent,
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.music_note_outlined),
                selectedIcon: Icon(Icons.music_note,
                    color: Theme.of(context).colorScheme.primary),
                label: l10n.navSongs,
              ),
              NavigationDestination(
                icon: const Icon(Icons.queue_music_outlined),
                selectedIcon: Icon(Icons.queue_music,
                    color: Theme.of(context).colorScheme.primary),
                label: l10n.navPlaylists,
              ),
              NavigationDestination(
                icon: const Icon(Icons.people_alt_outlined),
                selectedIcon: Icon(Icons.people_alt,
                    color: Theme.of(context).colorScheme.primary),
                label: l10n.navLive,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
