import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/local_track.dart';
import '../services/local_library_service.dart';
import 'local_music_screen.dart';

/// Alle mappen met lokale muziek. Met de schakelaar sluit je een map (en
/// submappen) uit of neem je hem weer mee.
class LocalFoldersScreen extends StatelessWidget {
  const LocalFoldersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final library = context.watch<LocalLibraryService>();
    final cs = Theme.of(context).colorScheme;
    final folders = library.folders;
    final excluded = library.excludedFolders.toSet();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.localFolders)),
      body: folders.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(l10n.localFoldersEmpty,
                    textAlign: TextAlign.center),
              ),
            )
          : ListView(
              children: [
                for (final entry in folders.entries)
                  SwitchListTile(
                    key: ValueKey('localFolder_${entry.key}'),
                    secondary: Icon(
                      excluded.contains(entry.key)
                          ? Icons.folder_off_outlined
                          : Icons.folder_outlined,
                      color: excluded.contains(entry.key)
                          ? cs.onSurfaceVariant
                          : cs.primary,
                    ),
                    title: Text(_folderName(entry.key),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      '${excluded.contains(entry.key) ? l10n.localExcludedLabel : l10n.songCount(entry.value)}\n${entry.key}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    isThreeLine: true,
                    value: !excluded.contains(entry.key),
                    onChanged: (include) async {
                      final lib = context.read<LocalLibraryService>();
                      if (include) {
                        await lib.includeFolder(entry.key);
                        if (context.mounted) await runLocalScan(context);
                      } else {
                        await confirmExcludeFolder(context, entry.key);
                      }
                    },
                  ),
              ],
            ),
    );
  }

  static String _folderName(String path) {
    final parts = path.split(RegExp(r'[/\\]')).where((p) => p.isNotEmpty);
    return parts.isEmpty ? path : parts.last;
  }
}

/// Nummers die uit de bibliotheek zijn gehaald maar nog op het apparaat
/// staan, met de mogelijkheid ze terug te zetten.
class LocalHiddenSongsScreen extends StatelessWidget {
  const LocalHiddenSongsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final library = context.watch<LocalLibraryService>();
    final hidden = library.hiddenPaths;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.localHiddenSongs)),
      body: hidden.isEmpty
          ? Center(child: Text(l10n.localHiddenEmpty))
          : ListView(
              children: [
                for (final path in hidden)
                  ListTile(
                    leading: const Icon(Icons.visibility_off_outlined),
                    title: Text(LocalTrack.fromPath(path).title,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(path,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: TextButton(
                      key: ValueKey('localRestore_$path'),
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        await context
                            .read<LocalLibraryService>()
                            .restoreHidden(path);
                        messenger.showSnackBar(
                            SnackBar(content: Text(l10n.localRestored)));
                      },
                      child: Text(l10n.localRestore),
                    ),
                  ),
              ],
            ),
    );
  }
}

/// Blok "Lokale muziek" in de instellingen.
class LocalMusicSettingsSection extends StatelessWidget {
  const LocalMusicSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final library = context.watch<LocalLibraryService>();

    return Column(
      children: [
        ListTile(
          key: const Key('settingsLocalScan'),
          leading: library.isScanning
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: Padding(
                    padding: EdgeInsets.all(2),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : const Icon(Icons.manage_search),
          title: Text(library.isScanning ? l10n.localScanning : l10n.localScan),
          subtitle: Text(l10n.songCount(library.tracks.length)),
          onTap: library.isScanning ? null : () => runLocalScan(context),
        ),
        ListTile(
          key: const Key('settingsLocalFolders'),
          leading: const Icon(Icons.folder_off_outlined),
          title: Text(l10n.localFolders),
          subtitle:
              Text(l10n.localFoldersDesc(library.excludedFolders.length)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LocalFoldersScreen()),
          ),
        ),
        ListTile(
          key: const Key('settingsLocalHidden'),
          leading: const Icon(Icons.visibility_off_outlined),
          title: Text(l10n.localHiddenSongs),
          subtitle:
              Text(l10n.localHiddenSongsDesc(library.hiddenPaths.length)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LocalHiddenSongsScreen()),
          ),
        ),
      ],
    );
  }
}
