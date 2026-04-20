import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/api_service.dart';

class AuthRepository {
  final ApiService api;

  AuthRepository(this.api);

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await api.dio.post(
        '/login',
        data: {
          'email': email,
          'password': password,
        },
      );
      return response.data;
    } catch (e) {
      throw Exception("Login failed: $e");
    }
  }
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
}