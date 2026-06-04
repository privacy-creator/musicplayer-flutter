import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/playlist.dart';
import '../services/api_service.dart';
import 'playlist_detail_screen.dart';

class PlaylistsScreen extends StatefulWidget {
  const PlaylistsScreen({super.key});

  @override
  State<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen> {
  List<Playlist> _playlists = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final pls = await context.read<ApiService>().getPlaylists();
      if (mounted) setState(() { _playlists = pls; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navPlaylists)),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1DB954)))
          : _playlists.isEmpty
              ? Center(
                  child: Text(l10n.noPlaylists,
                      style: const TextStyle(color: Color(0xFFB3B3B3))))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: const Color(0xFF1DB954),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _playlists.length,
                    itemBuilder: (_, i) => _PlaylistCard(playlist: _playlists[i]),
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

    return Card(
      color: const Color(0xFF1E1E1E),
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
                  color: const Color(0xFF1DB954).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.queue_music,
                    color: Color(0xFF1DB954), size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(playlist.name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                    const SizedBox(height: 3),
                    Text(
                      l10n.songCount(playlist.songs.length),
                      style: const TextStyle(
                          color: Color(0xFFB3B3B3), fontSize: 12),
                    ),
                    if (playlist.description != null &&
                        playlist.description!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(playlist.description!,
                          style: const TextStyle(
                              color: Color(0xFFB3B3B3), fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFFB3B3B3)),
            ],
          ),
        ),
      ),
    );
  }
}
