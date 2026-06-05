import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../services/player_service.dart';
import '../screens/player_detail_screen.dart';

class PlayerBar extends StatefulWidget {
  const PlayerBar({super.key});

  @override
  State<PlayerBar> createState() => _PlayerBarState();
}

class _PlayerBarState extends State<PlayerBar> {
  StreamSubscription<String>? _errorSub;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _errorSub ??= context.read<PlayerService>().errorStream.listen((errKey) {
      if (!mounted) return;
      final l10n = AppL10n.of(context)!;
      final message = errKey == 'errorCannotLoad'
          ? l10n.errorCannotLoad
          : errKey;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: const Color(0xFFB00020),
          duration: const Duration(seconds: 3),
        ),
      );
    });
  }

  @override
  void dispose() {
    _errorSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerService>();
    final song = player.currentSong;
    if (song == null) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.primary, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StreamBuilder<Duration>(
            stream: player.positionStream,
            builder: (_, snap) {
              final pos = snap.data ?? Duration.zero;
              final dur = player.duration ?? Duration.zero;
              final pct = dur.inMilliseconds > 0
                  ? (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0)
                  : 0.0;
              return SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                  activeTrackColor: colorScheme.primary,
                  inactiveTrackColor: colorScheme.onSurface.withValues(alpha: 0.12),
                  thumbColor: colorScheme.onSurface,
                  overlayColor: colorScheme.onSurface.withValues(alpha: 0.12),
                ),
                child: Slider(
                  value: pct,
                  onChanged: (v) => player.seek(dur * v),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 4, 8),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PlayerDetailScreen()),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: SizedBox(
                            width: 42,
                            height: 42,
                            child: song.imageUrl != null
                                ? Image.network(
                                    song.imageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => _thumb(colorScheme),
                                  )
                                : _thumb(colorScheme),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                song.title,
                                style: TextStyle(
                                    color: colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                song.artist,
                                style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.skip_previous,
                      color: colorScheme.onSurface.withValues(alpha: 0.7)),
                  onPressed: player.playPrevious,
                ),
                _PlayPauseButton(
                  isPlaying: player.isPlaying,
                  onTap: player.togglePlayPause,
                  colorScheme: colorScheme,
                ),
                IconButton(
                  icon: Icon(Icons.skip_next,
                      color: colorScheme.onSurface.withValues(alpha: 0.7)),
                  onPressed: player.playNext,
                ),
                IconButton(
                  icon: Icon(
                    Icons.shuffle,
                    color: player.shuffleMode
                        ? colorScheme.primary
                        : colorScheme.onSurface.withValues(alpha: 0.45),
                    size: 20,
                  ),
                  onPressed: player.toggleShuffle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _thumb(ColorScheme cs) => Container(
        color: cs.surfaceContainerHighest,
        child: Icon(Icons.music_note, color: cs.primary, size: 22),
      );
}

class _PlayPauseButton extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _PlayPauseButton({
    required this.isPlaying,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: colorScheme.primary,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isPlaying ? Icons.pause : Icons.play_arrow,
          color: Colors.black,
          size: 22,
        ),
      ),
    );
  }
}
