class AppConstants {
  static const String baseUrl = 'https://api.hiddebalestra.nl/muziek';
  static const String apiUrl = '$baseUrl/api';
  static const String websiteUrl = 'https://www.awake-music.co';
  static const String wsUrl = 'wss://api.hiddebalestra.nl:8080';
  static const String githubReleasesUrl =
      'https://github.com/privacy-creator/musicplayer-flutter/releases';
  static const String githubApiLatestUrl =
      'https://api.github.com/repos/privacy-creator/musicplayer-flutter/releases/latest';

  // Rewrite legacy local dev URLs to the production server.
  // Replaces the full old base (host + /backend path) so the uploads path resolves correctly.
  static String fixUrl(String url) {
    if (url.isEmpty) return url;
    const oldBases = [
      'http://localhost/backend',
      'http://127.0.0.1/backend',
      'http://10.0.2.2/backend',
    ];
    for (final old in oldBases) {
      if (url.startsWith(old)) {
        return baseUrl + url.substring(old.length);
      }
    }
    return url;
  }
}
