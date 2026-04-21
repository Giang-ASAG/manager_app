// lib/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:manager/data/models/product.dart';
import 'package:manager/data/repositories/manager_repository.dart';
import 'package:manager/viewmodels/auth_viewmodel.dart';

import 'package:manager/views/screens/auth/login_screen.dart';
import 'package:manager/views/screens/categories/categories_form_screen.dart';
import 'package:manager/views/screens/categories/categories_list_screen.dart';
import 'package:manager/views/screens/customer/customer_form_screen.dart';
import 'package:manager/views/screens/customer/customer_list_screen.dart';
import 'package:manager/views/screens/dashboard/dashboard_screen.dart';
import 'package:manager/views/screens/invoice/invoice_detail_screen.dart';
import 'package:manager/views/screens/invoice/invoice_form_screen.dart';
import 'package:manager/views/screens/invoice/invoice_list_screen.dart';
import 'package:manager/views/screens/main/main_screen.dart';
import 'package:manager/views/screens/product/product_detail_screen.dart';
import 'package:manager/views/screens/product/product_form_screen.dart';
import 'package:manager/views/screens/product/product_list_screen.dart';
import 'package:manager/views/screens/supplier/supplier_form_screen.dart';
import 'package:manager/views/screens/supplier/supplier_list_screen.dart';

import 'app_routes.dart';

class AppRouter {
  static GoRouter createRouter(AuthViewModel authViewModel) {
    return GoRouter(
      initialLocation: AppRoutes.login,
      debugLogDiagnostics: true,

      refreshListenable: authViewModel,
      // 👈 QUAN TRỌNG

      redirect: (context, state) {
        final isLoggedIn = authViewModel.isLoggedIn;
        final isGoingToLogin = state.uri.toString() == AppRoutes.login;

        // Chưa login -> luôn về login
        if (!isLoggedIn) {
          return isGoingToLogin ? null : AppRoutes.login;
        }

        // Đã login -> không cho quay lại login
        if (isLoggedIn && isGoingToLogin) {
          return AppRoutes.main;
        }

        return null;
      },
      routes: [
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) => const LoginScreen(),
        ),

        GoRoute(
          path: AppRoutes.main,
          builder: (context, state) => const MainScreen(),
        ),

        GoRoute(
          path: AppRoutes.dashboard,
          builder: (context, state) => const DashboardScreen(),
        ),

        // Products Group
        GoRoute(
          path: AppRoutes.products,
          builder: (context, state) => const ProductListScreen(),
        ),

        GoRoute(
          path: AppRoutes.productAdd,
          builder: (context, state) => const ProductFormScreen(),
        ),
        GoRoute(
          path: AppRoutes.productDetail,
          builder: (context, state) {
            final product = state.extra as Product;
            return ProductDetailScreen(product: product);
          },
        ),
        GoRoute(
          path: AppRoutes.categories,
          builder: (context, state) => const CategoryListScreen(),
        ),
        GoRoute(
          path: AppRoutes.categoryAdd,
          builder: (context, state) => const CategoriesFormScreen(),
        ),

        GoRoute(
          path: AppRoutes.customers,
          builder: (context, state) => const CustomerListScreen(),
        ),
        GoRoute(
          path: AppRoutes.customerAdd,
          builder: (context, state) => const CustomerFormScreen(),
        ),

        GoRoute(
          path: AppRoutes.suppliers,
          builder: (context, state) => const SupplierListScreen(),
        ),
        GoRoute(
          path: AppRoutes.supplierAdd,
          builder: (context, state) => const SupplierFormScreen(),
        ),

        GoRoute(
          path: AppRoutes.invoices,
          builder: (context, state) => const InvoiceListScreen(),
        ),
        GoRoute(
          path: AppRoutes.invoiceAdd,
          builder: (context, state) => const InvoiceFormScreen(),
        ),
        GoRoute(
          path: AppRoutes.invoiceDetail,
          builder: (context, state) {
            final id = state.extra is int ? state.extra as int : 0;
            return InvoiceDetailScreen(id: id);
          },
        ),
      ],

      // Xử lý khi vào route không tồn tại
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 80, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Không tìm thấy trang\n${state.uri}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.main),
                child: const Text('Về trang chủ'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
