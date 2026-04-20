import 'package:manager/core/services/api_service.dart';
import 'package:manager/data/models/category.dart';

class CategoriesRepository {
  final ApiService _api;

  CategoriesRepository(this._api);

  Future<List<Category>> getCategories() async {
    try {
      final response = await _api.dio.get('/categories');
      final List data = response.data;
      return data.map((e) => Category.fromJson(e)).toList();
    } catch (e) {
      throw Exception("Failed to load products: $e");
    }
  }

  Future<Category> createCategory(Category category) async {
    try {
      final response =
          await _api.dio.post('/categories', data: category.toJson());
      return Category.fromJson(response.data);
    } catch (e) {
      throw Exception("Failed to create category: $e");
    }
  }

  Future<void> deleteCategory(int id) async {
    try {
      await _api.dio.delete('/categories/$id');
    } catch (e) {
      throw Exception("Failed to delete product: $e");
    }
  }
}
