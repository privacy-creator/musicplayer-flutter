import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/song.dart';
import '../services/api_service.dart';
import 'lrc_sync_screen.dart';

class EditLyricsScreen extends StatefulWidget {
  final Song song;

  /// Overrides the player used by the sync tool (tests only).
  final SyncPlayback? syncPlayback;

  const EditLyricsScreen({super.key, required this.song, this.syncPlayback});

  @override
  State<EditLyricsScreen> createState() => _EditLyricsScreenState();
}

class _EditLyricsScreenState extends State<EditLyricsScreen> {
  late final TextEditingController _ctrl;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.song.lyricsLrc ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// Opens the tap-along sync tool on the editor's text, falling back to the
  /// song's plain lyrics when the editor is still empty.
  Future<void> _openSyncTool() async {
    final source = _ctrl.text.trim().isNotEmpty
        ? _ctrl.text
        : (widget.song.lyrics ?? '');
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => LrcSyncScreen(
          song: widget.song,
          initialText: source,
          playback: widget.syncPlayback,
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() => _ctrl.text = result);
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final lrc = _ctrl.text;
    try {
      await context.read<ApiService>().updateSongLyricsLrc(widget.song, lrc);
      if (mounted) {
        final l10n = AppL10n.of(context)!;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.lyricsSaved)));
        Navigator.pop(
          context,
          Song(
            id: widget.song.id,
            title: widget.song.title,
            artist: widget.song.artist,
            genre: widget.song.genre,
            language: widget.song.language,
            year: widget.song.year,
            duration: widget.song.duration,
            audioUrl: widget.song.audioUrl,
            imageUrl: widget.song.imageUrl,
            lyrics: widget.song.lyrics,
            lyricsLrc: lrc,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        final l10n = AppL10n.of(context)!;
        setState(() {
          _saving = false;
          _error = l10n.lyricsSaveError;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.editLyricsLrc),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(l10n.save),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_error!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: FilledButton.tonalIcon(
                key: const Key('open-sync-tool'),
                onPressed: _saving ? null : _openSyncTool,
                icon: const Icon(Icons.touch_app),
                label: Text(l10n.syncLyricsTool),
              ),
            ),
            Expanded(
              child: TextField(
                controller: _ctrl,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                decoration: InputDecoration(
                  hintText: l10n.lyricsLrcHint,
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
