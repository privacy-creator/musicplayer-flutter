import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../l10n/app_localizations.dart';
import '../models/song.dart';
import '../screens/edit_lyrics_screen.dart';
import '../services/language_service.dart';
import '../services/player_service.dart';
import '../services/translation_service.dart';
import '../utils/lrc_parser.dart';

class LyricsSection extends StatefulWidget {
  final Song song;

  const LyricsSection({super.key, required this.song});

  @override
  State<LyricsSection> createState() => _LyricsSectionState();
}

class _LyricsSectionState extends State<LyricsSection> {
  late Song _song;
  String? _translated;
  bool _showTranslated = false;
  bool _loading = false;
  String? _error;

  List<LrcLine> _lrcLines = [];
  final _lrcScrollCtrl = ScrollController();
  int _lastActiveIndex = -1;
  static const _lrcRowHeight = 34.0;
  static const _lrcViewportHeight = 220.0;

  final _shareKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _song = widget.song;
    _parseLrc();
  }

  @override
  void didUpdateWidget(covariant LyricsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.song.id != widget.song.id) {
      _song = widget.song;
      _translated = null;
      _showTranslated = false;
      _lastActiveIndex = -1;
      _parseLrc();
    }
  }

  @override
  void dispose() {
    _lrcScrollCtrl.dispose();
    super.dispose();
  }

  void _parseLrc() {
    final lrc = _song.lyricsLrc;
    _lrcLines = (lrc != null && lrc.trim().isNotEmpty) ? parseLrc(lrc) : [];
  }

  String? get _plainLyricsForTranslation {
    if (_song.lyrics != null && _song.lyrics!.isNotEmpty) return _song.lyrics;
    if (_lrcLines.isNotEmpty) {
      return _lrcLines.map((l) => l.text).where((t) => t.isNotEmpty).join('\n');
    }
    return null;
  }

  Future<void> _translate(BuildContext context) async {
    final text = _plainLyricsForTranslation;
    if (text == null) return;
    final targetLang = context.read<LanguageService>().locale.languageCode;
    final service = context.read<TranslationService>();
    final l10n = AppL10n.of(context)!;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await service.translate(
        songId: _song.id,
        text: text,
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

  Future<void> _editLyrics(BuildContext context) async {
    final updated = await Navigator.push<Song>(
      context,
      MaterialPageRoute(builder: (_) => EditLyricsScreen(song: _song)),
    );
    if (updated != null && mounted) {
      setState(() {
        _song = updated;
        _lastActiveIndex = -1;
        _parseLrc();
      });
    }
  }

  Future<void> _shareAsImage() async {
    try {
      final boundary = _shareKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 2.5);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/lyrics_share_${_song.id}.png');
      await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: '${_song.title} — ${_song.artist}',
      );
    } catch (_) {}
  }

  void _maybeAutoScroll(int activeIndex) {
    if (activeIndex == _lastActiveIndex || activeIndex < 0) return;
    _lastActiveIndex = activeIndex;
    if (!_lrcScrollCtrl.hasClients) return;
    final target = (activeIndex * _lrcRowHeight) -
        _lrcViewportHeight / 2 +
        _lrcRowHeight / 2;
    _lrcScrollCtrl.animateTo(
      target.clamp(0, _lrcScrollCtrl.position.maxScrollExtent),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final hasPlainLyrics = _song.lyrics != null && _song.lyrics!.isNotEmpty;
    final hasSyncedLyrics = _lrcLines.isNotEmpty;

    if (!hasPlainLyrics && !hasSyncedLyrics) {
      // Still allow adding synced lyrics even when there's nothing yet.
      return Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => _editLyrics(context),
            icon: const Icon(Icons.lyrics_outlined, size: 16),
            label: Text(l10n.editLyricsLrc),
          ),
        ),
      );
    }

    return RepaintBoundary(
      key: _shareKey,
      child: Container(
        color: colorScheme.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 36),
            const Divider(),
            const SizedBox(height: 20),

            // Header row: "Lyrics" label + translate / show-original + menu
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
                else if (_plainLyricsForTranslation != null)
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
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_horiz,
                      size: 18, color: colorScheme.onSurfaceVariant),
                  onSelected: (value) {
                    if (value == 'edit') _editLyrics(context);
                    if (value == 'share') _shareAsImage();
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text(l10n.editLyricsLrc),
                    ),
                    PopupMenuItem(
                      value: 'share',
                      child: Text(l10n.shareAsImage),
                    ),
                  ],
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
            ] else if (hasSyncedLyrics)
              _SyncedLyrics(
                lines: _lrcLines,
                song: _song,
                rowHeight: _lrcRowHeight,
                viewportHeight: _lrcViewportHeight,
                scrollController: _lrcScrollCtrl,
                onActiveIndex: _maybeAutoScroll,
              )
            else
              Text(
                _song.lyrics!,
                style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                    height: 1.8,
                    fontSize: 14),
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SyncedLyrics extends StatelessWidget {
  final List<LrcLine> lines;
  final Song song;
  final double rowHeight;
  final double viewportHeight;
  final ScrollController scrollController;
  final ValueChanged<int> onActiveIndex;

  const _SyncedLyrics({
    required this.lines,
    required this.song,
    required this.rowHeight,
    required this.viewportHeight,
    required this.scrollController,
    required this.onActiveIndex,
  });

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerService>();
    final isCurrentSong = player.currentSong?.id == song.id;
    final activeIndex = isCurrentSong
        ? activeLrcLineIndex(lines, player.position)
        : -1;

    WidgetsBinding.instance
        .addPostFrameCallback((_) => onActiveIndex(activeIndex));

    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: viewportHeight,
      child: ListView.builder(
        controller: scrollController,
        itemExtent: rowHeight,
        itemCount: lines.length,
        itemBuilder: (context, i) {
          final isActive = i == activeIndex;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              lines[i].text,
              style: TextStyle(
                fontSize: isActive ? 16 : 14,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive
                    ? colorScheme.primary
                    : colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          );
        },
      ),
    );
  }
}
