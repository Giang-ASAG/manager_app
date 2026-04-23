import 'package:flutter/material.dart';
import 'package:manager/data/models/warehouse.dart';
import 'package:manager/data/repositories/warehouse_repository.dart';

class WarehouseViewModel extends ChangeNotifier {
  final WarehouseRepository _repo;

  WarehouseViewModel(this._repo);

  List<Warehouse> warehouses = [];
  bool isLoading = false;
  String? error;

  Future<void> fetchWarehouses() async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();
      warehouses = await _repo.getWarehouses();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createWarehouse(Warehouse warehouse) async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();
      final newWarehouse = await _repo.createWarehouse(warehouse);
      warehouses.add(newWarehouse);
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteWarehouse(int id) async {
    try {
      await _repo.deleteWarehouse(id);
      warehouses.removeWhere((e) => e.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateWarehouse(int id, Warehouse warehouseData) async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();
      final updatedWarehouse = await _repo.updateWarehouse(id, warehouseData);
      final index = warehouses.indexWhere((e) => e.id == id);
      if (index != -1) {
        warehouses[index] = updatedWarehouse;
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
