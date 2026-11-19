import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/local_track.dart';
import '../services/local_library_service.dart';
import '../services/player_service.dart';
import '../widgets/global_app_bar_actions.dart';
import '../widgets/menu_sheet.dart';
import 'local_folders_screen.dart';
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
            // Zelfde menu als de rest van de app (instellingen, login),
            // aangevuld met de acties voor lokale muziek.
            GlobalAppBarActions(
              extraItems: [
                AppBarMenuItem(
                  icon: Icons.manage_search,
                  label: l10n.localScan,
                  onTap: () {
                    Navigator.pop(context);
                    runLocalScan(context);
                  },
                ),
                if (library.tracks.isNotEmpty)
                  AppBarMenuItem(
                    icon: Icons.shuffle,
                    label: l10n.tooltipShuffleAll,
                    onTap: () {
                      Navigator.pop(context);
                      context.read<PlayerService>().shufflePlay(
                          [for (final t in library.tracks) t.toSong()]);
                    },
                  ),
                AppBarMenuItem(
                  icon: Icons.folder_off_outlined,
                  label: l10n.localFolders,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const LocalFoldersScreen()),
                    );
                  },
                ),
              ],
            ),
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
      trailing: IconButton(
        key: ValueKey('localMenu_${track.path}'),
        icon: const Icon(Icons.more_vert),
        onPressed: () => showLocalTrackMenu(ctx, track, playlistId: playlistId),
      ),
    );
  }
}

/// Opties voor een lokaal nummer, als bottom sheet zoals het nummer-menu
/// van de cloud-muziek.
Future<void> showLocalTrackMenu(
  BuildContext context,
  LocalTrack track, {
  String? playlistId,
}) async {
  final l10n = AppL10n.of(context)!;
  final artist = track.artist.isEmpty ? l10n.localUnknownArtist : track.artist;
  final folder = LocalLibraryService.folderOf(track.path);

  final choice = await MenuSheet.show<String>(
    context,
    title: track.title,
    subtitle: artist,
    headerIcon: Icons.audio_file,
    items: (sheetCtx) {
      MenuSheetItem item(String value, IconData icon, String label,
              {Color? color}) =>
          MenuSheetItem(
            key: ValueKey('localMenuItem_$value'),
            icon: icon,
            label: label,
            color: color,
            onTap: () => Navigator.pop(sheetCtx, value),
          );
      return [
        item('queue', Icons.playlist_add_outlined, l10n.btnAddToQueue),
        item('playlist', Icons.queue_music_outlined, l10n.localAddToPlaylist),
        if (playlistId != null)
          item('remove', Icons.playlist_remove_outlined,
              l10n.localRemoveFromPlaylist),
        item('rename', Icons.edit_outlined, l10n.localRename),
        item('exclude', Icons.folder_off_outlined, l10n.localExcludeFolder),
        item('delete', Icons.delete_outline, l10n.localDelete,
            color: Colors.redAccent),
      ];
    },
  );
  if (choice == null || !context.mounted) return;

  final library = context.read<LocalLibraryService>();
  final messenger = ScaffoldMessenger.of(context);
  switch (choice) {
    case 'queue':
      context.read<PlayerService>().addToQueue(track.toSong());
      messenger.showSnackBar(
          SnackBar(content: Text(l10n.addedToQueue(track.title))));
    case 'playlist':
      await showAddToLocalPlaylistSheet(context, track);
    case 'remove':
      await library.removeFromPlaylist(playlistId!, track.path);
    case 'rename':
      await showRenameTrackDialog(context, track);
    case 'exclude':
      await confirmExcludeFolder(context, folder);
    case 'delete':
      await showDeleteTrackDialog(context, track);
  }
}

enum _DeleteChoice { library, device }

/// Vraagt of het nummer alleen uit de bibliotheek moet of ook van het
/// apparaat, en voert dat uit.
Future<void> showDeleteTrackDialog(BuildContext context, LocalTrack track) async {
  final l10n = AppL10n.of(context)!;
  final library = context.read<LocalLibraryService>();
  final messenger = ScaffoldMessenger.of(context);

  final choice = await showDialog<_DeleteChoice>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.localDeleteTitle(track.title)),
      contentPadding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            key: const Key('localDeleteLibrary'),
            leading: const Icon(Icons.remove_circle_outline),
            title: Text(l10n.localRemoveFromLibrary),
            subtitle: Text(l10n.localRemoveFromLibraryDesc),
            onTap: () => Navigator.pop(ctx, _DeleteChoice.library),
          ),
          ListTile(
            key: const Key('localDeleteDevice'),
            leading:
                const Icon(Icons.delete_forever_outlined, color: Colors.redAccent),
            title: Text(l10n.localDeleteFromDevice,
                style: const TextStyle(color: Colors.redAccent)),
            subtitle: Text(l10n.localDeleteFromDeviceDesc),
            onTap: () => Navigator.pop(ctx, _DeleteChoice.device),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l10n.localCancel),
        ),
      ],
    ),
  );
  if (choice == null) return;

  if (choice == _DeleteChoice.library) {
    await library.removeFromLibrary(track.path);
    messenger.showSnackBar(
        SnackBar(content: Text(l10n.localRemovedFromLibrary)));
    return;
  }
  try {
    await library.deleteFile(track.path);
    messenger.showSnackBar(
        SnackBar(content: Text(l10n.localDeletedFromDevice)));
  } on LocalDeleteException {
    messenger.showSnackBar(SnackBar(content: Text(l10n.localDeleteFailed)));
  }
}

