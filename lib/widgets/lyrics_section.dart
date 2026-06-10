import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/song.dart';
import '../services/language_service.dart';
import '../services/translation_service.dart';

class LyricsSection extends StatefulWidget {
  final Song song;

  const LyricsSection({super.key, required this.song});

  @override
  State<LyricsSection> createState() => _LyricsSectionState();
}

class _LyricsSectionState extends State<LyricsSection> {
  String? _translated;
  bool _showTranslated = false;
  bool _loading = false;
  String? _error;

  Future<void> _translate(BuildContext context) async {
    final targetLang = context.read<LanguageService>().locale.languageCode;
    final service = context.read<TranslationService>();
    final l10n = AppL10n.of(context)!;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await service.translate(
        songId: widget.song.id,
        text: widget.song.lyrics!,
        targetLang: targetLang,
      );
      if (mounted) {
        setState(() {
          _translated = result;
          _showTranslated = true;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = l10n.translateError;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final lyrics = widget.song.lyrics;

    if (lyrics == null || lyrics.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 36),
        const Divider(),
        const SizedBox(height: 20),

        // Header row: "Lyrics" label + translate / show-original button
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.lyrics,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            if (_loading)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(l10n.translating,
                      style: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                          fontSize: 12)),
                ],
              )
            else if (_showTranslated && _translated != null)
              TextButton(
                onPressed: () => setState(() => _showTranslated = false),
                child: Text(l10n.showOriginal,
                    style: TextStyle(color: colorScheme.primary, fontSize: 12)),
              )
            else
              TextButton.icon(
                onPressed: () => _translate(context),
                icon: Icon(Icons.translate, size: 14, color: colorScheme.primary),
                label: Text(l10n.translateLyrics,
                    style: TextStyle(color: colorScheme.primary, fontSize: 12)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
          ],
        ),

        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.error, fontSize: 12)),
        ],

        const SizedBox(height: 14),

        // Lyrics body
        if (_showTranslated && _translated != null) ...[
          Text(
            l10n.translatedLyrics.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1,
              color: colorScheme.onSurface.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.info_outline,
                  size: 12,
                  color: colorScheme.onSurface.withValues(alpha: 0.4)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  l10n.translationDisclaimer,
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _translated!,
            style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.85),
                height: 1.8,
                fontSize: 14),
          ),
        ] else
          Text(
            lyrics,
            style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.8,
                fontSize: 14),
          ),

        const SizedBox(height: 24),
      ],
    );
  }
}
