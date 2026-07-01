import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../constants.dart';
import '../l10n/app_localizations.dart';
import '../models/song.dart';
import '../services/api_service.dart';
import '../services/download_service.dart';
import '../services/player_service.dart';
import '../services/streaming_service.dart';
import '../widgets/global_app_bar_actions.dart';
import 'song_detail_screen.dart';

Future<bool> _confirmLeaveStream(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Leave live stream?'),
      content: const Text(
          'You are currently listening along in a live stream. '
          'Leave the stream and play your own music?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Leave stream'),
        ),
      ],
    ),
  );
  return result == true;
}

class SongsScreen extends StatefulWidget {
  final Future<bool> Function()? connectivityChecker;
  const SongsScreen({super.key, this.connectivityChecker});

  @override
  State<SongsScreen> createState() => _SongsScreenState();
}

class _SongsScreenState extends State<SongsScreen> {
  List<Song> _songs = [];
  bool _loading = true;
  bool _offline = false;
  final _searchCtrl = TextEditingController();
  String _language = '';
  String _genre = '';

  static const _languages = [
    '', 'English', 'Dutch', 'Spanish', 'Italian', 'German', 'French'
  ];
  List<String> _genres = const [''];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<bool> _hasInternet() async {
    if (widget.connectivityChecker != null) {
      return widget.connectivityChecker!();
    }
    try {
      final results = await Connectivity().checkConnectivity();
      return results.isNotEmpty &&
          results.any((r) => r != ConnectivityResult.none);
    } catch (_) {
      return false;
    }
  }

