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
import 'screens/login_screen.dart';
import 'screens/songs_screen.dart';
import 'screens/playlists_screen.dart';
import 'widgets/player_bar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Permission.notification.request();

  final downloadService = DownloadService();
  await downloadService.init();

  final prefs = await SharedPreferences.getInstance();
  final languageService = LanguageService(prefs);

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
  ));
}

class MusicPlayerApp extends StatelessWidget {
  final MusicAudioHandler audioHandler;
  final DownloadService downloadService;
  final LanguageService languageService;

  const MusicPlayerApp({
    super.key,
    required this.audioHandler,
    required this.downloadService,
    required this.languageService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LanguageService>.value(value: languageService),
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
      ],
      child: Consumer<LanguageService>(
        builder: (_, lang, __) => MaterialApp(
          title: 'Music Player',
          debugShowCheckedModeBanner: false,
          locale: lang.locale,
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          theme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF121212),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF1DB954),
              secondary: Color(0xFF1ED760),
              surface: Color(0xFF1E1E1E),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1E1E1E),
              foregroundColor: Colors.white,
              elevation: 0,
              titleTextStyle: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            navigationBarTheme: const NavigationBarThemeData(
              backgroundColor: Color(0xFF1E1E1E),
              indicatorColor: Color(0x221DB954),
            ),
          ),
          home: const _AuthWrapper(),
        ),
      ),
    );
  }
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
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.music_note, color: Color(0xFF1DB954), size: 56),
              SizedBox(height: 20),
              CircularProgressIndicator(color: Color(0xFF1DB954)),
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
  static const _pages = [SongsScreen(), PlaylistsScreen()];

  void _showLanguagePicker(BuildContext context) {
    final lang = context.read<LanguageService>();
    final l10n = AppL10n.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Text(
                  l10n.languagePicker,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _LangOption(
                flag: '🇳🇱',
                label: 'Nederlands',
                code: 'nl',
                current: lang.locale.languageCode,
                onTap: () {
                  lang.setLocale(const Locale('nl'));
                  Navigator.pop(context);
                },
              ),
              _LangOption(
                flag: '🇬🇧',
                label: 'English',
                code: 'en',
                current: lang.locale.languageCode,
                onTap: () {
                  lang.setLocale(const Locale('en'));
                  Navigator.pop(context);
                },
              ),
              _LangOption(
                flag: '🇪🇸',
                label: 'Español',
                code: 'es',
                current: lang.locale.languageCode,
                onTap: () {
                  lang.setLocale(const Locale('es'));
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final l10n = AppL10n.of(context)!;

    return Scaffold(
      body: Stack(
        children: [
          _pages[_index],
          Positioned(
            top: 0,
            right: 0,
            child: SafeArea(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.language,
                        color: Color(0xFFB3B3B3), size: 20),
                    tooltip: l10n.languagePicker,
                    onPressed: () => _showLanguagePicker(context),
                  ),
                  auth.isAuthenticated
                      ? IconButton(
                          icon: const Icon(Icons.logout,
                              color: Color(0xFFB3B3B3), size: 20),
                          tooltip: l10n.tooltipAdminLogout,
                          onPressed: () => context.read<AuthService>().logout(),
                        )
                      : IconButton(
                          icon: const Icon(Icons.admin_panel_settings_outlined,
                              color: Color(0xFF3A3A3A), size: 20),
                          tooltip: l10n.tooltipAdminLogin,
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const LoginScreen()),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PlayerBar(),
          NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            backgroundColor: const Color(0xFF1E1E1E),
            surfaceTintColor: Colors.transparent,
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.music_note_outlined),
                selectedIcon:
                    const Icon(Icons.music_note, color: Color(0xFF1DB954)),
                label: l10n.navSongs,
              ),
              NavigationDestination(
                icon: const Icon(Icons.queue_music_outlined),
                selectedIcon:
                    const Icon(Icons.queue_music, color: Color(0xFF1DB954)),
                label: l10n.navPlaylists,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LangOption extends StatelessWidget {
  final String flag;
  final String label;
  final String code;
  final String current;
  final VoidCallback onTap;

  const _LangOption({
    required this.flag,
    required this.label,
    required this.code,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = code == current;
    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 24)),
      title: Text(
        label,
        style: TextStyle(
          color: isActive ? const Color(0xFF1DB954) : Colors.white,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isActive
          ? const Icon(Icons.check, color: Color(0xFF1DB954), size: 18)
          : null,
      onTap: onTap,
    );
  }
}
