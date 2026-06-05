import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../services/download_service.dart';
import '../services/player_service.dart';
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
    final l10n = AppL10n.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down,
              size: 32, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(l10n.nowPlaying,
            style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 13)),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: l10n.tooltipQueue,
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.queue_music),
                if (context.watch<PlayerService>().queue.isNotEmpty)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1DB954),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${context.read<PlayerService>().queue.length}',
                          style: const TextStyle(
                              fontSize: 9,
                              color: Colors.black,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const QueueScreen()),
            ),
          ),
          _DownloadButton(song: song, downloads: downloads),
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
                    color: const Color(0xFF282828),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1DB954).withValues(alpha: 0.2),
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
                            errorBuilder: (_, _, _) => _placeholder())
                        : _placeholder(),
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
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          song.artist,
                          style: const TextStyle(
                              color: Color(0xFFB3B3B3), fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.shuffle,
                      color: player.shuffleMode
                          ? const Color(0xFF1DB954)
                          : Colors.white.withValues(alpha: 0.45),
                    ),
                    onPressed: player.toggleShuffle,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Progress bar + time
              StreamBuilder<Duration>(
                stream: player.positionStream,
                builder: (_, snap) {
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
                          activeTrackColor: const Color(0xFF1DB954),
                          inactiveTrackColor: Colors.white12,
                          thumbColor: Colors.white,
                          overlayColor: Colors.white24,
                        ),
                        child: Slider(
                          value: pct,
                          onChanged: (v) => player.seek(dur * v),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_fmt(pos),
                                style: const TextStyle(
                                    color: Color(0xFFB3B3B3), fontSize: 12)),
                            Text(_fmt(dur),
                                style: const TextStyle(
                                    color: Color(0xFFB3B3B3), fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 12),

              // Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    iconSize: 36,
                    icon: Icon(Icons.skip_previous,
                        color: Colors.white.withValues(alpha: 0.8)),
                    onPressed: player.playPrevious,
                  ),
                  GestureDetector(
                    onTap: player.togglePlayPause,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1DB954),
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
                        color: Colors.white.withValues(alpha: 0.8)),
                    onPressed: player.playNext,
                  ),
                ],
              ),

              LyricsSection(song: song),

              const SizedBox(height: 36),
            ],
          ),
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
