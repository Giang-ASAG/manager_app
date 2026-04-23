import 'package:dio/dio.dart';
import 'package:manager/core/services/api_service.dart';
import 'package:manager/data/models/warehouse.dart';

class WarehouseRepository {
  final ApiService _api;

  WarehouseRepository(this._api);

  Future<List<Warehouse>> getWarehouses() async {
    try {
      final response = await _api.dio.get('/warehouses');
      final List data = response.data;
      return data.map((e) => Warehouse.fromJson(e)).toList();
    } catch (e) {
      throw Exception("Failed to load warehouses: $e");
    }
  }

  Future<Warehouse> createWarehouse(Warehouse warehouse) async {
    try {
      final response =
          await _api.dio.post('/warehouses', data: warehouse.toJson());
      return Warehouse.fromJson(response.data);
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

  Future<void> deleteWarehouse(int id) async {
    try {
      await _api.dio.delete('/warehouses/$id');
    } catch (e) {
      throw Exception("Failed to delete warehouse: $e");
    }
  }

  Future<Warehouse> updateWarehouse(int id, Warehouse warehouseData) async {
    try {
      final response =
          await _api.dio.put('/warehouses/$id', data: warehouseData.toJson());
      return Warehouse.fromJson(response.data);
    } catch (e) {
      throw Exception("Failed to update warehouse: $e");
    }
  }
}
