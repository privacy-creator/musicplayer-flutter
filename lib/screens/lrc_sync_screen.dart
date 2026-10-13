import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/song.dart';
import '../services/player_service.dart';
import '../utils/lrc_parser.dart';
import '../utils/lrc_sync.dart';

/// The bits of playback the sync tool needs; abstracted so the screen can be
/// widget-tested without a real audio player.
abstract class SyncPlayback implements Listenable {
  Stream<Duration> get positionStream;
  Duration get position;
  bool get isPlaying;

  /// Whether the song being synced is the one loaded in the player.
  bool get isSongLoaded;
  Future<void> playSong();
  Future<void> togglePlayPause();
  Future<void> seek(Duration position);
}

class PlayerSyncPlayback implements SyncPlayback {
  final PlayerService player;
  final Song song;

  PlayerSyncPlayback(this.player, this.song);

  @override
  void addListener(VoidCallback listener) => player.addListener(listener);
  @override
  void removeListener(VoidCallback listener) => player.removeListener(listener);
  @override
  Stream<Duration> get positionStream => player.positionStream;
  @override
  Duration get position => player.position;
  @override
  bool get isPlaying => player.isPlaying;
  @override
  bool get isSongLoaded => player.currentSong?.id == song.id;
  @override
  Future<void> playSong() => player.playSong(song, [song], 0);
  @override
  Future<void> togglePlayPause() => player.togglePlayPause();
  @override
  Future<void> seek(Duration position) => player.seek(position);
}

/// Tap-along tool: play the song and tap once per line to timestamp it.
/// Pops with the resulting LRC text, or null when left without "Done".
class LrcSyncScreen extends StatefulWidget {
  final Song song;
  final String initialText;
  final SyncPlayback? playback;

  const LrcSyncScreen({
    super.key,
    required this.song,
    required this.initialText,
    this.playback,
  });

  @override
  State<LrcSyncScreen> createState() => _LrcSyncScreenState();
}

class _LrcSyncScreenState extends State<LrcSyncScreen> {
  late final LrcSyncSession _session;
  late final SyncPlayback _playback;
  final _scrollCtrl = ScrollController();

  static const _rowHeight = 56.0;

  @override
  void initState() {
    super.initState();
    _session = LrcSyncSession.fromText(widget.initialText);
    _playback = widget.playback ??
        PlayerSyncPlayback(context.read<PlayerService>(), widget.song);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _stamp() {
    setState(() => _session.stamp(_playback.position));
    _scrollToCurrent();
  }

  void _undo() {
    setState(_session.undo);
    _scrollToCurrent();
  }

  void _scrollToCurrent() {
    if (!_scrollCtrl.hasClients) return;
    final target = (_session.current - 2) * _rowHeight;
    _scrollCtrl.animateTo(
      target.clamp(0.0, _scrollCtrl.position.maxScrollExtent),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  void _seekRelative(Duration delta) {
    final next = _playback.position + delta;
    _playback.seek(next.isNegative ? Duration.zero : next);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.syncLyricsTool),
        actions: [
          IconButton(
            key: const Key('sync-undo'),
            tooltip: l10n.syncUndo,
            icon: const Icon(Icons.undo),
            onPressed: _session.canUndo ? _undo : null,
          ),
          TextButton(
            key: const Key('sync-done'),
            onPressed: _session.isEmpty
                ? null
                : () => Navigator.pop(context, _session.toLrc()),
            child: Text(l10n.syncDone),
          ),
        ],
      ),
      body: _session.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l10n.syncNoLines,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colorScheme.onSurfaceVariant)),
              ),
            )
          : ListenableBuilder(
              listenable: _playback,
              builder: (context, _) => Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text(l10n.syncLyricsHelp,
                        style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant)),
                  ),
                  if (!_playback.isSongLoaded)
                    _PlaySongBanner(onPlay: _playback.playSong),
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollCtrl,
                      itemExtent: _rowHeight,
                      itemCount: _session.length,
                      itemBuilder: (context, i) => _SyncLineRow(
                        index: i,
                        session: _session,
                        selected: i == _session.current,
                        onSelect: () => setState(() => _session.select(i)),
                        onSeek: (t) => _playback.seek(t),
                        onNudge: (d) => setState(() => _session.nudge(i, d)),
                        onClear: () => setState(() => _session.clear(i)),
                      ),
                    ),
                  ),
                  _ControlsPanel(
                    session: _session,
                    playback: _playback,
                    onStamp: _playback.isSongLoaded && !_session.isFinished
                        ? _stamp
                        : null,
                    onSeekRelative: _seekRelative,
                  ),
                ],
              ),
            ),
    );
  }
}

