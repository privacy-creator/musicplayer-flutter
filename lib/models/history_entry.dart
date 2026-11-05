class HistoryEntry {
  final int songId;
  final DateTime playedAt;
  final Duration lastPosition;
  final int playCount;

  const HistoryEntry({
    required this.songId,
    required this.playedAt,
    this.lastPosition = Duration.zero,
    this.playCount = 1,
  });

  HistoryEntry copyWith({
    DateTime? playedAt,
    Duration? lastPosition,
    int? playCount,
  }) =>
      HistoryEntry(
        songId: songId,
        playedAt: playedAt ?? this.playedAt,
        lastPosition: lastPosition ?? this.lastPosition,
        playCount: playCount ?? this.playCount,
      );

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
        songId: json['songId'] as int,
        playedAt: DateTime.fromMillisecondsSinceEpoch(json['playedAt'] as int),
        lastPosition:
            Duration(milliseconds: json['lastPositionMs'] as int? ?? 0),
        playCount: json['playCount'] as int? ?? 1,
      );

  Map<String, dynamic> toJson() => {
        'songId': songId,
        'playedAt': playedAt.millisecondsSinceEpoch,
        'lastPositionMs': lastPosition.inMilliseconds,
        'playCount': playCount,
      };
}
