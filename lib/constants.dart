class AppConstants {
  static const String baseUrl = 'https://api.hiddebalestra.nl/muziek';
  static const String apiUrl = '$baseUrl/api';

  // Rewrite legacy localhost/127.0.0.1 URLs to the production host
  static String fixUrl(String url) {
    if (url.isEmpty) return url;
    final origin = Uri.parse(baseUrl).origin; // 'https://api.hiddebalestra.nl'
    return url
        .replaceFirst('http://localhost', origin)
        .replaceFirst('http://127.0.0.1', origin);
  }
}
