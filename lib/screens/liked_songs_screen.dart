import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../services/liked_songs_service.dart';
import 'song_list_screen.dart';

class LikedSongsScreen extends StatelessWidget {
  const LikedSongsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    return SongListScreen(
      title: l10n.likedSongs,
      songs: context.watch<LikedSongsService>().likedSongs,
      emptyText: l10n.noLikedSongs,
    );
  }
}
