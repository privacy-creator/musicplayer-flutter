import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../services/download_service.dart';
import '../services/player_service.dart';
import '../services/streaming_service.dart';
import '../models/song.dart';
import '../widgets/lyrics_section.dart';
import 'queue_screen.dart';

class PlayerDetailScreen extends StatelessWidget {
  const PlayerDetailScreen({super.key});

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerService>();
    final song = player.currentSong;
    if (song == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => Navigator.of(context).pop());
      return const SizedBox.shrink();
    }

    final downloads = context.watch<DownloadService>();
    final streaming = context.watch<StreamingService>();
    final locked = streaming.inRoom && !streaming.isHost;
    final l10n = AppL10n.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.keyboard_arrow_down,
              size: 32, color: colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(l10n.nowPlaying,
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: colorScheme.onSurface),
            iconSize: 28,
            onPressed: () => _showPlayerMenu(
                context, song, downloads, player, l10n, colorScheme),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 16),

              // Album art
              Center(
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 300, maxHeight: 300),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: colorScheme.surfaceContainerHighest,
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.2),
                        blurRadius: 60,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: song.imageUrl != null
                        ? Image.network(song.imageUrl!, fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _placeholder(colorScheme))
                        : _placeholder(colorScheme),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Title + artist + shuffle
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.title,
                          style: TextStyle(
                              color: colorScheme.onSurface,
                              fontSize: 22,
                              fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          song.artist,
                          style: TextStyle(
                              color: colorScheme.onSurfaceVariant, fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.shuffle,
                      color: locked
                          ? colorScheme.onSurface.withValues(alpha: 0.2)
                          : player.shuffleMode
                              ? colorScheme.primary
                              : colorScheme.onSurface.withValues(alpha: 0.45),
                    ),
                    onPressed: locked ? null : player.toggleShuffle,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Progress bar + time
              StreamBuilder<Duration>(
                stream: player.positionStream,
                builder: (ctx, snap) {
                  final pos = snap.data ?? Duration.zero;
                  final dur = player.duration ?? Duration.zero;
                  final pct = dur.inMilliseconds > 0
                      ? (pos.inMilliseconds / dur.inMilliseconds)
                          .clamp(0.0, 1.0)
                      : 0.0;
                  return Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4,
                          thumbShape:
                              const RoundSliderThumbShape(enabledThumbRadius: 7),
                          overlayShape:
                              const RoundSliderOverlayShape(overlayRadius: 16),
                          activeTrackColor: colorScheme.primary,
                          inactiveTrackColor:
                              colorScheme.onSurface.withValues(alpha: 0.12),
                          thumbColor: colorScheme.onSurface,
                          overlayColor:
                              colorScheme.onSurface.withValues(alpha: 0.12),
                        ),
                        child: Slider(
                          value: pct,
                          onChanged: locked ? null : (v) => player.seek(dur * v),
                          onChangeEnd: locked
                              ? null
                              : (v) {
                                  final s = ctx.read<StreamingService>();
                                  if (s.isHost) {
                                    s.updateState(
                                      trackId: player.currentSong?.id,
                                      position:
                                          (dur * v).inMilliseconds / 1000.0,
                                      isPlaying: player.isPlaying,
                                    );
                                  }
                                },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_fmt(pos),
                                style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: 12)),
                            Text(_fmt(dur),
                                style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 12),

              // Controls
              Opacity(
                opacity: locked ? 0.35 : 1.0,
                child: IgnorePointer(
                  ignoring: locked,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        iconSize: 36,
                        icon: Icon(Icons.skip_previous,
                            color: colorScheme.onSurface.withValues(alpha: 0.8)),
                        onPressed: player.playPrevious,
                      ),
                      GestureDetector(
                        onTap: player.togglePlayPause,
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            player.isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.black,
                            size: 36,
                          ),
                        ),
                      ),
                      IconButton(
                        iconSize: 36,
                        icon: Icon(Icons.skip_next,
                            color: colorScheme.onSurface.withValues(alpha: 0.8)),
                        onPressed: player.playNext,
                      ),
                    ],
                  ),
                ),
              ),

              LyricsSection(song: song),

              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder(ColorScheme cs) => Center(
      child: Icon(Icons.music_note, color: cs.primary, size: 80));
}

void _showPlayerMenu(
  BuildContext context,
  Song song,
  DownloadService downloads,
  PlayerService player,
  AppL10n l10n,
  ColorScheme colorScheme,
) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) => _PlayerMenuSheet(
      song: song,
      downloads: downloads,
      player: player,
      l10n: l10n,
      colorScheme: colorScheme,
      onQueue: () {
        Navigator.pop(sheetCtx);
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const QueueScreen()));
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

class _PlayerMenuSheet extends StatelessWidget {
  final Song song;
  final DownloadService downloads;
  final PlayerService player;
  final AppL10n l10n;
  final ColorScheme colorScheme;
  final VoidCallback onQueue;
  final VoidCallback onDownload;
  final VoidCallback onDeleteDownload;

  const _PlayerMenuSheet({
    required this.song,
    required this.downloads,
    required this.player,
    required this.l10n,
    required this.colorScheme,
    required this.onQueue,
    required this.onDownload,
    required this.onDeleteDownload,
  });

  @override
  Widget build(BuildContext context) {
    final isDownloading = downloads.isDownloading(song.id);
    final isDownloaded = downloads.isDownloaded(song.id);
    final queueCount = player.queue.length;

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
              height: 1, color: colorScheme.outline.withValues(alpha: 0.2)),
          _PlayerSheetItem(
            icon: Icons.queue_music_outlined,
            label: queueCount > 0
                ? '${l10n.tooltipQueue} ($queueCount)'
                : l10n.tooltipQueue,
            colorScheme: colorScheme,
            onTap: onQueue,
          ),
          if (isDownloading)
            _PlayerSheetItem(
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
            _PlayerSheetItem(
              icon: Icons.download_done,
              label: l10n.tooltipDeleteDownload,
              colorScheme: colorScheme,
              iconColor: colorScheme.primary,
              onTap: onDeleteDownload,
            )
          else
            _PlayerSheetItem(
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

class _PlayerSheetItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme colorScheme;
  final VoidCallback onTap;
  final bool enabled;
  final Color? iconColor;
  final Widget? trailing;

  const _PlayerSheetItem({
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
            ?trailing,
          ],
        ),
      ),
    );
  }
}