const _seekStep = Duration(seconds: 5);

String _formatTime(Duration d) =>
    formatLrcTimestamp(d).substring(1, 9); // strip the brackets

class _PlaySongBanner extends StatelessWidget {
  final Future<void> Function() onPlay;

  const _PlaySongBanner({required this.onPlay});

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(l10n.syncPlaySongHint,
                style: TextStyle(
                    fontSize: 13, color: colorScheme.onSecondaryContainer)),
          ),
          TextButton.icon(
            key: const Key('sync-play-song'),
            onPressed: onPlay,
            icon: const Icon(Icons.play_arrow),
            label: Text(l10n.syncPlaySong),
          ),
        ],
      ),
    );
  }
}

class _SyncLineRow extends StatelessWidget {
  final int index;
  final LrcSyncSession session;
  final bool selected;
  final VoidCallback onSelect;
  final ValueChanged<Duration> onSeek;
  final ValueChanged<Duration> onNudge;
  final VoidCallback onClear;

  const _SyncLineRow({
    required this.index,
    required this.session,
    required this.selected,
    required this.onSelect,
    required this.onSeek,
    required this.onNudge,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final time = session.timeAt(index);
    final outOfOrder = session.isOutOfOrder(index);
    final text = session.textAt(index);

    return Material(
      color: selected
          ? colorScheme.primary.withValues(alpha: 0.15)
          : Colors.transparent,
      child: InkWell(
        key: Key('sync-line-$index'),
        onTap: onSelect,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              TextButton(
                key: Key('sync-time-$index'),
                onPressed: time == null ? null : () => onSeek(time),
                style: TextButton.styleFrom(
                  minimumSize: const Size(84, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                ),
                child: Text(
                  time == null ? '--:--.--' : _formatTime(time),
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: outOfOrder
                        ? colorScheme.error
                        : time == null
                            ? colorScheme.onSurfaceVariant
                            : colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  text.isEmpty ? '♪' : text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    color: selected ? colorScheme.primary : null,
                  ),
                ),
              ),
              if (selected && time != null) ...[
                IconButton(
                  key: Key('sync-nudge-minus-$index'),
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.remove, size: 18),
                  tooltip: '-0.1s',
                  onPressed: () => onNudge(-LrcSyncSession.nudgeStep),
                ),
                IconButton(
                  key: Key('sync-nudge-plus-$index'),
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.add, size: 18),
                  tooltip: '+0.1s',
                  onPressed: () => onNudge(LrcSyncSession.nudgeStep),
                ),
                IconButton(
                  key: Key('sync-clear-$index'),
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: l10n.syncClearTime,
                  onPressed: onClear,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ControlsPanel extends StatelessWidget {
  final LrcSyncSession session;
  final SyncPlayback playback;
  final VoidCallback? onStamp;
  final ValueChanged<Duration> onSeekRelative;

  const _ControlsPanel({
    required this.session,
    required this.playback,
    required this.onStamp,
    required this.onSeekRelative,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final loaded = playback.isSongLoaded;

    return Material(
      elevation: 4,
      color: colorScheme.surfaceContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.syncProgress(session.stampedCount, session.length),
                      style: TextStyle(
                          fontSize: 12, color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                  StreamBuilder<Duration>(
                    stream: loaded ? playback.positionStream : null,
                    builder: (context, snap) => Text(
                      loaded
                          ? _formatTime(snap.data ?? playback.position)
                          : '--:--.--',
                      key: const Key('sync-position'),
                      style: const TextStyle(
                          fontFamily: 'monospace', fontSize: 13),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    key: const Key('sync-rewind'),
                    icon: const Icon(Icons.replay_5),
                    onPressed: loaded
                        ? () => onSeekRelative(-_seekStep)
                        : null,
                  ),
                  IconButton(
                    key: const Key('sync-play-pause'),
                    iconSize: 36,
                    icon: Icon(playback.isPlaying && loaded
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled),
                    onPressed: loaded ? playback.togglePlayPause : null,
                  ),
                  IconButton(
                    key: const Key('sync-forward'),
                    icon: const Icon(Icons.forward_5),
                    onPressed: loaded
                        ? () => onSeekRelative(_seekStep)
                        : null,
                  ),
                ],
              ),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  key: const Key('sync-stamp'),
                  onPressed: onStamp,
                  icon: const Icon(Icons.touch_app),
                  label: Text(l10n.syncSetTime,
                      style: const TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
