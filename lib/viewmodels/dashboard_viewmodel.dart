import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:manager/data/models/invoice.dart';
import 'package:manager/data/repositories/manager_repository.dart';

class DashboardViewModel extends ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;
  ManagerRepository? man;
  // ── Stats ──────────────────────────────────────────────────────────────────
  int totalRevenue = 0;
  int importTotal = 0;
  int totalOrders = 0;
  int totalProducts = 0;
  int stockPercent = 0;

  double revenueTrend = 0; // percent change vs yesterday
  double importTrend = 0;



  // ── Recent activity ────────────────────────────────────────────────────────


  // ── Computed formatters ────────────────────────────────────────────────────

  /// e.g. 120000000 → "120.000.000"
  String get totalRevenueFormatted =>
      NumberFormat('#,###', 'vi_VN').format(totalRevenue);

  /// e.g. 120000000 → "120,0" (millions)
  String get totalRevenueMillion =>
      (totalRevenue / 1000000).toStringAsFixed(1);

  String get importTotalMillion =>
      (importTotal / 1000000).toStringAsFixed(1);

  String get revenueTrendLabel =>
      '${revenueTrend >= 0 ? '+' : ''}${revenueTrend.toStringAsFixed(1)}%';

  String get importTrendLabel =>
      '${importTrend >= 0 ? '+' : ''}${importTrend.toStringAsFixed(1)}%';

  bool get revenueTrendUp => revenueTrend >= 0;
  bool get importTrendUp => importTrend >= 0;

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<List<Invoice>?> fetchInvoiceWeek() async{
    try{
      final list = await man?.invoice.getInvoice();
      return list;
    }
    catch(e){
      return [];
    }

  }


  Future<void> loadDashboard() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await Future.delayed(const Duration(milliseconds: 900)); // fake API

      totalRevenue = 1000000;
      importTotal = 1000000;
      totalOrders = 320;
      totalProducts = 1200;
      stockPercent = 85;
      revenueTrend = 12.4;
      importTrend = -3.1;


    } catch (e) {
      errorMessage = 'Không thể tải dữ liệu. Vui lòng thử lại.';
      debugPrint('Dashboard error: $e');
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() => loadDashboard();
}
