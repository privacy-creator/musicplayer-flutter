import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _localeKey = 'app_locale';

class LanguageService extends ChangeNotifier {
  final SharedPreferences _prefs;
  late Locale _locale;

  LanguageService(this._prefs) {
    final saved = _prefs.getString(_localeKey);
    _locale = saved != null ? Locale(saved) : const Locale('nl');
  }

  Locale get locale => _locale;

  static const supportedLocales = [
    Locale('nl'),
    Locale('en'),
    Locale('es'),
    Locale('de'),
    Locale('it'),
  ];

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    await _prefs.setString(_localeKey, locale.languageCode);
    notifyListeners();
  }
}
