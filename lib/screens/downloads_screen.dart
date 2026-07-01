import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../services/download_service.dart';

String _formatBytes(int bytes) {
  if (bytes == 0) return '0 B';
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final downloads = context.watch<DownloadService>();
    final songs = downloads.downloadedSongs;
    final totalSize = _formatBytes(downloads.totalDownloadSizeBytes);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.downloadsHeader)),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              '${songs.length} songs · $totalSize',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ),
          if (songs.isEmpty)
            ListTile(
              leading: const Icon(Icons.download_outlined),
              title: Text(l10n.noDownloads),
            )
          else ...[
            for (final song in songs) _DownloadedSongTile(song: song),
            ListTile(
              leading: const Icon(Icons.delete_forever_outlined,
                  color: Colors.redAccent),
              title: Text(l10n.deleteAllDownloads,
                  style: const TextStyle(color: Colors.redAccent)),
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(l10n.deleteAllDownloads),
                    content: Text(
                        '${songs.length} ${l10n.songCount(songs.length)}'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                            backgroundColor: Colors.redAccent),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(l10n.deleteAllDownloads),
                      ),
                    ],
                  ),
                );
                if (confirmed == true && context.mounted) {
                  await context.read<DownloadService>().deleteAll();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.allDownloadsRemoved)),
                    );
                  }
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _DownloadedSongTile extends StatelessWidget {
  final DownloadedSongInfo song;
  const _DownloadedSongTile({required this.song});

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final downloads = context.read<DownloadService>();
    final sizeStr = _formatBytes(downloads.getFileSizeBytes(song.id));

    return ListTile(
      leading: const Icon(Icons.music_note_outlined),
      title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('${song.artist} · $sizeStr'),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        tooltip: l10n.tooltipDeleteDownload,
        onPressed: () async {
          await downloads.delete(song.id);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.downloadRemoved)),
            );
          }
        },
      ),
    );
  }
}
