import 'package:flutter/material.dart';
import 'package:manager/data/models/customer.dart';
import 'package:manager/data/repositories/customer_repository.dart';

class CustomerViewmodel extends ChangeNotifier {
  final CustomerRepository _repo;

  CustomerViewmodel(this._repo);

  List<Customer> customers = [];
  bool isLoading = false;
  String? error;

  Future<void> fetchCustomers() async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();
      customers = await _repo.getCustomer();
    } catch (e) {
      error = e.toString();
      debugPrint("Error fetching categories: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createCustomer(Customer c) async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();
      final newCustomer = await _repo.createCustomer(c);
      customers.add(newCustomer);
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteCustomer (int id) async {
    try {
      await _repo.deleteCustomer(id);
      customers.removeWhere((e) => e.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
