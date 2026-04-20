import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:manager/data/models/supplier.dart'; // Đảm bảo đã có model Supplier
import 'package:manager/viewmodels/supplier_viewmodel.dart'; // Đảm bảo đã có viewmodel tương ứng
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:manager/views/widgets/app_button.dart';
import 'package:manager/views/widgets/app_sliver_app_bar.dart';
import 'package:manager/views/widgets/app_snackbar.dart';

class SupplierFormScreen extends StatefulWidget {
  const SupplierFormScreen({super.key});

  @override
  State<SupplierFormScreen> createState() => _SupplierFormScreenState();
}

class _SupplierFormScreenState extends State<SupplierFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers cho các trường dữ liệu
  final _nameController = TextEditingController();
  final _contactPersonController = TextEditingController(); // Thêm cho Supplier
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();

  bool _isActive = true;

  @override
  void dispose() {
    _nameController.dispose();
    _contactPersonController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _saveSupplier() async {
    if (_formKey.currentState!.validate()) {
      final supplierVM = context.read<SupplierViewmodel>();

      // Tạo Model Supplier để gửi lên API
      final Supplier supplierData = Supplier(
          id: 0,
          name: _nameController.text.trim(),
          contactPerson: _contactPersonController.text.trim(),
          status: _isActive ? "Active" : "Inactive",
          address: _addressController.text.trim(),
          city: _cityController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim());

      final success = await supplierVM.createSupplier(supplierData);

      if (mounted) {
        if (success) {
          AppSnackbar.showSuccess(context, "Thêm nhà cung cấp thành công");
          context.pop();
        } else {
          AppSnackbar.showError(context, 'Lỗi: ${supplierVM.error}');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final supplierVM = context.watch<SupplierViewmodel>();

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      body: CustomScrollView(
        slivers: [
          const AppSliverAppBar(
            title: 'Thêm nhà cung cấp mới',
            showBackButton: true,
            height: 80,
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
            sliver: SliverToBoxAdapter(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(context, "Thông tin định danh"),
                    _buildTextField(
                      context,
                      controller: _nameController,
                      label: 'Tên nhà cung cấp *',
                      hint: 'Ví dụ: Công ty Thép Hòa Phát',
                      icon: Icons.business_rounded,
                      validator: (v) =>
                          v!.isEmpty ? 'Vui lòng nhập tên nhà cung cấp' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      context,
                      controller: _contactPersonController,
                      label: 'Người liên hệ',
                      hint: 'Tên nhân viên kinh doanh/đại diện',
                      icon: Icons.person_pin_rounded,
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle(context, "Thông tin liên lạc"),
                    _buildTextField(
                      context,
                      controller: _emailController,
                      label: 'Email *',
                      hint: 'sales@supplier.com',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v!.isEmpty) return 'Vui lòng nhập email';
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(v)) return 'Email không hợp lệ';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      context,
                      controller: _phoneController,
                      label: 'Số điện thoại',
                      hint: 'Ví dụ: 028xxxxxxxx',
                      icon: Icons.phone_android_rounded,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle(context, "Địa chỉ"),
                    _buildTextField(
                      context,
                      controller: _addressController,
                      label: 'Địa chỉ kho/văn phòng',
                      hint: 'KCN, số nhà, đường...',
                      icon: Icons.location_on_outlined,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      context,
                      controller: _cityController,
                      label: 'Tỉnh/Thành phố',
                      hint: 'Ví dụ: Bình Dương',
                      icon: Icons.map_outlined,
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle(context, "Trạng thái hợp tác"),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: _fieldDecoration(context),
                      child: Row(
                        children: [
                          Icon(
                              _isActive
                                  ? Icons.check_circle_outline
                                  : Icons.block_flipped,
                              color: _isActive ? Colors.green : cs.error),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _isActive
                                  ? "Đang hoạt động (Active)"
                                  : "Ngừng hoạt động (Inactive)",
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: _isActive ? Colors.green : cs.error),
                            ),
                          ),
                          Switch(
                            value: _isActive,
                            onChanged: (val) => setState(() => _isActive = val),
                            activeColor: Colors.green,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Ngày đăng ký: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}",
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: cs.outline),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomSheet: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
          child: AppButton(
            text: "Lưu nhà cung cấp",
            isLoading: supplierVM.isLoading,
            onPressed: _saveSupplier,
          ),
        ),
      ),
    );
  }

  // --- Helpers giữ nguyên cấu trúc cũ của bạn ---

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          decoration: _fieldDecoration(context),
          child: TextFormField(
            controller: controller,
            validator: validator,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(icon, color: cs.primary, size: 20),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  BoxDecoration _fieldDecoration(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return BoxDecoration(
      color: cs.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: cs.outline.withOpacity(0.2)),
    );
  }
}
