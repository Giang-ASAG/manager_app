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

// ================= UPDATE =================
// Future<bool> updateCategory(int id, Category category) async {
//   try {
//     isLoading = true;
//     notifyListeners();
//
//     final updated = await _repo.updateCategory(id, category);
//
//     final index = categories.indexWhere((e) => e.id == id);
//     if (index != -1) {
//       categories[index] = updated;
//     }
//     return true;
//   } catch (e) {
//     error = e.toString();
//     return false;
//   } finally {
//     isLoading = false;
//     notifyListeners();
//   }
// }

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
}
