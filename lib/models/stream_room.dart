class StreamParticipant {
  final int id;
  final String email;

  const StreamParticipant({required this.id, required this.email});

  factory StreamParticipant.fromJson(Map<String, dynamic> json) =>
      StreamParticipant(
        id: json['id'] as int,
        email: json['email'] as String? ?? '',
      );
}

class StreamRoom {
  final int id;
  final int hostId;
  final String roomCode;
  final int? currentTrackId;
  final double position;
  final bool isPlaying;
  final List<StreamParticipant> participants;

  const StreamRoom({
    required this.id,
    required this.hostId,
    required this.roomCode,
    this.currentTrackId,
    required this.position,
    required this.isPlaying,
    required this.participants,
  });

  factory StreamRoom.fromJson(Map<String, dynamic> json) => StreamRoom(
        id: json['id'] as int,
        hostId: json['host_id'] as int,
        roomCode: json['room_code'] as String,
        currentTrackId: json['current_track_id'] as int?,
        position: (json['position'] as num).toDouble(),
        isPlaying: json['is_playing'] == true || json['is_playing'] == 1,
        participants: (json['participants'] as List? ?? [])
            .cast<Map<String, dynamic>>()
            .map(StreamParticipant.fromJson)
            .toList(),
      );

  StreamRoom copyWith({
    int? id,
    int? hostId,
    String? roomCode,
    Object? currentTrackId = _sentinel,
    double? position,
    bool? isPlaying,
    List<StreamParticipant>? participants,
  }) =>
      StreamRoom(
        id: id ?? this.id,
        hostId: hostId ?? this.hostId,
        roomCode: roomCode ?? this.roomCode,
        currentTrackId: currentTrackId == _sentinel
            ? this.currentTrackId
            : currentTrackId as int?,
        position: position ?? this.position,
        isPlaying: isPlaying ?? this.isPlaying,
        participants: participants ?? this.participants,
      );
}

// Sentinel to distinguish "not passed" from explicit null in copyWith.
const Object _sentinel = Object();
