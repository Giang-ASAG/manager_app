class AppRoutes {
  static const login = '/login';
  static const main = '/main';
  static const dashboard = '/dashboard';

  // Products
  static const products = '/products';
  static const productAdd = '/products/add';
  static const productDetail = '/products/detail/:id';
  static const productEdit = '/products/edit/:id';

  //Categories
  static const categories = "/categories";
  static const categoryAdd = "/categories/add";
  //Customers
  static const customers = "/customers";
  static const customerAdd = "/customers/add";
  static const customerDetail = "/customers/detail/:id";
  static const customerEdit = "/customers/edit/:id";

  static const invoices = "/invoices";
  static const invoiceAdd = "/invoice/add";
  static const invoiceDetail = "/invoice/detail/:id";

  static const suppliers = "/suppliers";
  static const supplierAdd = "/supplier/add";
  static const supplierDetail = "/supplier/detail/:id";
  static const supplierEdit = "/supplier/edit/:id";

  // Branches
  static const branches = "/branches";
  static const branchAdd = "/branches/add";
  static const branchDetail = "/branches/detail/:id";
  static const branchEdit = "/branches/edit/:id";
}
