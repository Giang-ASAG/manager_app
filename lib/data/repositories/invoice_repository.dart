import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:manager/core/services/api_service.dart';
import 'package:manager/data/models/invoice.dart';

class InvoiceRepository {
  final ApiService _api;

  InvoiceRepository(this._api);

  Future<List<Invoice>> getInvoice() async {
    try {
      final response = await _api.dio.get('/invoices');
      final List data = response.data;
      return data.map((e) => Invoice.fromJson(e)).toList();
    } catch (e) {
      throw Exception("Failed to load invoices: $e");
    }
  }

  Future<Invoice> getInvoicebyId(int id) async {
    try {
      final response = await _api.dio.get('/invoices/$id');
      final resData = response.data;
      // Kiểm tra xem response.data là cái hóa đơn hay là cái bọc chứa hóa đơn
      if (resData is Map<String, dynamic>) {
        if (resData.containsKey('data')) {
          // Nếu có key 'data', truyền cái ruột vào model
          return Invoice.fromJson(resData['data']);
        }
        // Nếu không có key 'data', truyền trực tiếp
        return Invoice.fromJson(resData);
      }

      throw Exception("Định dạng dữ liệu không hợp lệ");
    } catch (e) {
      rethrow;
    }
  }

  Future<Invoice> createInvoice(Invoice invoice) async {
    try {
      final response = await _api.dio.post(
        '/invoices',
        data: invoice.toJson(),
      );
      return Invoice.fromJson(response.data);
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
}
