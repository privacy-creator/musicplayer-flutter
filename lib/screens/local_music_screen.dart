import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/local_track.dart';
import '../services/local_library_service.dart';
import '../services/player_service.dart';
import 'local_playlist_detail_screen.dart';

String formatLocalBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

/// Muziek die op het apparaat zelf staat, los van de cloud-muziek.
class LocalMusicScreen extends StatelessWidget {
  const LocalMusicScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final library = context.watch<LocalLibraryService>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.navLocal),
          actions: [
            if (library.isScanning)
              const Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              IconButton(
                key: const Key('localScanButton'),
                tooltip: l10n.localScan,
                icon: const Icon(Icons.manage_search),
                onPressed: () => runLocalScan(context),
              ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.localSongsTab),
              Tab(text: l10n.localPlaylistsTab),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_LocalSongsTab(), _LocalPlaylistsTab()],
        ),
      ),
    );
  }
}

Future<void> runLocalScan(BuildContext context) async {
  final l10n = AppL10n.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  final result = await context.read<LocalLibraryService>().scan();
  final msg = switch (result.status) {
    LocalScanStatus.ok => l10n.localScanDone(result.added),
    LocalScanStatus.permissionDenied => l10n.localPermissionDenied,
    LocalScanStatus.error => l10n.localScanError,
    LocalScanStatus.alreadyScanning => null,
  };
  if (msg != null) messenger.showSnackBar(SnackBar(content: Text(msg)));
}

// ── Nummers ───────────────────────────────────────────────────────────────────

class _LocalSongsTab extends StatefulWidget {
  const _LocalSongsTab();

  @override
  State<_LocalSongsTab> createState() => _LocalSongsTabState();
}

class _LocalSongsTabState extends State<_LocalSongsTab> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final library = context.watch<LocalLibraryService>();
    final all = library.tracks;

    if (all.isEmpty) {
      return _EmptyLocal(scanning: library.isScanning);
    }

    final tracks = library.search(_query);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: TextField(
            key: const Key('localSearchField'),
            decoration: InputDecoration(
              hintText: l10n.localSearchHint,
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              border: const OutlineInputBorder(),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.songCount(tracks.length),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: tracks.isEmpty
                    ? null
                    : () => context
                        .read<PlayerService>()
                        .shufflePlay([for (final t in tracks) t.toSong()]),
                icon: const Icon(Icons.shuffle, size: 18),
                label: Text(l10n.localShuffle),
              ),
            ],
          ),
        ),
        Expanded(
          child: tracks.isEmpty
              ? Center(child: Text(l10n.noSongsFound))
              : ListView.builder(
                  itemCount: tracks.length,
                  itemBuilder: (_, i) =>
                      LocalTrackTile(track: tracks[i], tracks: tracks, index: i),
                ),
        ),
      ],
    );
  }
}

class _EmptyLocal extends StatelessWidget {
  final bool scanning;
  const _EmptyLocal({required this.scanning});

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.phone_android, size: 56, color: cs.primary),
            const SizedBox(height: 16),
            Text(l10n.localEmptyTitle,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(l10n.localEmptyBody,
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant)),
            if (Platform.isIOS) ...[
              const SizedBox(height: 8),
              Text(l10n.localIosHint,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              key: const Key('localEmptyScanButton'),
              onPressed: scanning ? null : () => runLocalScan(context),
              icon: scanning
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.manage_search),
              label: Text(scanning ? l10n.localScanning : l10n.localScan),
            ),
          ],
        ),
      ),
    );
  }
}


/// Eén lokaal nummer. Tik = afspelen binnen [tracks] (de zichtbare lijst).
class LocalTrackTile extends StatelessWidget {
  final LocalTrack track;
  final List<LocalTrack> tracks;
  final int index;

  /// Als gezet, toont het menu "Uit afspeellijst verwijderen".
  final String? playlistId;

  const LocalTrackTile({
    super.key,
    required this.track,
    required this.tracks,
    required this.index,
    this.playlistId,
  });

