import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageViewModel extends ChangeNotifier {
  Locale _locale = const Locale('vi');

  Locale get locale => _locale;

  static const _key = "language_code";

  LanguageViewModel(String? initialCode)
      : _locale = Locale(initialCode ?? 'vi') { // Mặc định là 'vi' nếu null
    // Bạn không cần gọi loadLanguage() ở đây nữa vì đã có giá trị khởi tạo
  }

  Future<void> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString(_key);

    if (lang == null) {
      _locale = const Locale('vi');
    } else {
      _locale = Locale(lang);
    }

    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, code);
    _locale = Locale(code);
    notifyListeners();
  }

  Future<void> toggleLanguage() async {
    if (_locale.languageCode == 'vi') {
      await setLanguage('en');
    } else {
      await setLanguage('vi');
    }
  }
}