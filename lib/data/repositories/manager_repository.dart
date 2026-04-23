import 'package:manager/core/services/api_service.dart';
import 'package:manager/data/repositories/auth_repository.dart';
import 'package:manager/data/repositories/branch_repository.dart';
import 'package:manager/data/repositories/categories_repository.dart';
import 'package:manager/data/repositories/customer_repository.dart';
import 'package:manager/data/repositories/invoice_repository.dart';
import 'package:manager/data/repositories/product_repository.dart';
import 'package:manager/data/repositories/purchase_repository.dart';
import 'package:manager/data/repositories/suppliers_repository.dart';
import 'package:manager/data/repositories/warehouse_repository.dart';

class ManagerRepository {
  final ApiService _apiService;

  late final ProductRepository products;
  late final AuthRepository auth;
  late final CategoriesRepository categories;
  late final InvoiceRepository invoice;
  late final CustomerRepository customer;
  late final SuppliersRepository supplier;
  late final BranchRepository branch;
  late final PurchaseRepository purchase;
  late final WarehouseRepository warehouse;

  // Nhận ApiService từ Constructor
  ManagerRepository(this._apiService) {
    // Truyền cùng 1 apiService vào tất cả các repo con
    products = ProductRepository(_apiService);
    auth = AuthRepository(_apiService);
    categories = CategoriesRepository(_apiService);
    invoice = InvoiceRepository(_apiService);
    customer = CustomerRepository(_apiService);
    supplier = SuppliersRepository(_apiService);
    branch = BranchRepository(_apiService);
    purchase = PurchaseRepository(_apiService);
    warehouse = WarehouseRepository(_apiService);
  }
}
