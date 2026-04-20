import 'package:flutter/material.dart';
import 'package:manager/data/models/product.dart';
import 'package:manager/data/repositories/product_repository.dart';


class ProductViewModel extends ChangeNotifier {
  final ProductRepository _repo;

  ProductViewModel(this._repo);

  List<Product> products = [];
  bool isLoading = false;
  String? error;

  // ================= GET ALL =================
  Future<void> fetchProducts() async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      products = await _repo.getProducts();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ================= CREATE =================
  Future<bool> createProduct(Product product) async {
    try {
      isLoading = true;
      notifyListeners();
      final newProduct = await _repo.createProduct(product);
      products.add(newProduct); // update UI luôn
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
  Future<bool> updateProduct(int id, Product product) async {
    try {
      isLoading = true;
      notifyListeners();

      final updated = await _repo.updateProduct(id, product);

      final index = products.indexWhere((e) => e.id == id);
      if (index != -1) {
        products[index] = updated;
      }

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
  Future<void> deleteProduct(int id) async {
    try {
      await _repo.deleteProduct(id);
      products.removeWhere((e) => e.id == id);
      notifyListeners();

    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }
}