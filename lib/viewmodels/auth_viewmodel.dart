import 'package:flutter/material.dart';
import '../data/repositories/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository repo;

  AuthViewModel(this.repo);

  // Private fields
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _token;

  // Public getters
  bool get isLoggedIn => _isLoggedIn;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  String? get token => _token;

  // ====================== LOAD TOKEN KHI MỞ APP ======================
  Future<void> loadToken() async {
    try {
      final savedToken = await repo.getToken();
      if (savedToken != null && savedToken.isNotEmpty) {
        _token = savedToken;
        _isLoggedIn = true;
      } else {
        _isLoggedIn = false;
        _token = null;
      }
    } catch (e) {
      _isLoggedIn = false;
      _token = null;
    }
    notifyListeners();
  }

  // ====================== LOGIN ======================
  Future<bool> login(String email, String password) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final res = await repo.login(email, password);

      final accessToken = res['token']?.toString();

      if (accessToken == null || accessToken.isEmpty) {
        throw Exception("Token không hợp lệ từ server");
      }

      _token = accessToken;
      _isLoggedIn = true;

      await repo.saveToken(accessToken);

      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      _isLoggedIn = false;
      _token = null;
      notifyListeners();
      return false;
    }
  }

  // ====================== LOGOUT ======================
  Future<void> logout() async {
    try {
      await repo.clearToken(); // Sử dụng hàm đã thêm ở repository
    } catch (e) {
      debugPrint("Logout error: $e");
    }

    _token = null;
    _isLoggedIn = false;
    _errorMessage = null;
    notifyListeners();
  }

  // Clear error khi user bắt đầu nhập lại
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
