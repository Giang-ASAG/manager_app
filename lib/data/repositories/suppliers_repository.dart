import 'package:dio/dio.dart';
import 'package:manager/core/services/api_service.dart';
import 'package:manager/data/models/supplier.dart';

class SuppliersRepository {
  final ApiService _api;

  SuppliersRepository(this._api);

  Future<List<Supplier>> getSuppliers() async {
    try {
      final response = await _api.dio.get('/suppliers');
      final List data = response.data;
      return data.map((e) => Supplier.fromJson(e)).toList();
    } catch (e) {
      throw Exception("Failed to load products: $e");
    }
  }

  Future<Supplier> createSupplier(Supplier s) async {
    try {
      final response = await _api.dio.post('/suppliers', data: s.toJson());
      return Supplier.fromJson(response.data);
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

  Future<void> deleteSupplier(int id) async {
    try {
      await _api.dio.delete('/suppliers/$id');
    } catch (e) {
      throw Exception("Failed to delete product: $e");
    }
  }
}
