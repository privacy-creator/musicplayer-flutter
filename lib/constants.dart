class AppConstants {
  // Android emulator → 10.0.2.2 reaches the host machine
  // Physical device → use your LAN IP, e.g. http://192.168.1.x/backend
  static const String baseUrl = 'http://10.0.2.2/backend';
  static const String apiUrl = '$baseUrl/api';

  // Rewrite URLs that contain localhost/127.0.0.1 so they work inside the emulator/device
  static String fixUrl(String url) {
    if (url.isEmpty) return url;
    final origin = Uri.parse(baseUrl).origin; // e.g. 'http://10.0.2.2'
    return url
        .replaceFirst('http://localhost', origin)
        .replaceFirst('http://127.0.0.1', origin);
  }
}
