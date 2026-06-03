import 'package:flutter/foundation.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  final ApiService _api;

  bool _isAuthenticated = false;
  bool _isAdmin = false;

  AuthService(this._api);

  bool get isAuthenticated => _isAuthenticated;
  bool get isAdmin => _isAdmin;

  Future<Map<String, dynamic>> login(String email, String password) async {
    final data = await _api.login(email, password);
    if (data['success'] == true && data['mfaRequired'] != true) {
      _isAuthenticated = true;
      _isAdmin = data['isAdmin'] == true;
      notifyListeners();
    }
    return data;
  }

  Future<void> verifyMfa(int userId, String code) async {
    final data = await _api.verifyMfa(userId, code);
    if (data['success'] == true) {
      _isAuthenticated = true;
      _isAdmin = data['isAdmin'] == true;
      notifyListeners();
    } else {
      throw Exception(data['message'] ?? 'Verification failed');
    }
  }

  Future<void> logout() async {
    await _api.logout();
    _isAuthenticated = false;
    _isAdmin = false;
    notifyListeners();
  }

  Future<void> checkAuth() async {
    try {
      final data = await _api.checkAuth();
      if (data['success'] == true) {
        _isAuthenticated = true;
        _isAdmin = data['isAdmin'] == true;
        notifyListeners();
      }
    } catch (_) {
      _isAuthenticated = false;
    }
  }
}
