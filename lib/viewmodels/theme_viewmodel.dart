import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeViewModel extends ChangeNotifier {
  static const String _key = "theme_mode";

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  bool get isDark => _themeMode == ThemeMode.dark;

  ThemeViewModel() {
    loadTheme(); // 👈 load khi khởi tạo
  }

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();

    final isDark = prefs.getBool(_key);

    if (isDark == null) {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    }

    notifyListeners();
  }

  Future<void> toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();

    if (_themeMode == ThemeMode.dark) {
      _themeMode = ThemeMode.light;
      await prefs.setBool(_key, false);
    } else {
      _themeMode = ThemeMode.dark;
      await prefs.setBool(_key, true);
    }

    notifyListeners();
  }

  Future<void> setDark(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    _themeMode = value ? ThemeMode.dark : ThemeMode.light;

    await prefs.setBool(_key, value);

    notifyListeners();
  }
}