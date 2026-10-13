class LrcLine {
  final Duration timestamp;
  final String text;

  const LrcLine({required this.timestamp, required this.text});
}

final _lrcLineRe = RegExp(r'^\[(\d{1,2}):(\d{2})(?:[.:](\d{1,3}))?\](.*)$');

/// Parses standard `[mm:ss.xx]text` LRC lyrics into timestamped lines.
/// Lines that don't match the timestamp pattern (e.g. metadata tags like
/// `[ar:Artist]`) are skipped. Returns lines sorted by timestamp.
List<LrcLine> parseLrc(String raw) {
  final lines = <LrcLine>[];
  for (final rawLine in raw.split('\n')) {
    final line = parseLrcLine(rawLine);
    if (line != null) lines.add(line);
  }
  lines.sort((a, b) => a.timestamp.compareTo(b.timestamp));
  return lines;
}

/// Parses a single `[mm:ss.xx]text` line, or returns null if it has no
/// leading timestamp.
LrcLine? parseLrcLine(String rawLine) {
  final match = _lrcLineRe.firstMatch(rawLine.trim());
  if (match == null) return null;
  final minutes = int.parse(match.group(1)!);
  final seconds = int.parse(match.group(2)!);
  final fraction = match.group(3);
  final milliseconds = fraction == null
      ? 0
      : int.parse(fraction.padRight(3, '0').substring(0, 3));
  return LrcLine(
    timestamp:
        Duration(minutes: minutes, seconds: seconds, milliseconds: milliseconds),
    text: match.group(4)!.trim(),
  );
}

/// Formats [d] as an LRC timestamp `[mm:ss.xx]` (centisecond precision,
/// truncated so that [parseLrcLine] round-trips it exactly).
String formatLrcTimestamp(Duration d) {
  if (d.isNegative) d = Duration.zero;
  final minutes = d.inMinutes.toString().padLeft(2, '0');
  final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
  final centis = ((d.inMilliseconds % 1000) ~/ 10).toString().padLeft(2, '0');
  return '[$minutes:$seconds.$centis]';
}

/// Strips `[mm:ss.xx]` timestamps, returning the plain lyric text —
/// used when translating LRC lyrics that have no separate plain-text field.
String stripLrcTimestamps(String raw) {
  return raw
      .split('\n')
      .map((line) {
        final match = _lrcLineRe.firstMatch(line.trim());
        return (match?.group(4) ?? line).trim();
      })
      .where((line) => line.isNotEmpty)
      .join('\n');
}

/// Index of the currently active line for [position], or -1 if before the
/// first line / there are no lines.
int activeLrcLineIndex(List<LrcLine> lines, Duration position) {
  var index = -1;
  for (var i = 0; i < lines.length; i++) {
    if (lines[i].timestamp <= position) {
      index = i;
    } else {
      break;
    }
  }
  return index;
}
