import 'package:flutter/material.dart';
import '../data/repositories/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository repo;

  AuthViewModel(this.repo);

  bool isLoading = false;
  String? errorMessage;
  String? token;

  Future<bool> login(String email, String password) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      final res = await repo.login(email, password);

      final accessToken = res['token'];

      // ❗ Check kỹ
      if (accessToken == null || accessToken.toString().isEmpty) {
        throw Exception("Token không hợp lệ");
      }

      token = accessToken;

      // 🔥 Lưu token
      await repo.saveToken(accessToken);
      debugPrint("Token===:  "+ accessToken.toString());
      isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