/// Bevestiging voordat een map wordt uitgesloten.
Future<void> confirmExcludeFolder(BuildContext context, String folder) async {
  final l10n = AppL10n.of(context)!;
  final library = context.read<LocalLibraryService>();
  final messenger = ScaffoldMessenger.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.localExcludeFolder),
      content: Text(l10n.localExcludeFolderConfirm(folder)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l10n.localCancel),
        ),
        FilledButton(
          key: const Key('localExcludeConfirm'),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l10n.localExcludeFolder),
        ),
      ],
    ),
  );
  if (ok != true) return;
  final removed = await library.excludeFolder(folder);
  messenger.showSnackBar(
      SnackBar(content: Text(l10n.localFolderExcluded(removed))));
}

// ── Dialogen ──────────────────────────────────────────────────────────────────

Future<void> showRenameTrackDialog(BuildContext context, LocalTrack track) async {
  final l10n = AppL10n.of(context)!;
  final library = context.read<LocalLibraryService>();
  final messenger = ScaffoldMessenger.of(context);

  final result = await showDialog<_RenameResult>(
    context: context,
    builder: (_) => _RenameTrackDialog(track: track),
  );
  if (result == null) return;

  try {
    await library.renameTrack(track.path,
        title: result.title,
        artist: result.artist,
        renameFile: result.renameFile);
    messenger.showSnackBar(SnackBar(content: Text(l10n.localRenameDone)));
  } on LocalRenameException catch (e) {
    messenger.showSnackBar(SnackBar(
      content: Text(
          e.message == 'exists' ? l10n.localRenameExists : l10n.localRenameFailed),
    ));
  }
}

typedef _RenameResult = ({String title, String artist, bool renameFile});

/// Eigen State zodat de controllers pas worden opgeruimd als de dialoog
/// (inclusief sluitanimatie) echt uit de boom is.
class _RenameTrackDialog extends StatefulWidget {
  final LocalTrack track;
  const _RenameTrackDialog({required this.track});

  @override
  State<_RenameTrackDialog> createState() => _RenameTrackDialogState();
}

class _RenameTrackDialogState extends State<_RenameTrackDialog> {
  late final _titleCtrl = TextEditingController(text: widget.track.title);
  late final _artistCtrl = TextEditingController(text: widget.track.artist);
  bool _renameFile = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _artistCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    return AlertDialog(
      title: Text(l10n.localRename),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('localRenameTitle'),
              controller: _titleCtrl,
              autofocus: true,
              decoration: InputDecoration(labelText: l10n.localFieldTitle),
            ),
            TextField(
              key: const Key('localRenameArtist'),
              controller: _artistCtrl,
              decoration: InputDecoration(labelText: l10n.localFieldArtist),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              key: const Key('localRenameFile'),
              contentPadding: EdgeInsets.zero,
              value: _renameFile,
              onChanged: (v) => setState(() => _renameFile = v ?? false),
              title: Text(l10n.localRenameFile,
                  style: const TextStyle(fontSize: 14)),
              subtitle: Text(widget.track.fileName,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.localCancel),
        ),
        FilledButton(
          key: const Key('localRenameSave'),
          onPressed: () {
            if (_titleCtrl.text.trim().isEmpty) return;
            Navigator.pop<_RenameResult>(context, (
              title: _titleCtrl.text,
              artist: _artistCtrl.text,
              renameFile: _renameFile,
            ));
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

/// Vraagt een naam; geeft null bij annuleren of lege invoer.
Future<String?> showLocalPlaylistNameDialog(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  String initial = '',
}) async {
  final name = await showDialog<String>(
    context: context,
    builder: (_) => _PlaylistNameDialog(
        title: title, confirmLabel: confirmLabel, initial: initial),
  );
  final clean = name?.trim() ?? '';
  return clean.isEmpty ? null : clean;
}

class _PlaylistNameDialog extends StatefulWidget {
  final String title;
  final String confirmLabel;
  final String initial;
  const _PlaylistNameDialog({
    required this.title,
    required this.confirmLabel,
    required this.initial,
  });

  @override
  State<_PlaylistNameDialog> createState() => _PlaylistNameDialogState();
}

class _PlaylistNameDialogState extends State<_PlaylistNameDialog> {
  late final _ctrl = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        key: const Key('localPlaylistNameField'),
        controller: _ctrl,
        autofocus: true,
        decoration: InputDecoration(labelText: l10n.localPlaylistName),
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.localCancel),
        ),
        FilledButton(
          key: const Key('localPlaylistNameConfirm'),
          onPressed: () => Navigator.pop(context, _ctrl.text),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

Future<void> showAddToLocalPlaylistSheet(
    BuildContext context, LocalTrack track) async {
  final l10n = AppL10n.of(context)!;
  final library = context.read<LocalLibraryService>();
  final messenger = ScaffoldMessenger.of(context);

  final choice = await MenuSheet.show<String>(
    context,
    title: l10n.localAddToPlaylist,
    subtitle: track.title,
    headerIcon: Icons.queue_music,
    items: (sheetCtx) => [
      MenuSheetItem(
        key: const Key('localSheetNewPlaylist'),
        icon: Icons.add,
        label: l10n.localNewPlaylist,
        onTap: () => Navigator.pop(sheetCtx, '__new__'),
      ),
      for (final p in library.playlists)
        MenuSheetItem(
          icon: Icons.queue_music_outlined,
          label:
              '${p.name} (${library.tracksForPlaylist(p.id).length})',
          onTap: () => Navigator.pop(sheetCtx, p.id),
        ),
    ],
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
