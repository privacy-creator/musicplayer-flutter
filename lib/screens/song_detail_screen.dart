import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/song.dart';
import '../services/api_service.dart';
import '../services/download_service.dart';
import '../services/player_service.dart';
import '../widgets/lyrics_section.dart';
import 'queue_screen.dart';

class SongDetailScreen extends StatefulWidget {
  final Song song;
  const SongDetailScreen({super.key, required this.song});

  @override
  State<SongDetailScreen> createState() => _SongDetailScreenState();
}

class _SongDetailScreenState extends State<SongDetailScreen> {
  Song? _song;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final s = await context.read<ApiService>().getSong(widget.song.id);
      if (mounted) setState(() { _song = s; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _song = widget.song; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final song = _song ?? widget.song;
    final player = context.watch<PlayerService>();
    final downloads = context.watch<DownloadService>();
    final isCurrent = player.currentSong?.id == song.id;
    final l10n = AppL10n.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(song.title),
        actions: [_DownloadButton(song: song, downloads: downloads)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1DB954)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Album art
                  Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: const Color(0xFF282828),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1DB954).withValues(alpha: 0.25),
                          blurRadius: 40,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: song.imageUrl != null
                        ? Image.network(song.imageUrl!, fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _placeholder())
                        : _placeholder(),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    song.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    [
                      if (song.artist.isNotEmpty) song.artist,
                      if (song.genre.isNotEmpty) song.genre,
                      if (song.language.isNotEmpty) song.language,
                      if (song.year > 0) song.year.toString(),
                    ].join(' • '),
                    style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    song.formattedDuration,
                    style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 12),
                  ),

                  // Offline badge
                  if (downloads.isDownloaded(song.id)) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1DB954).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF1DB954), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.offline_pin, color: Color(0xFF1DB954), size: 14),
                          const SizedBox(width: 4),
                          Text(l10n.offlineBadge,
                              style: const TextStyle(color: Color(0xFF1DB954), fontSize: 12)),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),

                  // Play button
                  SizedBox(
                    width: 200,
                    height: 48,
                    child: ElevatedButton.icon(
                      icon: Icon(isCurrent && player.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow),
                      label: Text(isCurrent && player.isPlaying
                          ? l10n.btnPause
                          : l10n.btnPlay),
                      onPressed: () =>
                          context.read<PlayerService>().playSong(song, [song], 0),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1DB954),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Add to queue button
                  SizedBox(
                    width: 200,
                    height: 44,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.playlist_add, size: 20),
                      label: Text(l10n.btnAddToQueue),
                      onPressed: () {
                        context.read<PlayerService>().addToQueue(song);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.songAdded(song.title)),
                            action: SnackBarAction(
                              label: l10n.queue,
                              textColor: const Color(0xFF1DB954),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const QueueScreen()),
                              ),
                            ),
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1DB954),
                        side: const BorderSide(color: Color(0xFF1DB954)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24)),
                      ),
                    ),
                  ),

                  LyricsSection(song: song),
                ],
              ),
            ),
    );
  }

  Widget _placeholder() => const Center(
      child: Icon(Icons.music_note, color: Color(0xFF1DB954), size: 80));
}

class _DownloadButton extends StatelessWidget {
  final Song song;
  final DownloadService downloads;

  const _DownloadButton({required this.song, required this.downloads});

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;

    if (downloads.isDownloading(song.id)) {
      return Padding(
        padding: const EdgeInsets.all(14),
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            value: downloads.getProgress(song.id),
            strokeWidth: 2.5,
            color: const Color(0xFF1DB954),
          ),
        ),
      );
    }

    if (downloads.isDownloaded(song.id)) {
      return IconButton(
        tooltip: l10n.tooltipDeleteDownload,
        icon: const Icon(Icons.download_done, color: Color(0xFF1DB954)),
        onPressed: () => downloads.delete(song.id),
      );
    }

    return IconButton(
      tooltip: l10n.tooltipDownload,
      icon: const Icon(Icons.download_outlined),
      onPressed: () => downloads.download(song, context.read<ApiService>().dio),
    );
  }
}
