import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../constants.dart';

class UpdateService extends ChangeNotifier {
  final Future<String?> Function()? _fetchLatestTag;

  String _currentVersion = '';
  String? _latestVersion;
  bool _isChecking = false;

  UpdateService({Future<String?> Function()? fetchLatestTag})
      : _fetchLatestTag = fetchLatestTag;

  String get currentVersion => _currentVersion;
  String? get latestVersion => _latestVersion;
  bool get isChecking => _isChecking;

  bool get hasUpdate {
    if (_latestVersion == null || _currentVersion.isEmpty) return false;
    return _latestVersion != _currentVersion;
  }

  Future<void> init() async {
    final info = await PackageInfo.fromPlatform();
    _currentVersion = info.version;
    notifyListeners();
    await checkForUpdates();
  }

  Future<void> checkForUpdates() async {
    if (_isChecking) return;
    _isChecking = true;
    notifyListeners();
    try {
      final tag = await (_fetchLatestTag?.call() ?? _defaultFetch());
      _latestVersion = tag?.replaceFirst(RegExp(r'^v'), '');
    } catch (_) {
      _latestVersion = null;
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }

  static Future<String?> _defaultFetch() async {
    final dio = Dio();
    final response = await dio.get<Map<String, dynamic>>(
      AppConstants.githubApiLatestUrl,
    );
    return response.data?['tag_name'] as String?;
  }
}
