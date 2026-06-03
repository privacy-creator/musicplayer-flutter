import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../services/api_service.dart';
import '../services/player_service.dart';
import 'song_detail_screen.dart';

class SongsScreen extends StatefulWidget {
  const SongsScreen({super.key});

  @override
  State<SongsScreen> createState() => _SongsScreenState();
}

class _SongsScreenState extends State<SongsScreen> {
  List<Song> _songs = [];
  bool _loading = true;
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

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final songs = await context.read<ApiService>().getSongs(
        search: _searchCtrl.text,
        language: _language,
        genre: _genre,
      );
      if (!mounted) return;
      final genreSet = songs.map((s) => s.genre).where((g) => g.isNotEmpty).toSet().toList()..sort();
      setState(() {
        _songs = songs;
        _genres = ['', ...genreSet];
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Songs'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
          IconButton(
            tooltip: 'Shuffle all',
            icon: const Icon(Icons.shuffle, color: Color(0xFF1DB954)),
            onPressed: _songs.isEmpty
                ? null
                : () => context.read<PlayerService>().shufflePlay(_songs),
          ),
        ],
      ),
      body: Column(
        children: [
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
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1DB954)))
                : _songs.isEmpty
                    ? const Center(
                        child: Text('No songs found',
                            style: TextStyle(color: Color(0xFFB3B3B3))))
                    : GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
    return Container(
      color: const Color(0xFF1E1E1E),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Column(
        children: [
          TextField(
            controller: searchCtrl,
            onChanged: onSearch,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search songs...',
              hintStyle: const TextStyle(color: Color(0xFFB3B3B3)),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF1DB954), size: 20),
              filled: true,
              fillColor: const Color(0xFF282828),
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
                  label: 'Language',
                  value: language,
                  items: languages,
                  onChanged: onLanguage,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Drop(
                  label: 'Genre',
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
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _Drop({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF282828),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: const Color(0xFF282828),
          style: const TextStyle(color: Colors.white, fontSize: 13),
          hint: Text(label, style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 13)),
          isDense: true,
          items: items
              .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(e.isEmpty ? 'All $label' : e),
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

    return GestureDetector(
      onTap: () => context.read<PlayerService>().playSong(song, playlist, index),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: isCurrent
              ? Border.all(color: const Color(0xFF1DB954), width: 1.5)
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
                            errorBuilder: (_, _, _) => _placeholder())
                        : _placeholder(),
                    // Playing indicator
                    if (isCurrent)
                      Container(
                        color: Colors.black45,
                        child: Icon(
                          player.isPlaying ? Icons.pause_circle : Icons.play_circle,
                          color: const Color(0xFF1DB954),
                          size: 48,
                        ),
                      ),
                    // Info button
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
                      color: isCurrent ? const Color(0xFF1DB954) : Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${song.genre} • ${song.year}',
                    style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 11),
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

  Widget _placeholder() => Container(
        color: const Color(0xFF282828),
        child: const Icon(Icons.music_note, color: Color(0xFF1DB954), size: 48),
      );
}
