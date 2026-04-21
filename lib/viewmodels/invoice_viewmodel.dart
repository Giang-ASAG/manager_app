import 'package:flutter/material.dart';
import 'package:manager/data/models/invoice.dart';
import 'package:manager/data/repositories/invoice_repository.dart';

class InvoiceViewmodel extends ChangeNotifier {
  final InvoiceRepository _repo;

  InvoiceViewmodel(this._repo);

  List<Invoice> invoices = [];
  bool isLoading = false;
  String? error;
  Invoice? invoiceDta;

  // ================= FETCH ALL =================
  Future<void> fetchInvoices() async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();
      invoices = await _repo.getInvoice();
    } catch (e) {
      error = e.toString();
      debugPrint("Error fetching categories: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchInvoicebyId(int id) async {
    // Thêm dấu ? vì có thể trả về null khi lỗi
    isLoading = true;
    notifyListeners();
    try {
      // Gọi repository để lấy dữ liệu
      final invoice = await _repo.getInvoicebyId(id);
      invoiceDta = invoice;
    } catch (e) {
      invoiceDta = null;
      debugPrint("Error fetching invoice detail: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createInvoice(Invoice invoice) async {
    try {
      isLoading = true;
      notifyListeners();
      final newProduct = await _repo.createInvoice(invoice);
      invoices.add(newProduct);
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
