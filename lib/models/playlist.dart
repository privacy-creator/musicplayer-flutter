import 'song.dart';

class Playlist {
  final int id;
  final String name;
  final String? description;
  final List<Song> songs;

  const Playlist({
    required this.id,
    required this.name,
    this.description,
    this.songs = const [],
  });

  factory Playlist.fromJson(Map<String, dynamic> j) {
    final rawSongs = j['songs'] as List<dynamic>? ?? [];
    return Playlist(
      id: j['id'] as int,
      name: j['name'] as String? ?? '',
      description: j['description'] as String?,
      songs: rawSongs.map((s) => Song.fromJson(s as Map<String, dynamic>)).toList(),
    );
  }
}