  Future<void> _load() async {
    setState(() { _loading = true; _offline = false; });
    final apiService = context.read<ApiService>();
    final online = await _hasInternet();
    try {
      final songs = await apiService.getSongs(
        search: _searchCtrl.text,
        language: _language,
        genre: _genre,
      );
      if (!mounted) return;
      final genreSet = songs
          .map((s) => s.genre)
          .where((g) => g.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
      setState(() {
        _songs = songs;
        _genres = ['', ...genreSet];
        _loading = false;
        _offline = !online;
      });
    } catch (_) {
      if (mounted) setState(() { _loading = false; _offline = true; });
    }
  }

  void _downloadAll() {
    final downloads = context.read<DownloadService>();
    final api = context.read<ApiService>();
    for (final song in _songs) {
      if (!downloads.isDownloaded(song.id) && !downloads.isDownloading(song.id)) {
        downloads.download(song, api.dio);
      }
    }
  }

  Future<void> _refreshOnline() async {
    final online = await _hasInternet();
    if (!online) {
      if (mounted) {
        final l10n = AppL10n.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.noInternet),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navSongs),
        actions: [
          GlobalAppBarActions(
            extraItems: _songs.isEmpty
                ? []
                : [
                    AppBarMenuItem(
                      icon: Icons.download_for_offline_outlined,
                      label: (_searchCtrl.text.isNotEmpty ||
                              _language.isNotEmpty ||
                              _genre.isNotEmpty)
                          ? '${l10n.downloadAll} (${_songs.length})'
                          : l10n.downloadAll,
                      onTap: _downloadAll,
                    ),
                  ],
          ),
          IconButton(
            tooltip: l10n.tooltipRefresh,
            icon: const Icon(Icons.refresh),
            onPressed: _refreshOnline,
          ),
          IconButton(
            tooltip: l10n.tooltipShuffleAll,
            icon: Icon(Icons.shuffle, color: colorScheme.primary),
            onPressed: _songs.isEmpty
                ? null
                : () async {
                    final streaming = context.read<StreamingService>();
                    if (streaming.inRoom && !streaming.isHost) {
                      final leave = await _confirmLeaveStream(context);
                      if (!leave || !context.mounted) return;
                      await streaming.leaveRoom();
                      if (!context.mounted) return;
                    }
                    context.read<PlayerService>().shufflePlay(_songs);
                  },
          ),
        ],
      ),
      body: Column(
        children: [
          const _DownloadProgressBanner(),
          if (_offline)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: const Color(0xFF7B5300),
              child: Row(
                children: [
                  const Icon(Icons.wifi_off, color: Colors.white, size: 14),
                  const SizedBox(width: 6),
                  Text(l10n.offlineBanner,
                      style: const TextStyle(color: Colors.white, fontSize: 12)),
                ],
              ),
            ),
          _Filters(
            searchCtrl: _searchCtrl,
            language: _language,
            languages: _languages,
            genre: _genre,
            genres: _genres,
            onSearch: (_) => _load(),
            onLanguage: (v) { setState(() => _language = v ?? ''); _load(); },
            onGenre: (v) { setState(() => _genre = v ?? ''); _load(); },
          ),
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
                : _songs.isEmpty
                    ? Center(
                        child: Text(l10n.noSongsFound,
                            style: TextStyle(color: colorScheme.onSurfaceVariant)))
                    : GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.72,
                        ),
                        itemCount: _songs.length,
                        itemBuilder: (_, i) =>
                            _SongCard(song: _songs[i], playlist: _songs, index: i),
                      ),
          ),
        ],
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  final TextEditingController searchCtrl;
  final String language;
  final List<String> languages;
  final String genre;
  final List<String> genres;
  final ValueChanged<String> onSearch;
  final ValueChanged<String?> onLanguage;
  final ValueChanged<String?> onGenre;

  const _Filters({
    required this.searchCtrl,
    required this.language,
    required this.languages,
    required this.genre,
    required this.genres,
    required this.onSearch,
    required this.onLanguage,
    required this.onGenre,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Column(
        children: [
          TextField(
            controller: searchCtrl,
            onChanged: onSearch,
            style: TextStyle(color: colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: l10n.searchHint,
              hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
              prefixIcon: Icon(Icons.search, color: colorScheme.primary, size: 20),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _Drop(
                  label: l10n.filterLanguage,
                  allLabel: l10n.allLanguage,
                  value: language,
                  items: languages,
                  onChanged: onLanguage,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Drop(
                  label: l10n.filterGenre,
                  allLabel: l10n.allGenre,
                  value: genre,
                  items: genres,
                  onChanged: onGenre,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Drop extends StatelessWidget {
  final String label;
  final String allLabel;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _Drop({
    required this.label,
    required this.allLabel,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isActive = value.isNotEmpty;

    return InkWell(
      key: Key('filter_drop_$label'),
      borderRadius: BorderRadius.circular(8),
      onTap: () => _showSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: isActive
              ? colorScheme.primary.withValues(alpha: 0.12)
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: isActive
              ? Border.all(color: colorScheme.primary.withValues(alpha: 0.4))
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value.isEmpty ? label : value,
                style: TextStyle(
                  color: isActive
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                  fontSize: 13,
                  fontWeight:
                      isActive ? FontWeight.w500 : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: isActive
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  void _showSheet(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  label,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        title: Text(allLabel),
                        trailing: value.isEmpty
                            ? Icon(Icons.check,
                                color: colorScheme.primary, size: 18)
                            : null,
                        onTap: () {
                          Navigator.pop(sheetCtx);
                          onChanged('');
                        },
                      ),
                      for (final item in items.where((e) => e.isNotEmpty))
                        ListTile(
                          title: Text(item),
                          trailing: value == item
                              ? Icon(Icons.check,
                                  color: colorScheme.primary, size: 18)
                              : null,
                          onTap: () {
                            Navigator.pop(sheetCtx);
                            onChanged(item);
                          },
                        ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _shareSong(BuildContext context, Song song) async {
  final url = '${AppConstants.websiteUrl}/song/${song.id}';
  final box = context.findRenderObject() as RenderBox?;
  await Share.share(
    url,
    subject: song.title,
    sharePositionOrigin:
        box != null ? box.localToGlobal(Offset.zero) & box.size : null,
  );
}

class _DownloadProgressBanner extends StatelessWidget {
  const _DownloadProgressBanner();

  @override
  Widget build(BuildContext context) {
    final downloads = context.watch<DownloadService>();
    if (!downloads.hasActiveDownloads) return const SizedBox.shrink();

    final active = downloads.activeDownloads;
    final count = active.length;
    final avgProgress =
        active.values.fold(0.0, (s, v) => s + v) / count;
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppL10n.of(context)!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          color: colorScheme.primaryContainer,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(
            children: [
              Icon(Icons.download_outlined,
                  color: colorScheme.onPrimaryContainer, size: 14),
              const SizedBox(width: 6),
              Text(
                '${l10n.downloadingActive} ($count)',
                style: TextStyle(
                    color: colorScheme.onPrimaryContainer, fontSize: 12),
              ),
              const Spacer(),
              Text(
                '${(avgProgress * 100).toInt()}%',
                style: TextStyle(
                    color: colorScheme.onPrimaryContainer, fontSize: 12),
              ),
            ],
          ),
        ),
        LinearProgressIndicator(
          value: avgProgress,
          minHeight: 3,
          backgroundColor:
              colorScheme.primaryContainer,
          valueColor:
              AlwaysStoppedAnimation(colorScheme.primary),
        ),
      ],
    );
  }
}

void _showSongMenu(BuildContext context, Song song) {
  final l10n = AppL10n.of(context)!;
  final downloads = context.read<DownloadService>();
  final api = context.read<ApiService>();
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) => _SongMenuSheet(
      song: song,
      downloads: downloads,
      onQueue: () {
        Navigator.pop(sheetCtx);
        context.read<PlayerService>().addToQueue(song);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.addedToQueue(song.title)),
          duration: const Duration(seconds: 2),
        ));
      },
      onInfo: () {
        Navigator.pop(sheetCtx);
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => SongDetailScreen(song: song)));
      },
      onShare: () async {
        Navigator.pop(sheetCtx);
        await _shareSong(context, song);
      },
      onDownload: () {
        Navigator.pop(sheetCtx);
        downloads.download(song, api.dio);
      },
      onDeleteDownload: () {
        Navigator.pop(sheetCtx);
        downloads.delete(song.id);
      },
    ),
  );
}

class _SongCard extends StatelessWidget {
  final Song song;
  final List<Song> playlist;
  final int index;

  const _SongCard({required this.song, required this.playlist, required this.index});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerService>();
    final isCurrent = player.currentSong?.id == song.id;
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () async {
        final streaming = context.read<StreamingService>();
        if (streaming.inRoom && !streaming.isHost) {
          final leave = await _confirmLeaveStream(context);
          if (!leave || !context.mounted) return;
          await streaming.leaveRoom();
          if (!context.mounted) return;
        }
        context.read<PlayerService>().playSong(song, playlist, index);
      },
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: isCurrent
              ? Border.all(color: colorScheme.primary, width: 1.5)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    song.imageUrl != null
                        ? Image.network(song.imageUrl!, fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _placeholder(colorScheme))
                        : _placeholder(colorScheme),
                    if (isCurrent)
                      Container(
                        color: Colors.black45,
                        child: Icon(
                          player.isPlaying ? Icons.pause_circle : Icons.play_circle,
                          color: colorScheme.primary,
                          size: 48,
                        ),
                      ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: () => _showSongMenu(context, song),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.more_vert,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    style: TextStyle(
                      color: isCurrent ? colorScheme.primary : colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${song.genre} • ${song.year}',
                    style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(ColorScheme cs) => Container(
        color: cs.surfaceContainerHighest,
        child: Icon(Icons.music_note, color: cs.primary, size: 48),
      );
}

class _SongMenuSheet extends StatelessWidget {
  final Song song;
  final DownloadService downloads;
  final VoidCallback onQueue;
  final VoidCallback onInfo;
  final VoidCallback onShare;
  final VoidCallback onDownload;
  final VoidCallback onDeleteDownload;

  const _SongMenuSheet({
    required this.song,
    required this.downloads,
    required this.onQueue,
    required this.onInfo,
    required this.onShare,
    required this.onDownload,
    required this.onDeleteDownload,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppL10n.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: song.imageUrl != null
                      ? Image.network(
                          song.imageUrl!,
                          width: 54,
                          height: 54,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _thumb(colorScheme),
                        )
                      : _thumb(colorScheme),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        song.artist,
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(
              height: 1,
              color: colorScheme.outline.withValues(alpha: 0.2)),
          _SheetItem(
            icon: Icons.playlist_add_outlined,
            label: l10n.btnAddToQueue,
            onTap: onQueue,
          ),
          _SheetItem(
            icon: Icons.info_outline,
            label: l10n.menuSongInfo,
            onTap: onInfo,
          ),
          _SheetItem(
            icon: Icons.share_outlined,
            label: l10n.tooltipShare,
            onTap: onShare,
          ),
          if (downloads.isDownloading(song.id))
            _SheetItem(
              icon: Icons.downloading_outlined,
              label: l10n.tooltipDownload,
              enabled: false,
              trailing: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  value: downloads.getProgress(song.id),
                  strokeWidth: 2,
                  color: colorScheme.primary,
                ),
              ),
              onTap: () {},
            )
          else if (downloads.isDownloaded(song.id))
            _SheetItem(
              icon: Icons.download_done,
              label: l10n.tooltipDeleteDownload,
              iconColor: colorScheme.primary,
              onTap: onDeleteDownload,
            )
          else
            _SheetItem(
              icon: Icons.download_outlined,
              label: l10n.tooltipDownload,
              onTap: onDownload,
            ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
        ],
      ),
    );
  }

  Widget _thumb(ColorScheme cs) => Container(
        width: 54,
        height: 54,
        color: cs.surfaceContainerHighest,
        child: Icon(Icons.music_note, color: cs.primary, size: 28),
      );
}

class _SheetItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool enabled;
  final Color? iconColor;
  final Widget? trailing;

  const _SheetItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = true,
    this.iconColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = enabled
        ? colorScheme.onSurface
        : colorScheme.onSurface.withValues(alpha: 0.4);
    return InkWell(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? color, size: 22),
            const SizedBox(width: 18),
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: color, fontSize: 16),
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
