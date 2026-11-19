import 'song.dart';

/// Een audiobestand dat op het apparaat zelf staat. Wordt nooit naar de
/// server gestuurd; blijft volledig gescheiden van de cloud-muziek.
class LocalTrack {
  /// Absoluut pad naar het bestand op het apparaat.
  final String path;
  final String title;
  final String artist;
  final int sizeBytes;

  const LocalTrack({
    required this.path,
    required this.title,
    required this.artist,
    this.sizeBytes = 0,
  });

  /// Stabiel, altijd negatief id afgeleid van het pad, zodat het nooit
  /// botst met cloud-song-id's (die positief zijn).
  int get id => idForPath(path);

  String get fileName {
    final i = path.lastIndexOf(RegExp(r'[/\\]'));
    return i >= 0 ? path.substring(i + 1) : path;
  }

  String get extension {
    final name = fileName;
    final dot = name.lastIndexOf('.');
    return dot > 0 ? name.substring(dot + 1).toLowerCase() : '';
  }

  /// FNV-1a over het pad, beperkt tot 30 bits en negatief gemaakt.
  static int idForPath(String path) {
    var hash = 0x811c9dc5;
    for (final unit in path.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return -((hash & 0x3FFFFFFF) + 1);
  }

  /// Maakt een titel/artiest uit een bestandsnaam zoals
  /// `Artiest - Titel.mp3`. Zonder ` - ` wordt alles de titel.
  static ({String title, String artist}) parseFileName(String fileName) {
    var base = fileName;
    final dot = base.lastIndexOf('.');
    if (dot > 0) base = base.substring(0, dot);
    base = base.replaceAll('_', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    final sep = base.indexOf(' - ');
    if (sep > 0) {
      final artist = base.substring(0, sep).trim();
      final title = base.substring(sep + 3).trim();
      if (title.isNotEmpty) return (title: title, artist: artist);
    }
    return (title: base.isEmpty ? fileName : base, artist: '');
  }

  factory LocalTrack.fromPath(String path, {int sizeBytes = 0}) {
    final i = path.lastIndexOf(RegExp(r'[/\\]'));
    final name = i >= 0 ? path.substring(i + 1) : path;
    final parsed = parseFileName(name);
    return LocalTrack(
      path: path,
      title: parsed.title,
      artist: parsed.artist,
      sizeBytes: sizeBytes,
    );
  }

  LocalTrack copyWith({
    String? path,
    String? title,
    String? artist,
    int? sizeBytes,
  }) =>
      LocalTrack(
        path: path ?? this.path,
        title: title ?? this.title,
        artist: artist ?? this.artist,
        sizeBytes: sizeBytes ?? this.sizeBytes,
      );

  /// Omzetting naar een [Song] zodat de bestaande speler het kan afspelen.
  /// [Song.isLocal] is true en [Song.audioUrl] is het bestandspad.
  Song toSong() => Song(
        id: id,
        title: title,
        artist: artist,
        genre: '',
        language: '',
        year: 0,
        duration: 0,
        audioUrl: path,
      );

  factory LocalTrack.fromJson(Map<String, dynamic> j) => LocalTrack(
        path: j['path'] as String,
        title: j['title'] as String? ?? '',
        artist: j['artist'] as String? ?? '',
        sizeBytes: (j['size'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'path': path,
        'title': title,
        'artist': artist,
        'size': sizeBytes,
      };
}

/// Afspeellijst die alleen op dit apparaat bestaat. Bewust zonder
/// deel-functionaliteit: lokale bestanden kunnen niet met anderen gedeeld
/// worden, dus de playlist ook niet.
class LocalPlaylist {
  final String id;
  final String name;
  final List<String> paths;

  const LocalPlaylist({
    required this.id,
    required this.name,
    this.paths = const [],
  });

  /// Lokale playlists zijn nooit deelbaar.
  bool get isShareable => false;

  LocalPlaylist copyWith({String? name, List<String>? paths}) => LocalPlaylist(
        id: id,
        name: name ?? this.name,
        paths: paths ?? this.paths,
      );

  factory LocalPlaylist.fromJson(Map<String, dynamic> j) => LocalPlaylist(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        paths: (j['paths'] as List<dynamic>? ?? const [])
            .map((e) => e as String)
            .toList(),
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'paths': paths};
}
