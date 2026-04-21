import 'package:dio/dio.dart';
import 'package:manager/core/services/api_service.dart';
import 'package:manager/data/models/customer.dart';

class CustomerRepository {
  final ApiService _api;

  CustomerRepository(this._api);

  Future<List<Customer>> getCustomer() async {
    try {
      final response = await _api.dio.get('/customers');
      final List data = response.data;
      return data.map((e) => Customer.fromJson(e)).toList();
    } catch (e) {
      throw Exception("Failed to load customers: $e");
    }
  }

  Future<Customer> createCustomer(Customer c) async {
    try {
      final response = await _api.dio.post('/customers', data: c.toJson());
      return Customer.fromJson(response.data);
    } on DioException catch (e) {
      // Ép kiểu về DioException để lấy dữ liệu response
      if (e.response?.statusCode == 422) {
        // 🟢 ĐÂY LÀ DÒNG QUAN TRỌNG: Nó sẽ hiện ra lỗi cụ thể trong Debug Console
        print("CHI TIẾT LỖI TỪ SERVER: ${e.response?.data}");

        final serverErrors = e.response?.data['errors'];
        if (serverErrors != null) {
          print("DANH SÁCH TRƯỜNG SAI: $serverErrors");
        }
      }

      // Ném lỗi kèm thông báo từ Server để UI hiển thị được
      throw Exception("Thất bại (422): ${e.response?.data ?? e.message}");
    } catch (e) {
      // Xử lý các lỗi hệ thống khác nếu có
      throw Exception("Lỗi hệ thống: $e");
    }
  }

  Future<void> deleteCustomer(int id) async {
    try {
      await _api.dio.delete('/customers/$id');
    } catch (e) {
      // Xử lý các lỗi hệ thống khác nếu có
      throw Exception("Lỗi hệ thống: $e");
    }
  }

  Future<Customer> updateProduct(int id, Customer customer) async {
    try {
      final response = await _api.dio.put(
        '/customers/$id',
        data: customer.toJson(),
      );

      return Customer.fromJson(response.data);
    } catch (e) {
      throw Exception("Failed to update product: $e");
    }
  }
}
