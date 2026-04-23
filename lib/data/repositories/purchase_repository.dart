import 'package:dio/dio.dart';
import 'package:manager/core/services/api_service.dart';
import 'package:manager/data/models/purchase.dart';

class PurchaseRepository {
  final ApiService _api;

  PurchaseRepository(this._api);

  Future<List<Purchase>> getPurchases() async {
    try {
      final response = await _api.dio.get('/purchases');
      final List data = response.data;
      return data.map((e) => Purchase.fromJson(e)).toList();
    } catch (e) {
      throw Exception("Failed to load purchases: $e");
    }
  }

  Future<Purchase> getPurchaseById(int id) async {
    try {
      final response = await _api.dio.get('/purchases/$id');
      final resData = response.data;
      // Kiểm tra xem response.data là đơn hàng hay là cái bọc chứa đơn hàng
      if (resData is Map<String, dynamic>) {
        if (resData.containsKey('data')) {
          // Nếu có key 'data', truyền cái ruột vào model
          return Purchase.fromJson(resData['data']);
        }
        // Nếu không có key 'data', truyền trực tiếp
        return Purchase.fromJson(resData);
      }

      throw Exception("Định dạng dữ liệu không hợp lệ");
    } catch (e) {
      rethrow;
    }
  }

  Future<Purchase> createPurchase(Purchase purchase) async {
    try {
      final response = await _api.dio.post(
        '/purchases',
        data: purchase.toJson(),
      );
      return Purchase.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        print("CHI TIẾT LỖI TỪ SERVER: ${e.response?.data}");

        final serverErrors = e.response?.data['errors'];
        if (serverErrors != null) {
          print("DANH SÁCH TRƯỜNG SAI: $serverErrors");
        }
      }
      throw Exception("Thất bại (422): ${e.response?.data ?? e.message}");
    } catch (e) {
      throw Exception("Lỗi hệ thống: $e");
    }
  }

  Future<Purchase> updatePurchase(int id, Purchase purchase) async {
    try {
      final response = await _api.dio.put(
        '/purchases/$id',
        data: purchase.toJson(),
      );
      return Purchase.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        print("CHI TIẾT LỖI TỪ SERVER: ${e.response?.data}");

        final serverErrors = e.response?.data['errors'];
        if (serverErrors != null) {
          print("DANH SÁCH TRƯỜNG SAI: $serverErrors");
        }
      }
      throw Exception("Thất bại (422): ${e.response?.data ?? e.message}");
    } catch (e) {
      throw Exception("Lỗi hệ thống: $e");
    }
  }

  Future<bool> deletePurchase(int id) async {
    try {
      await _api.dio.delete('/purchases/$id');
      return true;
    } catch (e) {
      throw Exception("Failed to delete purchase: $e");
    }
  }
}
