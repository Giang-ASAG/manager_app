import 'package:flutter/material.dart';
import 'package:manager/data/models/purchase.dart';
import 'package:manager/data/repositories/purchase_repository.dart';

class PurchaseViewmodel extends ChangeNotifier {
  final PurchaseRepository _repo;

  PurchaseViewmodel(this._repo);

  List<Purchase> purchases = [];
  bool isLoading = false;
  String? error;
  Purchase? purchaseData;

  // ================= FETCH ALL =================
  Future<void> fetchPurchases() async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();
      purchases = await _repo.getPurchases();
    } catch (e) {
      error = e.toString();
      debugPrint("Error fetching purchases: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchPurchaseById(int id) async {
    isLoading = true;
    notifyListeners();
    try {
      final purchase = await _repo.getPurchaseById(id);
      purchaseData = purchase;
    } catch (e) {
      purchaseData = null;
      debugPrint("Error fetching purchase detail: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createPurchase(Purchase purchase) async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();
      final newPurchase = await _repo.createPurchase(purchase);
      purchases.add(newPurchase);
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updatePurchase(int id, Purchase purchase) async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();
      final updatedPurchase = await _repo.updatePurchase(id, purchase);
      final index = purchases.indexWhere((p) => p.id == id);
      if (index != -1) {
        purchases[index] = updatedPurchase;
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

  Future<bool> deletePurchase(int id) async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();
      await _repo.deletePurchase(id);
      purchases.removeWhere((p) => p.id == id);
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