  @override
  Widget build(BuildContext ctx) {
    final l10n = AppL10n.of(ctx)!;
    final player = ctx.watch<PlayerService>();
    final cs = Theme.of(ctx).colorScheme;
    final isCurrent = player.currentSong?.id == track.id;
    final artist =
        track.artist.isEmpty ? l10n.localUnknownArtist : track.artist;

    return ListTile(
      key: ValueKey('local_${track.path}'),
      leading: Icon(
        isCurrent && player.isPlaying ? Icons.graphic_eq : Icons.audio_file,
        color: isCurrent ? cs.primary : null,
      ),
      title: Text(
        track.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: isCurrent ? cs.primary : null),
      ),
      subtitle: Text(
        '$artist · ${formatLocalBytes(track.sizeBytes)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () {
        final songs = [for (final t in tracks) t.toSong()];
        ctx.read<PlayerService>().playSong(songs[index], songs, index);
      },
      trailing: PopupMenuButton<String>(
        key: ValueKey('localMenu_${track.path}'),
        onSelected: (v) => _onMenu(ctx, v),
        itemBuilder: (_) => [
          PopupMenuItem(value: 'rename', child: Text(l10n.localRename)),
          PopupMenuItem(
              value: 'playlist', child: Text(l10n.localAddToPlaylist)),
          PopupMenuItem(value: 'queue', child: Text(l10n.btnAddToQueue)),
          if (playlistId != null)
            PopupMenuItem(
                value: 'remove', child: Text(l10n.localRemoveFromPlaylist)),
        ],
      ),
    );
  }

  Future<void> _onMenu(BuildContext ctx, String value) async {
    final l10n = AppL10n.of(ctx)!;
    switch (value) {
      case 'rename':
        await showRenameTrackDialog(ctx, track);
      case 'playlist':
        await showAddToLocalPlaylistSheet(ctx, track);
      case 'queue':
        ctx.read<PlayerService>().addToQueue(track.toSong());
        ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(content: Text(l10n.addedToQueue(track.title))));
      case 'remove':
        await ctx
            .read<LocalLibraryService>()
            .removeFromPlaylist(playlistId!, track.path);
    }
  }
}

// ── Dialogen ──────────────────────────────────────────────────────────────────

Future<void> showRenameTrackDialog(BuildContext context, LocalTrack track) async {
  final l10n = AppL10n.of(context)!;
  final library = context.read<LocalLibraryService>();
  final messenger = ScaffoldMessenger.of(context);
  final titleCtrl = TextEditingController(text: track.title);
  final artistCtrl = TextEditingController(text: track.artist);
  var renameFile = false;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(l10n.localRename),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('localRenameTitle'),
              controller: titleCtrl,
              autofocus: true,
              decoration: InputDecoration(labelText: l10n.localFieldTitle),
            ),
            TextField(
              key: const Key('localRenameArtist'),
              controller: artistCtrl,
              decoration: InputDecoration(labelText: l10n.localFieldArtist),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              key: const Key('localRenameFile'),
              contentPadding: EdgeInsets.zero,
              value: renameFile,
              onChanged: (v) => setState(() => renameFile = v ?? false),
              title: Text(l10n.localRenameFile,
                  style: const TextStyle(fontSize: 14)),
              subtitle: Text(track.fileName,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.localCancel),
          ),
          FilledButton(
            key: const Key('localRenameSave'),
            onPressed: () {
              if (titleCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    ),
  );

  final title = titleCtrl.text;
  final artist = artistCtrl.text;
  titleCtrl.dispose();
  artistCtrl.dispose();
  if (confirmed != true) return;

  try {
    await library.renameTrack(track.path,
        title: title, artist: artist, renameFile: renameFile);
    messenger.showSnackBar(SnackBar(content: Text(l10n.localRenameDone)));
  } on LocalRenameException catch (e) {
    messenger.showSnackBar(SnackBar(
      content: Text(
          e.message == 'exists' ? l10n.localRenameExists : l10n.localRenameFailed),
    ));
  }
}

