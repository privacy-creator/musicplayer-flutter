import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/song.dart';
import '../services/player_service.dart';

class QueueScreen extends StatelessWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerService>();
    final queue = player.queue;
    final upcoming = player.upcomingInPlaylist;
    final current = player.currentSong;
    final l10n = AppL10n.of(context)!;

    final isEmpty = current == null && queue.isEmpty && upcoming.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.queue),
        actions: [
          if (queue.isNotEmpty)
            TextButton(
              onPressed: () => context.read<PlayerService>().clearQueue(),
              child: Text(l10n.clearQueue,
                  style: const TextStyle(color: Color(0xFF1DB954))),
            ),
        ],
      ),
      body: isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.queue_music, color: Color(0xFF3A3A3A), size: 64),
                  const SizedBox(height: 16),
                  Text(l10n.emptyQueue,
                      style: const TextStyle(color: Color(0xFFB3B3B3))),
                ],
              ),
            )
          : ListView(
              children: [
                if (current != null) ...[
                  _SectionHeader(l10n.sectionNowPlaying),
                  _QueueTile(song: current, isCurrent: true),
                ],
                if (queue.isNotEmpty) ...[
                  _SectionHeader(l10n.sectionQueue(queue.length)),
                  ...queue.asMap().entries.map(
                        (e) => _QueueTile(
                          song: e.value,
                          onRemove: () =>
                              context.read<PlayerService>().removeFromQueue(e.key),
                        ),
                      ),
                ],
                if (upcoming.isNotEmpty) ...[
                  _SectionHeader(l10n.sectionUpNext),
                  ...upcoming.take(15).map((s) => _QueueTile(song: s)),
                ],
                const SizedBox(height: 16),
              ],
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFFB3B3B3),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _QueueTile extends StatelessWidget {
  final Song song;
  final bool isCurrent;
  final VoidCallback? onRemove;

  const _QueueTile({
    required this.song,
    this.isCurrent = false,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: 44,
          height: 44,
          child: song.imageUrl != null
              ? Image.network(
                  song.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _thumb(),
                )
              : _thumb(),
        ),
      ),
      title: Text(
        song.title,
        style: TextStyle(
          color: isCurrent ? const Color(0xFF1DB954) : Colors.white,
          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
          fontSize: 14,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        song.artist,
        style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 12),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: onRemove != null
          ? IconButton(
              icon: const Icon(Icons.close, color: Color(0xFFB3B3B3), size: 18),
              onPressed: onRemove,
            )
          : isCurrent
              ? const Icon(Icons.volume_up, color: Color(0xFF1DB954), size: 18)
              : null,
    );
  }

  Widget _thumb() => Container(
        color: const Color(0xFF282828),
        child: const Icon(Icons.music_note, color: Color(0xFF1DB954), size: 22),
      );
}
