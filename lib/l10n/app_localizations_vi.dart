// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get loginTitle => 'Đăng nhập vào tài khoản';

  @override
  String get loginBtn => 'Đăng nhập';

  @override
  String get dashboard_text => 'Trang tổng quan';

  @override
  String get password_text => 'Mật khẩu';

  @override
  String get en => 'Tiếng anh';

  @override
  String get vi => 'Tiếng việt';

  @override
  String get language_text => 'Ngôn ngữ';

  @override
  String get theme_text => 'Giao diện';

  @override
  String get logout_text => 'Đăng xuất';

  @override
  String get login_success => 'Đăng nhập thành công';

  @override
  String get login_failed => 'Đăng nhập thất bại';

  @override
  String get logout_success => 'Đăng xuất thành công';

  @override
  String get yes => 'Có';

  @override
  String get no => 'Không';

  @override
  String get confirm => 'Xác nhận';

  @override
  String get common_save => 'Lưu';

  @override
  String get common_add => 'Thêm';

  @override
  String get common_edit => 'Sửa';

  @override
  String get common_delete => 'Xóa';

  @override
  String get common_update => 'Cập nhật';

  @override
  String get common_cancel => 'Hủy';

  @override
  String get common_search => 'Tìm kiếm';

  @override
  String get common_confirm => 'Xác nhận';

  @override
  String get common_detail => 'Chi tiết';

  @override
  String get common_warning => 'Cảnh báo';

  @override
  String action_success(Object action, Object item) {
    return '$action $item thành công';
  }

  @override
  String action_failed(Object action, Object item) {
    return '$action $item thất bại';
  }

  @override
  String confirmDeleteItem(String item) {
    return 'Bạn có chắc muốn xóa $item này không?';
  }

  @override
  String actionSuccess(String action, String item) {
    return '$action $item thành công';
  }

  @override
  String actionFailed(String action, String item) {
    return '$action $item thất bại';
  }

  @override
  String get confirm_delete => 'Bạn có chắc muốn xóa không?';

  @override
  String get confirm_logout => 'Bạn có chắc muốn đăng xuất không?';

  @override
  String get quick_actions => 'Chức năng nhanh';

  @override
  String get recent_actions => 'Hoạt động gần đây';

  @override
  String get view_all => 'Xem tất cả';

  @override
  String get customer => 'Khách hàng';

  @override
  String get customer_list => 'Danh sách khách hàng';

  @override
  String get customer_add => 'Thêm khách hàng';

  @override
  String get customer_edit => 'Sửa khách hàng';

  @override
  String get customer_delete => 'Xóa khách hàng';

  @override
  String get customer_save => 'Lưu khách hàng';

  @override
  String get customer_detail => 'Chi tiết khách hàng';

  @override
  String get category => 'Danh mục';

  @override
  String get category_list => 'Danh sách danh mục';

  @override
  String get category_add => 'Thêm danh mục';

  @override
  String get category_edit => 'Sửa danh mục';

  @override
  String get category_delete => 'Xóa danh mục';

  @override
  String get category_save => 'Lưu danh mục';

  @override
  String get category_detail => 'Chi tiết danh mục';

  @override
  String get product => 'Sản phẩm';

  @override
  String get product_list => 'Danh sách sản phẩm';

  @override
  String get product_add => 'Thêm sản phẩm';

  @override
  String get product_edit => 'Sửa sản phẩm';

  @override
  String get product_delete => 'Xóa sản phẩm';

  @override
  String get product_save => 'Lưu sản phẩm';

  @override
  String get product_detail => 'Chi tiết sản phẩm';

  @override
  String get invoice => 'Hóa đơn';

  @override
  String get invoice_list => 'Danh sách hóa đơn';

  @override
  String get invoice_add => 'Thêm hóa đơn';

  @override
  String get invoice_edit => 'Sửa hóa đơn';

  @override
  String get invoice_delete => 'Xóa hóa đơn';

  @override
  String get invoice_save => 'Lưu hóa đơn';

  @override
  String get invoice_detail => 'Chi tiết hóa đơn';

  @override
  String get supplier => 'Nhà cung cấp';

  @override
  String get supplier_list => 'Danh sách nhà cung cấp';

  @override
  String get supplier_add => 'Thêm nhà cung cấp';

  @override
  String get supplier_edit => 'Sửa nhà cung cấp';

  @override
  String get supplier_delete => 'Xóa nhà cung cấp';

  @override
  String get supplier_save => 'Lưu nhà cung cấp';

  @override
  String get supplier_detail => 'Chi tiết nhà cung cấp';

  @override
  String get sales => 'Bán hàng';

  @override
  String get purchase => 'Nhập hàng';

  @override
  String get inventory => 'Quản lý kho';

  @override
  String get debt => 'Công nợ';

  @override
  String get sales_create => 'Tạo đơn bán';

  @override
  String get purchase_create => 'Tạo đơn nhập';

  @override
  String get inventory_manage => 'Quản lý kho';

  @override
  String get debt_manage => 'Quản lý công nợ';

  @override
  String get branch => 'Chi nhánh';

  @override
  String get branch_list => 'Danh sách chi nhánh';

  @override
  String get branch_add => 'Thêm chi nhánh';

  @override
  String get branch_edit => 'Sửa chi nhánh';

  @override
  String get branch_delete => 'Xóa chi nhánh';

  @override
  String get branch_save => 'Lưu chi nhánh';

  @override
  String get branch_detail => 'Chi tiết chi nhánh';

  @override
  String get warehouse => 'Kho';

  @override
  String get warehouse_list => 'Danh sách kho';

  @override
  String get warehouse_add => 'Thêm kho';

  @override
  String get warehouse_edit => 'Sửa kho';

  @override
  String get warehouse_delete => 'Xóa kho';

  @override
  String get warehouse_save => 'Lưu kho';

  @override
  String get warehouse_detail => 'Chi tiết kho';

  @override
  String get settings => 'Cài đặt';

  @override
  String get message_success => 'Thành công';

  @override
  String get message_error => 'Lỗi';

  @override
  String get no_data => 'Không có dữ liệu';
}
