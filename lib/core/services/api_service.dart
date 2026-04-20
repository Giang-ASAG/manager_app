import 'package:dio/dio.dart';
import 'package:manager/config/env.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  late Dio dio;

  ApiService() {
    dio = Dio(
      BaseOptions(
        baseUrl: Env.apiUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    _addInterceptors();
  }

  void _addInterceptors() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // 🔑 Lấy token từ storage
          final token = await _getToken();

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          return handler.next(options);
        },
        onError: (error, handler) {
          // 👉 xử lý 401 (token hết hạn)
          if (error.response?.statusCode == 401) {
            // TODO: logout / refresh token
          }
          return handler.next(error);
        },
      ),
    );
  }

  // 🔥 Hàm lấy token (bạn thay bằng storage thật)
  Future<String?> _getToken() async {
    // Ví dụ:
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');

    return null; // tạm thời
  }
}
