import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import '../services/api_service.dart';
import '../services/history_service.dart';
import '../services/liked_songs_service.dart';
import '../services/smart_playlists.dart';
import '../widgets/global_app_bar_actions.dart';
import 'liked_songs_screen.dart';
import 'playlist_detail_screen.dart';
import 'song_list_screen.dart';

class PlaylistsScreen extends StatefulWidget {
  const PlaylistsScreen({super.key});

  @override
  State<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen> {
  List<Playlist> _playlists = [];
  List<Song> _songs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final api = context.read<ApiService>();
    unawaited(_loadSongs(api));
    try {
      final pls = await api.getPlaylists();
      if (mounted) setState(() { _playlists = pls; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Smart playlists are built from the full catalogue; failure just hides them.
  Future<void> _loadSongs(ApiService api) async {
    try {
      final songs = await api.getSongs();
      if (mounted) setState(() => _songs = songs);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navPlaylists),
        actions: const [GlobalAppBarActions()],
      ),
      body: Column(
        children: [
          _SmartPlaylistsRow(songs: _songs),
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: _LikedSongsCard(),
          ),
          Expanded(
            child: _loading
                ? Center(
                    child:
                        CircularProgressIndicator(color: colorScheme.primary))
                : _playlists.isEmpty
                    ? Center(
                        child: Text(l10n.noPlaylists,
                            style:
                                TextStyle(color: colorScheme.onSurfaceVariant)))
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: colorScheme.primary,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _playlists.length,
                          itemBuilder: (_, i) =>
                              _PlaylistCard(playlist: _playlists[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _LikedSongsCard extends StatelessWidget {
  const _LikedSongsCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final count = context.watch<LikedSongsService>().likedSongs.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LikedSongsScreen()),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.favorite, color: Colors.red, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.likedSongs,
                        style: TextStyle(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                    const SizedBox(height: 3),
                    Text(
                      l10n.songCount(count),
                      style: TextStyle(
                          color: colorScheme.onSurfaceVariant, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaylistCard extends StatelessWidget {
  final Playlist playlist;
  const _PlaylistCard({required this.playlist});

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => PlaylistDetailScreen(playlist: playlist)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.queue_music, color: colorScheme.primary, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(playlist.name,
                        style: TextStyle(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                    const SizedBox(height: 3),
                    Text(
                      l10n.songCount(playlist.songs.length),
                      style: TextStyle(
                          color: colorScheme.onSurfaceVariant, fontSize: 12),
                    ),
                    if (playlist.description != null &&
                        playlist.description!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(playlist.description!,
                          style: TextStyle(
                              color: colorScheme.onSurfaceVariant, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmartPlaylistsRow extends StatelessWidget {
  final List<Song> songs;
  const _SmartPlaylistsRow({required this.songs});

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final playlists = buildSmartPlaylists(
      songs: songs,
      history: context.watch<HistoryService>().entries,
      liked: context.watch<LikedSongsService>().likedSongs,
    );
    if (playlists.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Text(l10n.smartPlaylists,
              style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
        ),
        SizedBox(
          height: 128,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: playlists.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, i) => _SmartPlaylistCard(playlist: playlists[i]),
          ),
        ),
      ],
    );
  }
}

class _SmartPlaylistCard extends StatelessWidget {
  final SmartPlaylist playlist;
  const _SmartPlaylistCard({required this.playlist});

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final (title, description, icon, color) = switch (playlist.kind) {
      SmartPlaylistKind.mostPlayed => (
          l10n.smartMostPlayed,
          l10n.smartMostPlayedDesc,
          Icons.local_fire_department,
          Colors.orange,
        ),
      SmartPlaylistKind.genreMix => (
          l10n.smartGenreMix(playlist.label),
          l10n.smartGenreMixDesc,
          Icons.graphic_eq,
          Colors.purpleAccent,
        ),
      SmartPlaylistKind.forgottenFavorites => (
          l10n.smartForgottenFavorites,
          l10n.smartForgottenFavoritesDesc,
          Icons.history,
          Colors.red,
        ),
      SmartPlaylistKind.newThisYear => (
          l10n.smartNewThisYear(playlist.label),
          l10n.smartNewThisYearDesc,
          Icons.new_releases_outlined,
          Colors.lightBlue,
        ),
      SmartPlaylistKind.neverPlayed => (
          l10n.smartNeverPlayed,
          l10n.smartNeverPlayedDesc,
          Icons.explore_outlined,
          colorScheme.primary,
        ),
    };

    return SizedBox(
      width: 150,
      child: Card(
        margin: EdgeInsets.zero,
        color: color.withValues(alpha: 0.15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SongListScreen(
                title: title,
                description: description,
                songs: playlist.songs,
                emptyText: l10n.noSongsInPlaylist,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 30),
                const Spacer(),
                Text(title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                const SizedBox(height: 2),
                Text(l10n.songCount(playlist.songs.length),
                    style: TextStyle(
                        color: colorScheme.onSurfaceVariant, fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
