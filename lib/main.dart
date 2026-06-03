import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/audio_handler.dart';
import 'services/player_service.dart';
import 'screens/login_screen.dart';
import 'screens/songs_screen.dart';
import 'screens/playlists_screen.dart';
import 'widgets/player_bar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final handler = await AudioService.init(
    builder: () => MusicAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.music_player_flutter.audio',
      androidNotificationChannelName: 'Muziek',
      androidNotificationIcon: 'mipmap/ic_launcher',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      notificationColor: Color(0xFF1DB954),
    ),
  );
  runApp(MusicPlayerApp(audioHandler: handler));
}

class MusicPlayerApp extends StatelessWidget {
  final MusicAudioHandler audioHandler;
  const MusicPlayerApp({super.key, required this.audioHandler});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>(create: (_) => ApiService()),
        ChangeNotifierProxyProvider<ApiService, AuthService>(
          create: (ctx) => AuthService(ctx.read<ApiService>()),
          update: (_, api, prev) => prev ?? AuthService(api),
        ),
        ChangeNotifierProvider<PlayerService>(
          create: (_) => PlayerService(handler: audioHandler),
        ),
      ],
      child: MaterialApp(
        title: 'Music Player',
        debugShowCheckedModeBanner: false,
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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    return Scaffold(
      body: Stack(
        children: [
          _pages[_index],
          // Logout button top-right
          Positioned(
            top: 0,
            right: 0,
            child: SafeArea(
              child: auth.isAuthenticated
                  ? IconButton(
                      icon: const Icon(Icons.logout,
                          color: Color(0xFFB3B3B3), size: 20),
                      tooltip: 'Admin uitloggen',
                      onPressed: () => context.read<AuthService>().logout(),
                    )
                  : IconButton(
                      icon: const Icon(Icons.admin_panel_settings_outlined,
                          color: Color(0xFF3A3A3A), size: 20),
                      tooltip: 'Admin login',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LoginScreen()),
                      ),
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
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.music_note_outlined),
                selectedIcon: Icon(Icons.music_note, color: Color(0xFF1DB954)),
                label: 'Songs',
              ),
              NavigationDestination(
                icon: Icon(Icons.queue_music_outlined),
                selectedIcon:
                    Icon(Icons.queue_music, color: Color(0xFF1DB954)),
                label: 'Playlists',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
