import '../models/history_entry.dart';
import '../models/song.dart';

enum SmartPlaylistKind {
  mostPlayed,
  forgottenFavorites,
  neverPlayed,
  newThisYear,
  genreMix,
}

class SmartPlaylist {
  final SmartPlaylistKind kind;
  final List<Song> songs;

  /// Genre for [SmartPlaylistKind.genreMix], year for
  /// [SmartPlaylistKind.newThisYear]; empty otherwise.
  final String label;

  const SmartPlaylist(this.kind, this.songs, {this.label = ''});
}

const _maxSongs = 50;
const _forgottenAfter = Duration(days: 30);

/// Builds the auto-generated playlists from the catalogue, the local
/// listening history and liked songs. Empty playlists are left out.
List<SmartPlaylist> buildSmartPlaylists({
  required List<Song> songs,
  required List<HistoryEntry> history,
  required List<Song> liked,
  DateTime? now,
}) {
  now ??= DateTime.now();
  final byId = {for (final s in songs) s.id: s};
  final historyById = {for (final e in history) e.songId: e};

  final mostPlayed = (history.where((e) => byId.containsKey(e.songId)).toList()
        ..sort((a, b) {
          final byCount = b.playCount.compareTo(a.playCount);
          return byCount != 0 ? byCount : b.playedAt.compareTo(a.playedAt);
        }))
      .take(_maxSongs)
      .map((e) => byId[e.songId]!)
      .toList();

  final cutoff = now.subtract(_forgottenAfter);
  final forgotten = liked.where((s) {
    final entry = historyById[s.id];
    return entry == null || entry.playedAt.isBefore(cutoff);
  }).toList();

  final neverPlayed =
      songs.where((s) => !historyById.containsKey(s.id)).toList();

  final year = now.year;
  final newThisYear = songs.where((s) => s.year == year).toList();

  // Genre weighted by how often its songs were played.
  final genrePlays = <String, int>{};
  for (final e in history) {
    final genre = byId[e.songId]?.genre ?? '';
    if (genre.isEmpty) continue;
    genrePlays[genre] = (genrePlays[genre] ?? 0) + e.playCount;
  }
  String? topGenre;
  for (final entry in genrePlays.entries) {
    if (topGenre == null || entry.value > genrePlays[topGenre]!) {
      topGenre = entry.key;
    }
  }
  final genreMix = topGenre == null
      ? <Song>[]
      : songs.where((s) => s.genre == topGenre).toList();

  return [
    SmartPlaylist(SmartPlaylistKind.mostPlayed, mostPlayed),
    if (topGenre != null)
      SmartPlaylist(SmartPlaylistKind.genreMix, genreMix, label: topGenre),
    SmartPlaylist(SmartPlaylistKind.forgottenFavorites, forgotten),
    SmartPlaylist(SmartPlaylistKind.newThisYear, newThisYear,
        label: '$year'),
    SmartPlaylist(SmartPlaylistKind.neverPlayed, neverPlayed),
  ].where((p) => p.songs.isNotEmpty).toList();
}
