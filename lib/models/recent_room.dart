class RecentRoom {
  final String code;
  final DateTime lastJoined;

  const RecentRoom({required this.code, required this.lastJoined});

  factory RecentRoom.fromJson(Map<String, dynamic> json) => RecentRoom(
        code: json['code'] as String,
        lastJoined:
            DateTime.fromMillisecondsSinceEpoch(json['lastJoined'] as int),
      );

  Map<String, dynamic> toJson() => {
        'code': code,
        'lastJoined': lastJoined.millisecondsSinceEpoch,
      };
}
