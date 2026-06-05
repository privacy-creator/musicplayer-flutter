import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/player_service.dart';
import '../screens/player_detail_screen.dart';

/// Compact now-playing card shown at the top of the home screen while a song
/// is active. Tapping the card opens the full player. Hidden when idle.
class NowPlayingCard extends StatelessWidget {
  const NowPlayingCard({super.key});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerService>();
    final song = player.currentSong;
    if (song == null) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PlayerDetailScreen()),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.primary, width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 52,
                      height: 52,
                      child: song.imageUrl != null
                          ? Image.network(
                              song.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => _thumb(colorScheme),
                            )
                          : _thumb(colorScheme),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.title,
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          song.artist,
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: const Key('np_prev'),
                    icon: Icon(Icons.skip_previous,
                        color: colorScheme.onSurface.withValues(alpha: 0.7)),
                    onPressed: player.playPrevious,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                  _PlayPauseBtn(
                    isPlaying: player.isPlaying,
                    onTap: player.togglePlayPause,
                    colorScheme: colorScheme,
                  ),
                  IconButton(
                    key: const Key('np_next'),
                    icon: Icon(Icons.skip_next,
                        color: colorScheme.onSurface.withValues(alpha: 0.7)),
                    onPressed: player.playNext,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                ],
              ),
            ),
            StreamBuilder<Duration>(
              stream: player.positionStream,
              builder: (_, snap) {
                final pos = snap.data ?? Duration.zero;
                final dur = player.duration ?? Duration.zero;
                final pct = dur.inMilliseconds > 0
                    ? (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0)
                    : 0.0;
                return ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(14)),
                  child: LinearProgressIndicator(
                    key: const Key('np_progress'),
                    value: pct,
                    minHeight: 3,
                    color: colorScheme.primary,
                    backgroundColor:
                        colorScheme.onSurface.withValues(alpha: 0.08),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumb(ColorScheme cs) => Container(
        color: cs.surface,
        child: Icon(Icons.music_note, color: cs.primary, size: 28),
      );
}

class _PlayPauseBtn extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _PlayPauseBtn({
    required this.isPlaying,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        key: const Key('np_play_pause'),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: colorScheme.primary,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isPlaying ? Icons.pause : Icons.play_arrow,
          color: Colors.black,
          size: 20,
        ),
      ),
    );
  }
}
