import '../constants.dart';

class Song {
  final int id;
  final String title;
  final String artist;
  final String genre;
  final String language;
  final int year;
  final int duration;
  final String audioUrl;
  final String? imageUrl;
  final String? lyrics;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.genre,
    required this.language,
    required this.year,
    required this.duration,
    required this.audioUrl,
    this.imageUrl,
    this.lyrics,
  });

  factory Song.fromJson(Map<String, dynamic> j) => Song(
    id: j['id'] as int,
    title: j['title'] as String? ?? '',
    artist: j['artist'] as String? ?? '',
    genre: j['genre'] as String? ?? '',
    language: j['language'] as String? ?? '',
    year: (j['year'] as num?)?.toInt() ?? 0,
    duration: (j['duration'] as num?)?.toInt() ?? 0,
    audioUrl: AppConstants.fixUrl(j['audio_url'] as String? ?? ''),
    imageUrl: j['image_url'] != null
        ? AppConstants.fixUrl(j['image_url'] as String)
        : null,
    lyrics: j['lyrics'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'artist': artist,
    'genre': genre,
    'language': language,
    'year': year,
    'duration': duration,
    'audio_url': audioUrl,
    'image_url': imageUrl,
    'lyrics': lyrics,
  };

  String get formattedDuration {
    final m = duration ~/ 60;
    final s = duration % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
