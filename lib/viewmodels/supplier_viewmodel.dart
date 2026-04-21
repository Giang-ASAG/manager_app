import 'package:flutter/material.dart';
import 'package:manager/data/models/supplier.dart';
import 'package:manager/data/repositories/suppliers_repository.dart';

class SupplierViewmodel extends ChangeNotifier {
  final SuppliersRepository _repo;

  SupplierViewmodel(this._repo);

  List<Supplier> suppliers = [];
  bool isLoading = false;
  String? error;

  Future<void> fetchSuppliers() async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();
      suppliers = await _repo.getSuppliers();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createSupplier(Supplier s) async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();
      final newSupplier = await _repo.createSupplier(s);
      suppliers.add(newSupplier);
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteSupplier(int id) async {
    try {
      await _repo.deleteSupplier(id);
      suppliers.removeWhere((e) => e.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateSupplier(int id, Supplier supplierData) async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();
      final updatedSupplier = await _repo.updateSupplier(id, supplierData);
      final index = suppliers.indexWhere((e) => e.id == id);
      if (index != -1) {
        suppliers[index] = updatedSupplier;
      }
      notifyListeners();
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
