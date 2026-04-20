import 'package:dio/dio.dart';
import 'package:manager/core/services/api_service.dart';
import 'package:manager/data/models/product.dart';

class ProductRepository {
  final ApiService _api;

  ProductRepository(this._api);

  // 📦 GET ALL PRODUCTS
  Future<List<Product>> getProducts() async {
    try {
      final response = await _api.dio.get('/products');
      final List data = response.data;
      return data.map((e) => Product.fromJson(e)).toList();
    } catch (e) {
      throw Exception("Failed to load products: $e");
    }
  }

  // 🔍 GET PRODUCT BY ID
  Future<Product> getProductById(int id) async {
    try {
      final response = await _api.dio.get('/products/$id');
      return Product.fromJson(response.data);
    } catch (e) {
      throw Exception("Failed to get product: $e");
    }
  }

  // ➕ CREATE PRODUCT
  Future<Product> createProduct(Product product) async {
    try {
      final response = await _api.dio.post(
        '/products',
        data: product.toJson(),
      );
      return Product.fromJson(response.data);
    } on DioException catch (e) { // Ép kiểu về DioException để lấy dữ liệu response
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

  // ✏️ UPDATE PRODUCT
  Future<Product> updateProduct(int id, Product product) async {
    try {
      final response = await _api.dio.put(
        '/products/$id',
        data: product.toJson(),
      );

      return Product.fromJson(response.data);
    } catch (e) {
      throw Exception("Failed to update product: $e");
    }
  }

  // ❌ DELETE PRODUCT
  Future<void> deleteProduct(int id) async {
    try {
      await _api.dio.delete('/products/$id');
    } catch (e) {
      throw Exception("Failed to delete product: $e");
    }
  }
}
