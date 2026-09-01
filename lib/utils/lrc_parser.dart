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
    final match = _lrcLineRe.firstMatch(rawLine.trim());
    if (match == null) continue;
    final minutes = int.parse(match.group(1)!);
    final seconds = int.parse(match.group(2)!);
    final fraction = match.group(3);
    final milliseconds = fraction == null
        ? 0
        : int.parse(fraction.padRight(3, '0').substring(0, 3));
    final text = match.group(4)!.trim();
    lines.add(LrcLine(
      timestamp: Duration(
          minutes: minutes, seconds: seconds, milliseconds: milliseconds),
      text: text,
    ));
  }
  lines.sort((a, b) => a.timestamp.compareTo(b.timestamp));
  return lines;
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
