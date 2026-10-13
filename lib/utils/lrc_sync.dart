import 'lrc_parser.dart';

/// LRC metadata tags such as `[ar:Artist]` or `[length:03:20]`.
final _metaTagRe = RegExp(r'^\[[a-zA-Z#]+:.*\]$');

class _SyncEdit {
  final int index;
  final Duration? previousTime;
  final int previousCurrent;

  const _SyncEdit(this.index, this.previousTime, this.previousCurrent);
}

/// State for the "sync line by line" tool: a list of lyric lines, each with an
/// optional timestamp, plus a cursor on the line that the next tap will stamp.
///
/// Pure Dart so it can be unit-tested without a player.
class LrcSyncSession {
  final List<String> _texts;
  final List<Duration?> _times;
  final List<_SyncEdit> _undo = [];
  int _current;

  static const nudgeStep = Duration(milliseconds: 100);

  LrcSyncSession._(this._texts, this._times)
      : _current = _firstUnstamped(_times);

  /// Builds a session from LRC or plain text. Timed lines keep their time,
  /// plain lines start unsynced; blank lines and metadata tags are dropped.
  factory LrcSyncSession.fromText(String raw) {
    final texts = <String>[];
    final times = <Duration?>[];
    for (final rawLine in raw.split('\n')) {
      final trimmed = rawLine.trim();
      final timed = parseLrcLine(trimmed);
      if (timed != null) {
        texts.add(timed.text);
        times.add(timed.timestamp);
      } else if (trimmed.isNotEmpty && !_metaTagRe.hasMatch(trimmed)) {
        texts.add(trimmed);
        times.add(null);
      }
    }
    return LrcSyncSession._(texts, times);
  }

  static int _firstUnstamped(List<Duration?> times) {
    final i = times.indexOf(null);
    return i == -1 ? 0 : i;
  }

  int get length => _texts.length;
  bool get isEmpty => _texts.isEmpty;

  /// Line the next [stamp] applies to; equals [length] once the last line
  /// has been stamped.
  int get current => _current;
  bool get isFinished => _current >= _texts.length;

  String textAt(int i) => _texts[i];
  Duration? timeAt(int i) => _times[i];
  int get stampedCount => _times.where((t) => t != null).length;
  bool get canUndo => _undo.isNotEmpty;

  /// True when line [i] is timed earlier than a timed line above it.
  bool isOutOfOrder(int i) {
    final t = _times[i];
    if (t == null) return false;
    for (var j = i - 1; j >= 0; j--) {
      final prev = _times[j];
      if (prev != null) return t < prev;
    }
    return false;
  }

  void select(int i) {
    if (i < 0 || i >= _texts.length) return;
    _current = i;
  }

  /// Sets the current line's time to [position] and moves to the next line.
  /// Returns false when every line has already been passed.
  bool stamp(Duration position) {
    if (isFinished) return false;
    _record(_current);
    _times[_current] = position.isNegative ? Duration.zero : position;
    _current++;
    return true;
  }

  /// Shifts line [i]'s time by [delta] (clamped at zero); no-op if unsynced.
  void nudge(int i, Duration delta) {
    final t = _times[i];
    if (t == null) return;
    _record(i);
    final next = t + delta;
    _times[i] = next.isNegative ? Duration.zero : next;
  }

  void clear(int i) {
    if (_times[i] == null) return;
    _record(i);
    _times[i] = null;
  }

  /// Reverts the last stamp, nudge or clear, including the cursor position.
  void undo() {
    if (_undo.isEmpty) return;
    final edit = _undo.removeLast();
    _times[edit.index] = edit.previousTime;
    _current = edit.previousCurrent;
  }

  void _record(int i) => _undo.add(_SyncEdit(i, _times[i], _current));

  /// Serialises back to LRC in line order. Unsynced lines are kept as plain
  /// text so they can still be synced later.
  String toLrc() {
    final out = StringBuffer();
    for (var i = 0; i < _texts.length; i++) {
      if (i > 0) out.write('\n');
      final t = _times[i];
      if (t == null) {
        out.write(_texts[i]);
      } else {
        out.write(formatLrcTimestamp(t));
        if (_texts[i].isNotEmpty) out.write(' ${_texts[i]}');
      }
    }
    return out.toString();
  }
}