/// Vraagt een naam; geeft null bij annuleren of lege invoer.
Future<String?> showLocalPlaylistNameDialog(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  String initial = '',
}) async {
  final l10n = AppL10n.of(context)!;
  final ctrl = TextEditingController(text: initial);
  final name = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        key: const Key('localPlaylistNameField'),
        controller: ctrl,
        autofocus: true,
        decoration: InputDecoration(labelText: l10n.localPlaylistName),
        onSubmitted: (v) => Navigator.pop(ctx, v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l10n.localCancel),
        ),
        FilledButton(
          key: const Key('localPlaylistNameConfirm'),
          onPressed: () => Navigator.pop(ctx, ctrl.text),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  ctrl.dispose();
  final clean = name?.trim() ?? '';
  return clean.isEmpty ? null : clean;
}

Future<void> showAddToLocalPlaylistSheet(
    BuildContext context, LocalTrack track) async {
  final l10n = AppL10n.of(context)!;
  final library = context.read<LocalLibraryService>();
  final messenger = ScaffoldMessenger.of(context);

  final choice = await showModalBottomSheet<String>(
    context: context,
    builder: (ctx) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          ListTile(
            title: Text(l10n.localAddToPlaylist,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          ListTile(
            key: const Key('localSheetNewPlaylist'),
            leading: const Icon(Icons.add),
            title: Text(l10n.localNewPlaylist),
            onTap: () => Navigator.pop(ctx, '__new__'),
          ),
          for (final p in library.playlists)
            ListTile(
              leading: const Icon(Icons.queue_music),
              title: Text(p.name),
              subtitle: Text(l10n.songCount(library.tracksForPlaylist(p.id).length)),
              onTap: () => Navigator.pop(ctx, p.id),
            ),
        ],
      ),
    ),
  );
  if (choice == null || !context.mounted) return;

  var id = choice;
  if (choice == '__new__') {
    final name = await showLocalPlaylistNameDialog(context,
        title: l10n.localNewPlaylist, confirmLabel: l10n.localCreate);
    if (name == null) return;
    id = (await library.createPlaylist(name)).id;
  }
  final playlist = library.playlistById(id);
  if (playlist == null) return;
  final added = await library.addToPlaylist(id, track.path);
  messenger.showSnackBar(SnackBar(
    content: Text(added
        ? l10n.localAddedToPlaylist(playlist.name)
        : l10n.localAlreadyInPlaylist(playlist.name)),
  ));
}

// ── Afspeellijsten ────────────────────────────────────────────────────────────

class _LocalPlaylistsTab extends StatelessWidget {
  const _LocalPlaylistsTab();

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final library = context.watch<LocalLibraryService>();
    final cs = Theme.of(context).colorScheme;
    final playlists = library.playlists;

    return ListView(
      children: [
        ListTile(
          key: const Key('localCreatePlaylist'),
          leading: Icon(Icons.add_circle_outline, color: cs.primary),
          title: Text(l10n.localNewPlaylist),
          onTap: () async {
            final name = await showLocalPlaylistNameDialog(context,
                title: l10n.localNewPlaylist, confirmLabel: l10n.localCreate);
            if (name != null && context.mounted) {
              await context.read<LocalLibraryService>().createPlaylist(name);
            }
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Icon(Icons.lock_outline, size: 14, color: cs.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(
                child: Text(l10n.localNotShareable,
                    style:
                        TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
              ),
            ],
          ),
        ),
        const Divider(),
        if (playlists.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(child: Text(l10n.localNoPlaylists)),
          )
        else
          for (final p in playlists)
            ListTile(
              leading: const Icon(Icons.queue_music),
              title: Text(p.name),
              subtitle: Text(
                  '${l10n.songCount(library.tracksForPlaylist(p.id).length)} · ${l10n.localOnDevice}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LocalPlaylistDetailScreen(playlistId: p.id),
                ),
              ),
            ),
      ],
    );
  }
}
