import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:path_provider/path_provider.dart';
import '../constants.dart';
import '../models/song.dart';
import '../models/playlist.dart';

class ApiService {
  late final Dio _dio;
  bool _ready = false;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.apiUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      contentType: 'application/json',
    ));
    _init();
  }

  Future<void> _init() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final jar = PersistCookieJar(
        storage: FileStorage('${dir.path}/.cookies/'),
      );
      _dio.interceptors.add(CookieManager(jar));
    } catch (_) {
      _dio.interceptors.add(CookieManager(DefaultCookieJar()));
    }
    _ready = true;
  }

  Future<void> _wait() async {
    while (!_ready) {
      await Future.delayed(const Duration(milliseconds: 30));
    }
  }

  // ── Auth ──────────────────────────────────────────────────

  Future<Map<String, dynamic>> login(String email, String password) async {
    await _wait();
    final res = await _dio.post('/auth.php',
        data: {'action': 'login', 'email': email, 'password': password});
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> verifyMfa(int userId, String code) async {
    await _wait();
    final res = await _dio.post('/auth.php',
        data: {'action': 'verifyMfa', 'userId': userId, 'code': code});
    return res.data as Map<String, dynamic>;
  }

  Future<void> logout() async {
    await _wait();
    await _dio.post('/auth.php', data: {'action': 'logout'});
  }

  Future<Map<String, dynamic>> checkAuth() async {
    await _wait();
    final res =
        await _dio.post('/auth.php', data: {'action': 'checkAuth'});
    return res.data as Map<String, dynamic>;
  }

  // ── Songs ─────────────────────────────────────────────────

  Future<List<Song>> getSongs({
    String? search,
    String? language,
    String? genre,
    String? year,
  }) async {
    await _wait();
    final params = <String, String>{};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (language != null && language.isNotEmpty) params['language'] = language;
    if (genre != null && genre.isNotEmpty) params['genre'] = genre;
    if (year != null && year.isNotEmpty) params['year'] = year;

    final res = await _dio.get('/songs.php',
        queryParameters: params.isEmpty ? null : params);
    return (res.data as List).map((e) => Song.fromJson(e)).toList();
  }

  Future<Song> getSong(int id) async {
    await _wait();
    final res =
        await _dio.get('/songs.php', queryParameters: {'id': id});
    return Song.fromJson(res.data as Map<String, dynamic>);
  }

  // ── Playlists ─────────────────────────────────────────────

  Future<List<Playlist>> getPlaylists() async {
    await _wait();
    final res = await _dio.get('/playlists.php');
    return (res.data as List).map((e) => Playlist.fromJson(e)).toList();
  }

  Future<Playlist> getPlaylist(int id) async {
    await _wait();
    final res =
        await _dio.get('/playlists.php', queryParameters: {'id': id});
    return Playlist.fromJson(res.data as Map<String, dynamic>);
  }
}
