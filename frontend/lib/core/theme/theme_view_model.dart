import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the light/dark preference and remembers it across restarts.
class ThemeViewModel extends ChangeNotifier {
  ThemeViewModel(this._prefs)
    : _mode = (_prefs.getBool(_key) ?? false) ? ThemeMode.dark : ThemeMode.light;

  static const _key = 'dark_mode';

  final SharedPreferences _prefs;
  ThemeMode _mode;

  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  Future<void> toggle() async {
    _mode = isDark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    await _prefs.setBool(_key, isDark);
  }
}
