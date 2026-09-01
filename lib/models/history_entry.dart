class HistoryEntry {
  final int songId;
  final DateTime playedAt;
  final Duration lastPosition;

  const HistoryEntry({
    required this.songId,
    required this.playedAt,
    this.lastPosition = Duration.zero,
  });

  HistoryEntry copyWith({DateTime? playedAt, Duration? lastPosition}) =>
      HistoryEntry(
        songId: songId,
        playedAt: playedAt ?? this.playedAt,
        lastPosition: lastPosition ?? this.lastPosition,
      );

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
        songId: json['songId'] as int,
        playedAt: DateTime.fromMillisecondsSinceEpoch(json['playedAt'] as int),
        lastPosition:
            Duration(milliseconds: json['lastPositionMs'] as int? ?? 0),
      );

  Map<String, dynamic> toJson() => {
        'songId': songId,
        'playedAt': playedAt.millisecondsSinceEpoch,
        'lastPositionMs': lastPosition.inMilliseconds,
      };
}
