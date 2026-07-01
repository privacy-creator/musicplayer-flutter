import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../constants.dart';
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(song.title),
        actions: [
          Builder(
            builder: (ctx) => PopupMenuButton<String>(
              iconSize: 28,
              icon: const Icon(Icons.more_vert),
              onSelected: (value) async {
                if (value == 'share') {
                  final url = '${AppConstants.websiteUrl}/song/${song.id}';
                  final box = ctx.findRenderObject() as RenderBox?;
                  await Share.share(
                    url,
                    subject: song.title,
                    sharePositionOrigin: box != null
                        ? box.localToGlobal(Offset.zero) & box.size
                        : null,
                  );
                } else if (value == 'download') {
                  downloads.download(song, context.read<ApiService>().dio);
                } else if (value == 'delete_download') {
                  downloads.delete(song.id);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'share',
                  child: Row(children: [
                    const Icon(Icons.share, size: 20),
                    const SizedBox(width: 12),
                    Text(l10n.tooltipShare),
                  ]),
                ),
                if (downloads.isDownloading(song.id))
                  PopupMenuItem(
                    enabled: false,
                    child: Row(children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          value: downloads.getProgress(song.id),
                          strokeWidth: 2.5,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(l10n.tooltipDownload),
                    ]),
                  )
                else if (downloads.isDownloaded(song.id))
                  PopupMenuItem(
                    value: 'delete_download',
                    child: Row(children: [
                      Icon(Icons.download_done, size: 20, color: colorScheme.primary),
                      const SizedBox(width: 12),
                      Text(l10n.tooltipDeleteDownload),
                    ]),
                  )
                else
                  PopupMenuItem(
                    value: 'download',
                    child: Row(children: [
                      const Icon(Icons.download_outlined, size: 20),
                      const SizedBox(width: 12),
                      Text(l10n.tooltipDownload),
                    ]),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
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
                      color: colorScheme.surfaceContainerHighest,
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.25),
                          blurRadius: 40,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: song.imageUrl != null
                        ? Image.network(song.imageUrl!, fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _placeholder(colorScheme))
                        : _placeholder(colorScheme),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    song.title,
                    style: TextStyle(
                        color: colorScheme.onSurface,
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
                    style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    song.formattedDuration,
                    style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
                  ),

                  // Offline badge
                  if (downloads.isDownloaded(song.id)) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: colorScheme.primary, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.offline_pin, color: colorScheme.primary, size: 14),
                          const SizedBox(width: 4),
                          Text(l10n.offlineBadge,
                              style: TextStyle(color: colorScheme.primary, fontSize: 12)),
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
                        backgroundColor: colorScheme.primary,
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
                              textColor: colorScheme.primary,
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
                        foregroundColor: colorScheme.primary,
                        side: BorderSide(color: colorScheme.primary),
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

  Widget _placeholder(ColorScheme cs) => Center(
      child: Icon(Icons.music_note, color: cs.primary, size: 80));
}
