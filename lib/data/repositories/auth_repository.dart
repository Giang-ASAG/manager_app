import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/api_service.dart';

class AuthRepository {
  final ApiService api;
  static const String _tokenKey = 'auth_token';   // Dùng key cố định, dễ quản lý

  AuthRepository(this.api);

  // ====================== API ======================
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
      // Có thể throw custom exception sau này
      throw Exception("Login failed: ${e.toString()}");
    }
  }

  // ====================== Local Storage ======================
  Future<void> saveToken(String token) async {
    if (token.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Kiểm tra xem có token hợp lệ không
  Future<bool> hasValidToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
    // Sau này có thể thêm kiểm tra token hết hạn (JWT decode)
  }

  /// Xóa token khi logout
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  /// Logout đầy đủ (nếu cần gọi API logout trước)
  Future<void> logout() async {
    // Nếu backend có endpoint logout thì gọi ở đây
    // await api.dio.post('/logout');
    await clearToken();
  }
}