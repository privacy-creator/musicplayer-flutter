import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/song.dart';
import '../services/api_service.dart';
import '../services/download_service.dart';
import '../services/player_service.dart';
import '../widgets/like_button.dart';

/// Plain song list with play-all, shuffle and download-all actions.
class SongListScreen extends StatelessWidget {
  final String title;
  final List<Song> songs;
  final String emptyText;
  final String? description;

  const SongListScreen({
    super.key,
    required this.title,
    required this.songs,
    required this.emptyText,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerService>();
    final downloads = context.watch<DownloadService>();
    final l10n = AppL10n.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final allDownloaded =
        songs.isNotEmpty && songs.every((s) => downloads.isDownloaded(s.id));
    final downloading = songs.any((s) => downloads.isDownloading(s.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (songs.isNotEmpty) ...[
            IconButton(
              tooltip: allDownloaded ? l10n.downloadsHeader : l10n.downloadAll,
              icon: downloading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: colorScheme.primary),
                    )
                  : Icon(
                      allDownloaded
                          ? Icons.download_done
                          : Icons.download_for_offline_outlined,
                      color: allDownloaded ? colorScheme.primary : null,
                    ),
              onPressed: allDownloaded || downloading
                  ? null
                  : () {
                      final api = context.read<ApiService>();
                      unawaited(context
                          .read<DownloadService>()
                          .downloadAll(songs, api.dio));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.downloadingActive)),
                      );
                    },
            ),
            IconButton(
              tooltip: l10n.tooltipPlayAll,
              icon: Icon(Icons.play_arrow, color: colorScheme.primary),
              onPressed: () => player.playSong(songs[0], songs, 0),
            ),
            IconButton(
              tooltip: l10n.tooltipShuffle,
              icon: Icon(Icons.shuffle, color: colorScheme.primary),
              onPressed: () => player.shufflePlay(songs),
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: colorScheme.surface,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (description != null) ...[
                  Text(description!,
                      style: TextStyle(
                          color: colorScheme.onSurfaceVariant, fontSize: 13)),
                  const SizedBox(height: 4),
                ],
                Text(
                  l10n.songCount(songs.length),
                  style: TextStyle(
                      color: colorScheme.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Expanded(
            child: songs.isEmpty
                ? Center(
                    child: Text(emptyText,
                        style: TextStyle(color: colorScheme.onSurfaceVariant)))
                : ListView.builder(
                    itemCount: songs.length,
                    itemBuilder: (_, i) {
                      final song = songs[i];
                      final isCurrent = player.currentSong?.id == song.id;
                      return ListTile(
                        leading: SizedBox(
                          width: 32,
                          child: isCurrent
                              ? Icon(
                                  player.isPlaying
                                      ? Icons.volume_up
                                      : Icons.pause,
                                  color: colorScheme.primary,
                                  size: 18)
                              : Text('${i + 1}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: colorScheme.onSurfaceVariant)),
                        ),
                        title: Text(
                          song.title,
                          style: TextStyle(
                            color: isCurrent
                                ? colorScheme.primary
                                : colorScheme.onSurface,
                            fontWeight:
                                isCurrent ? FontWeight.bold : FontWeight.normal,
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
                          style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 12),
                        ),
                        trailing: LikeButton(song: song, size: 20),
                        onTap: () => player.playSong(song, songs, i),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
