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
          IconButton(
            icon: const Icon(Icons.more_vert),
            iconSize: 28,
            onPressed: () => _showSongDetailMenu(
                context, song, downloads, l10n, colorScheme),
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

void _showSongDetailMenu(
  BuildContext context,
  Song song,
  DownloadService downloads,
  AppL10n l10n,
  ColorScheme colorScheme,
) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) => _SongDetailMenuSheet(
      song: song,
      downloads: downloads,
      l10n: l10n,
      colorScheme: colorScheme,
      onShare: () async {
        Navigator.pop(sheetCtx);
        final url = '${AppConstants.websiteUrl}/song/${song.id}';
        final box = context.findRenderObject() as RenderBox?;
        await Share.share(
          url,
          subject: song.title,
          sharePositionOrigin:
              box != null ? box.localToGlobal(Offset.zero) & box.size : null,
        );
      },
      onDownload: () {
        Navigator.pop(sheetCtx);
        downloads.download(song, context.read<ApiService>().dio);
      },
      onDeleteDownload: () {
        Navigator.pop(sheetCtx);
        downloads.delete(song.id);
      },
    ),
  );
}

class _SongDetailMenuSheet extends StatelessWidget {
  final Song song;
  final DownloadService downloads;
  final dynamic l10n;
  final ColorScheme colorScheme;
  final VoidCallback onShare;
  final VoidCallback onDownload;
  final VoidCallback onDeleteDownload;

  const _SongDetailMenuSheet({
    required this.song,
    required this.downloads,
    required this.l10n,
    required this.colorScheme,
    required this.onShare,
    required this.onDownload,
    required this.onDeleteDownload,
  });

  @override
  Widget build(BuildContext context) {
    final isDownloading = downloads.isDownloading(song.id);
    final isDownloaded = downloads.isDownloaded(song.id);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: song.imageUrl != null
                      ? Image.network(
                          song.imageUrl!,
                          width: 54,
                          height: 54,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _thumb(),
                        )
                      : _thumb(),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        song.artist,
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(
              height: 1,
              color: colorScheme.outline.withValues(alpha: 0.2)),
          _DetailSheetItem(
            icon: Icons.share_outlined,
            label: l10n.tooltipShare,
            colorScheme: colorScheme,
            onTap: onShare,
          ),
          if (isDownloading)
            _DetailSheetItem(
              icon: Icons.downloading_outlined,
              label: l10n.tooltipDownload,
              colorScheme: colorScheme,
              enabled: false,
              trailing: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  value: downloads.getProgress(song.id),
                  strokeWidth: 2,
                  color: colorScheme.primary,
                ),
              ),
              onTap: () {},
            )
          else if (isDownloaded)
            _DetailSheetItem(
              icon: Icons.download_done,
              label: l10n.tooltipDeleteDownload,
              colorScheme: colorScheme,
              iconColor: colorScheme.primary,
              onTap: onDeleteDownload,
            )
          else
            _DetailSheetItem(
              icon: Icons.download_outlined,
              label: l10n.tooltipDownload,
              colorScheme: colorScheme,
              onTap: onDownload,
            ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
        ],
      ),
    );
  }

  Widget _thumb() => Container(
        width: 54,
        height: 54,
        color: colorScheme.surfaceContainerHighest,
        child: Icon(Icons.music_note, color: colorScheme.primary, size: 28),
      );
}

class _DetailSheetItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme colorScheme;
  final VoidCallback onTap;
  final bool enabled;
  final Color? iconColor;
  final Widget? trailing;

  const _DetailSheetItem({
    required this.icon,
    required this.label,
    required this.colorScheme,
    required this.onTap,
    this.enabled = true,
    this.iconColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final color = enabled
        ? colorScheme.onSurface
        : colorScheme.onSurface.withValues(alpha: 0.4);
    return InkWell(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? color, size: 22),
            const SizedBox(width: 18),
            Expanded(
              child: Text(label,
                  style: TextStyle(color: color, fontSize: 16)),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
