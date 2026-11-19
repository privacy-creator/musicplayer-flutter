import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../services/local_library_service.dart';
import '../services/player_service.dart';
import 'local_music_screen.dart';

/// Detailweergave van een lokale afspeellijst. Heeft bewust geen
/// deel-knop: lokale afspeellijsten bestaan alleen op dit apparaat.
class LocalPlaylistDetailScreen extends StatelessWidget {
  final String playlistId;
  const LocalPlaylistDetailScreen({super.key, required this.playlistId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final library = context.watch<LocalLibraryService>();
    final playlist = library.playlistById(playlistId);
    final cs = Theme.of(context).colorScheme;

    if (playlist == null) {
      return Scaffold(appBar: AppBar());
    }
    final tracks = library.tracksForPlaylist(playlistId);
    final songs = [for (final t in tracks) t.toSong()];

    return Scaffold(
      appBar: AppBar(
        title: Text(playlist.name),
        actions: [
          PopupMenuButton<String>(
            key: const Key('localPlaylistMenu'),
            onSelected: (v) async {
              if (v == 'rename') {
                final name = await showLocalPlaylistNameDialog(
                  context,
                  title: l10n.localRenamePlaylist,
                  confirmLabel: l10n.save,
                  initial: playlist.name,
                );
                if (name != null && context.mounted) {
                  await context
                      .read<LocalLibraryService>()
                      .renamePlaylist(playlistId, name);
                }
              } else if (v == 'delete') {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(l10n.localDeletePlaylist),
                    content:
                        Text(l10n.localDeletePlaylistConfirm(playlist.name)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(l10n.localCancel),
                      ),
                      FilledButton(
                        key: const Key('localDeletePlaylistConfirm'),
                        style: FilledButton.styleFrom(
                            backgroundColor: Colors.redAccent),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(l10n.localDeletePlaylist),
                      ),
                    ],
                  ),
                );
                if (ok == true && context.mounted) {
                  await context
                      .read<LocalLibraryService>()
                      .deletePlaylist(playlistId);
                  if (context.mounted) Navigator.pop(context);
                }
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                  value: 'rename', child: Text(l10n.localRenamePlaylist)),
              PopupMenuItem(
                  value: 'delete', child: Text(l10n.localDeletePlaylist)),
            ],
          ),
        ],
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Icon(Icons.lock_outline, size: 14, color: cs.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${l10n.songCount(tracks.length)} · ${l10n.localNotShareable}',
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                FilledButton.icon(
                  key: const Key('localPlaylistPlay'),
                  onPressed: songs.isEmpty
                      ? null
                      : () => context
                          .read<PlayerService>()
                          .playSong(songs.first, songs, 0),
                  icon: const Icon(Icons.play_arrow),
                  label: Text(l10n.localPlay),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: songs.isEmpty
                      ? null
                      : () => context.read<PlayerService>().shufflePlay(songs),
                  icon: const Icon(Icons.shuffle),
                  label: Text(l10n.localShuffle),
                ),
              ],
            ),
          ),
          if (tracks.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(l10n.localPlaylistEmpty, textAlign: TextAlign.center),
            )
          else
            for (var i = 0; i < tracks.length; i++)
              LocalTrackTile(
                track: tracks[i],
                tracks: tracks,
                index: i,
                playlistId: playlistId,
              ),
        ],
      ),
    );
  }
}
