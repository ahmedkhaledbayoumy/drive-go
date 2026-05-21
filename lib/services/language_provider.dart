import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _prefsKey = 'language_code';

  Locale _locale = const Locale('en');
  Locale get locale => _locale;

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey) ?? 'en';
    _locale = Locale(code);
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, locale.languageCode);
  }

  Future<void> toggle() async {
    final newLocale =
        _locale.languageCode == 'en' ? const Locale('ar') : const Locale('en');
    await setLocale(newLocale);
  }
}
