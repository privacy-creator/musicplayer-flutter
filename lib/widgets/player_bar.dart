import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/player_service.dart';
import '../screens/player_detail_screen.dart';

class PlayerBar extends StatelessWidget {
  const PlayerBar({super.key});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerService>();
    final song = player.currentSong;
    if (song == null) return const SizedBox.shrink();

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        border: Border(top: BorderSide(color: Color(0xFF1DB954), width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Seekable progress bar
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
                  activeTrackColor: const Color(0xFF1DB954),
                  inactiveTrackColor: Colors.white12,
                  thumbColor: Colors.white,
                  overlayColor: Colors.white24,
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
                // Thumbnail + title → taps open player detail
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
                                    errorBuilder: (_, _, _) => _thumb(),
                                  )
                                : _thumb(),
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
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                song.artist,
                                style: const TextStyle(
                                    color: Color(0xFFB3B3B3), fontSize: 11),
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
                // Controls
                IconButton(
                  icon: Icon(Icons.skip_previous,
                      color: Colors.white.withValues(alpha: 0.7)),
                  onPressed: player.playPrevious,
                ),
                _PlayPauseButton(isPlaying: player.isPlaying, onTap: player.togglePlayPause),
                IconButton(
                  icon: Icon(Icons.skip_next,
                      color: Colors.white.withValues(alpha: 0.7)),
                  onPressed: player.playNext,
                ),
                IconButton(
                  icon: Icon(
                    Icons.shuffle,
                    color: player.shuffleMode
                        ? const Color(0xFF1DB954)
                        : Colors.white.withValues(alpha: 0.45),
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

  Widget _thumb() => Container(
        color: const Color(0xFF282828),
        child: const Icon(Icons.music_note, color: Color(0xFF1DB954), size: 22),
      );
}

class _PlayPauseButton extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onTap;

  const _PlayPauseButton({required this.isPlaying, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: const BoxDecoration(
          color: Color(0xFF1DB954),
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
