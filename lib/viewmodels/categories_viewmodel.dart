import 'package:flutter/material.dart';
import 'package:manager/data/models/category.dart'; // Đảm bảo bạn đã có Model này
import 'package:manager/data/repositories/categories_repository.dart';

class CategoriesViewModel extends ChangeNotifier {
  final CategoriesRepository _repo;

  CategoriesViewModel(this._repo);

  List<Category> categories = [];
  bool isLoading = false;
  String? error;

  // ================= FETCH ALL =================
  Future<void> fetchCategories() async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      categories = await _repo.getCategories();
    } catch (e) {
      error = e.toString();
      debugPrint("Error fetching categories: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ================= CREATE =================
  Future<bool> createCategory(Category category) async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      final newCategory = await _repo.createCategory(category);
      categories.add(newCategory);
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

// ================= DELETE =================
  Future<bool> deleteCategory(int id) async {
    try {
      await _repo.deleteCategory(id);
      categories.removeWhere((e) => e.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCategory(Category updatedCategory) async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      final result =
          await _repo.updateCategory(updatedCategory.id, updatedCategory);
      // Cập nhật lại item trong danh sách
      final index =
          categories.indexWhere((cat) => cat.id == updatedCategory.id);
      if (index != -1) {
        categories[index] = result; // Dùng dữ liệu trả về từ server để đồng bộ
      }

      return true;
    } catch (e) {
      error = e.toString();
      debugPrint("Error updating category: $e");
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
