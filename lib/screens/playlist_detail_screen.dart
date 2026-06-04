import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/playlist.dart';
import '../services/api_service.dart';
import '../services/player_service.dart';
import 'song_detail_screen.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final Playlist playlist;
  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  Playlist? _playlist;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final pl = await context.read<ApiService>().getPlaylist(widget.playlist.id);
      if (mounted) setState(() { _playlist = pl; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _playlist = widget.playlist; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pl = _playlist ?? widget.playlist;
    final player = context.watch<PlayerService>();
    final l10n = AppL10n.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(pl.name),
        actions: [
          if (pl.songs.isNotEmpty) ...[
            IconButton(
              tooltip: l10n.tooltipPlayAll,
              icon: const Icon(Icons.play_arrow, color: Color(0xFF1DB954)),
              onPressed: () => player.playSong(pl.songs[0], pl.songs, 0),
            ),
            IconButton(
              tooltip: l10n.tooltipShuffle,
              icon: const Icon(Icons.shuffle, color: Color(0xFF1DB954)),
              onPressed: () => player.shufflePlay(pl.songs),
            ),
          ],
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1DB954)))
          : Column(
              children: [
                // Header
                Container(
                  width: double.infinity,
                  color: const Color(0xFF1E1E1E),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (pl.description != null && pl.description!.isNotEmpty) ...[
                        Text(pl.description!,
                            style: const TextStyle(
                                color: Color(0xFFB3B3B3), fontSize: 13)),
                        const SizedBox(height: 6),
                      ],
                      Text(
                        l10n.songCount(pl.songs.length),
                        style: const TextStyle(
                            color: Color(0xFF1DB954),
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                // Song list
                Expanded(
                  child: pl.songs.isEmpty
                      ? Center(
                          child: Text(l10n.noSongsInPlaylist,
                              style: const TextStyle(color: Color(0xFFB3B3B3))))
                      : ListView.builder(
                          itemCount: pl.songs.length,
                          itemBuilder: (_, i) {
                            final song = pl.songs[i];
                            final isCurrent = player.currentSong?.id == song.id;
                            return ListTile(
                              leading: SizedBox(
                                width: 32,
                                child: isCurrent
                                    ? Icon(
                                        player.isPlaying
                                            ? Icons.volume_up
                                            : Icons.pause,
                                        color: const Color(0xFF1DB954),
                                        size: 18)
                                    : Text('${i + 1}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            color: Color(0xFFB3B3B3))),
                              ),
                              title: Text(
                                song.title,
                                style: TextStyle(
                                  color: isCurrent
                                      ? const Color(0xFF1DB954)
                                      : Colors.white,
                                  fontWeight: isCurrent
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                [
                                  if (song.genre.isNotEmpty) song.genre,
                                  song.formattedDuration,
                                ].join(' • '),
                                style: const TextStyle(
                                    color: Color(0xFFB3B3B3), fontSize: 12),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.info_outline,
                                    color: Color(0xFFB3B3B3), size: 18),
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          SongDetailScreen(song: song)),
                                ),
                              ),
                              onTap: () =>
                                  player.playSong(song, pl.songs, i),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
