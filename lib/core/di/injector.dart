import 'package:get_it/get_it.dart';
import 'package:manager/data/repositories/invoice_repository.dart';
import 'package:manager/data/repositories/manager_repository.dart';
import 'package:manager/viewmodels/categories_viewmodel.dart';
import 'package:manager/viewmodels/customer_viewmodel.dart';
import 'package:manager/viewmodels/invoice_viewmodel.dart';
import 'package:manager/viewmodels/product_viewmodel.dart';
import 'package:manager/viewmodels/supplier_viewmodel.dart';

import '../services/api_service.dart';
import '../../data/repositories/auth_repository.dart';
import '../../viewmodels/auth_viewmodel.dart';

final getIt = GetIt.instance;

void setupLocator() {
  // =====================
  // SERVICES
  // =====================

  getIt.registerLazySingleton<ApiService>(
    () => ApiService(),
  );

  // =====================
  // REPOSITORIES
  // =====================
  getIt.registerLazySingleton<ManagerRepository>(
      () => ManagerRepository(getIt<ApiService>()));

  // =====================
  // VIEWMODELS
  // =====================
  getIt.registerFactory<AuthViewModel>(
    () => AuthViewModel(
        getIt<ManagerRepository>().auth), // Truy cập thẳng vào .auth
  );

  getIt.registerFactory<ProductViewModel>(
    () => ProductViewModel(
        getIt<ManagerRepository>().products), // Truy cập thẳng vào .products
  );
  getIt.registerFactory<CategoriesViewModel>(
    () => CategoriesViewModel(getIt<ManagerRepository>().categories),
  );
  getIt.registerFactory<InvoiceViewmodel>(
    () => InvoiceViewmodel(getIt<ManagerRepository>().invoice),
  );
  getIt.registerFactory<CustomerViewmodel>(
    () => CustomerViewmodel(getIt<ManagerRepository>().customer),
  );
  getIt.registerFactory<SupplierViewmodel>(
    () => SupplierViewmodel(getIt<ManagerRepository>().supplier),
  );
}
