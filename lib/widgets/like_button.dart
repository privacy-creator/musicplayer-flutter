import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/song.dart';
import '../services/liked_songs_service.dart';

class LikeButton extends StatelessWidget {
  final Song song;
  final double size;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final BoxConstraints? constraints;

  const LikeButton({
    super.key,
    required this.song,
    this.size = 22,
    this.color,
    this.padding,
    this.constraints,
  });

  @override
  Widget build(BuildContext context) {
    final isLiked = context.watch<LikedSongsService>().isLiked(song.id);
    final l10n = AppL10n.of(context)!;
    return IconButton(
      tooltip: isLiked ? l10n.tooltipUnlike : l10n.tooltipLike,
      padding: padding,
      constraints: constraints,
      icon: Icon(
        isLiked ? Icons.favorite : Icons.favorite_border,
        color: isLiked ? Colors.red : color,
        size: size,
      ),
      onPressed: () => context.read<LikedSongsService>().toggle(song),
    );
  }
}
