import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/song.dart';
import '../services/api_service.dart';
import '../services/player_service.dart';
import '../widgets/global_app_bar_actions.dart';
import 'song_detail_screen.dart';

class SongsScreen extends StatefulWidget {
  final Future<bool> Function()? connectivityChecker;
  const SongsScreen({super.key, this.connectivityChecker});

  @override
  State<SongsScreen> createState() => _SongsScreenState();
}

class _SongsScreenState extends State<SongsScreen> {
  List<Song> _songs = [];
  bool _loading = true;
  bool _offline = false;
  final _searchCtrl = TextEditingController();
  String _language = '';
  String _genre = '';

  static const _languages = [
    '', 'English', 'Dutch', 'Spanish', 'Italian', 'German', 'French'
  ];
  List<String> _genres = const [''];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<bool> _hasInternet() async {
    if (widget.connectivityChecker != null) {
      return widget.connectivityChecker!();
    }
    try {
      final results = await Connectivity().checkConnectivity();
      return results.isNotEmpty &&
          results.any((r) => r != ConnectivityResult.none);
    } catch (_) {
      return false;
    }
  }

  Future<void> _load() async {
    setState(() { _loading = true; _offline = false; });
    final apiService = context.read<ApiService>();
    final online = await _hasInternet();
    try {
      final songs = await apiService.getSongs(
        search: _searchCtrl.text,
        language: _language,
        genre: _genre,
      );
      if (!mounted) return;
      final genreSet = songs
          .map((s) => s.genre)
          .where((g) => g.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
      setState(() {
        _songs = songs;
        _genres = ['', ...genreSet];
        _loading = false;
        _offline = !online;
      });
    } catch (_) {
      if (mounted) setState(() { _loading = false; _offline = true; });
    }
  }

  Future<void> _refreshOnline() async {
    final online = await _hasInternet();
    if (!online) {
      if (mounted) {
        final l10n = AppL10n.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.noInternet),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navSongs),
        actions: [
          const GlobalAppBarActions(),
          IconButton(
            tooltip: l10n.tooltipRefresh,
            icon: const Icon(Icons.refresh),
            onPressed: _refreshOnline,
          ),
          IconButton(
            tooltip: l10n.tooltipShuffleAll,
            icon: Icon(Icons.shuffle, color: colorScheme.primary),
            onPressed: _songs.isEmpty
                ? null
                : () => context.read<PlayerService>().shufflePlay(_songs),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_offline)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: const Color(0xFF7B5300),
              child: Row(
                children: [
                  const Icon(Icons.wifi_off, color: Colors.white, size: 14),
                  const SizedBox(width: 6),
                  Text(l10n.offlineBanner,
                      style: const TextStyle(color: Colors.white, fontSize: 12)),
                ],
              ),
            ),
          _Filters(
            searchCtrl: _searchCtrl,
            language: _language,
            languages: _languages,
            genre: _genre,
            genres: _genres,
            onSearch: (_) => _load(),
            onLanguage: (v) { setState(() => _language = v ?? ''); _load(); },
            onGenre: (v) { setState(() => _genre = v ?? ''); _load(); },
          ),
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
                : _songs.isEmpty
                    ? Center(
                        child: Text(l10n.noSongsFound,
                            style: TextStyle(color: colorScheme.onSurfaceVariant)))
                    : GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.72,
                        ),
                        itemCount: _songs.length,
                        itemBuilder: (_, i) =>
                            _SongCard(song: _songs[i], playlist: _songs, index: i),
                      ),
          ),
        ],
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  final TextEditingController searchCtrl;
  final String language;
  final List<String> languages;
  final String genre;
  final List<String> genres;
  final ValueChanged<String> onSearch;
  final ValueChanged<String?> onLanguage;
  final ValueChanged<String?> onGenre;

  const _Filters({
    required this.searchCtrl,
    required this.language,
    required this.languages,
    required this.genre,
    required this.genres,
    required this.onSearch,
    required this.onLanguage,
    required this.onGenre,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Column(
        children: [
          TextField(
            controller: searchCtrl,
            onChanged: onSearch,
            style: TextStyle(color: colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: l10n.searchHint,
              hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
              prefixIcon: Icon(Icons.search, color: colorScheme.primary, size: 20),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _Drop(
                  label: l10n.filterLanguage,
                  allLabel: l10n.allLanguage,
                  value: language,
                  items: languages,
                  onChanged: onLanguage,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Drop(
                  label: l10n.filterGenre,
                  allLabel: l10n.allGenre,
                  value: genre,
                  items: genres,
                  onChanged: onGenre,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Drop extends StatelessWidget {
  final String label;
  final String allLabel;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _Drop({
    required this.label,
    required this.allLabel,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: colorScheme.surfaceContainerHighest,
          style: TextStyle(color: colorScheme.onSurface, fontSize: 13),
          hint: Text(label,
              style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13)),
          isDense: true,
          items: items
              .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(e.isEmpty ? allLabel : e),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _SongCard extends StatelessWidget {
  final Song song;
  final List<Song> playlist;
  final int index;

  const _SongCard({required this.song, required this.playlist, required this.index});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerService>();
    final isCurrent = player.currentSong?.id == song.id;
    final l10n = AppL10n.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => context.read<PlayerService>().playSong(song, playlist, index),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: isCurrent
              ? Border.all(color: colorScheme.primary, width: 1.5)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    song.imageUrl != null
                        ? Image.network(song.imageUrl!, fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _placeholder(colorScheme))
                        : _placeholder(colorScheme),
                    if (isCurrent)
                      Container(
                        color: Colors.black45,
                        child: Icon(
                          player.isPlaying ? Icons.pause_circle : Icons.play_circle,
                          color: colorScheme.primary,
                          size: 48,
                        ),
                      ),
                    Positioned(
                      bottom: 6,
                      left: 6,
                      child: GestureDetector(
                        onTap: () {
                          context.read<PlayerService>().addToQueue(song);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.addedToQueue(song.title)),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.playlist_add,
                              color: Colors.white70, size: 15),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => SongDetailScreen(song: song)),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.info_outline,
                              color: Colors.white70, size: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    style: TextStyle(
                      color: isCurrent ? colorScheme.primary : colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${song.genre} • ${song.year}',
                    style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(ColorScheme cs) => Container(
        color: cs.surfaceContainerHighest,
        child: Icon(Icons.music_note, color: cs.primary, size: 48),
      );
}
