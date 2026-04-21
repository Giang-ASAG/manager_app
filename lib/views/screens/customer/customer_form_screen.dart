import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:manager/core/utils/app_responsive.dart';
import 'package:manager/data/models/customer.dart';
import 'package:manager/viewmodels/customer_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:manager/views/widgets/app_button.dart';
import 'package:manager/views/widgets/app_sliver_app_bar.dart';
import 'package:manager/views/widgets/app_snackbar.dart';

class CustomerFormScreen extends StatefulWidget {
  const CustomerFormScreen({super.key});

  @override
  State<CustomerFormScreen> createState() => _CustomersFormScreenState();
}

class _CustomersFormScreenState extends State<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers cho các trường dữ liệu
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();

  bool _isActive = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _saveCustomer() async {
    if (_formKey.currentState!.validate()) {
      final customerVM = context.read<CustomerViewmodel>();

      // Tạo Map hoặc Model để gửi lên API
      final Customer customerData = Customer(
          id: 0,
          name: _nameController.text,
          status: _isActive == true ? "Active" : "Inactive",
          address: _addressController.text,
          city: _cityController.text,
          email: _emailController.text,
          phone: _phoneController.text);

      final success = await customerVM.createCustomer(customerData);

      if (mounted) {
        if (success) {
          AppSnackbar.showSuccess(context, "Thêm khách hàng thành công");
          context.pop();
        } else {
          AppSnackbar.showError(context, 'Lỗi: ${customerVM.error}');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final customerVM = context.watch<CustomerViewmodel>();

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      body: CustomScrollView(
        slivers: [
          const AppSliverAppBar(
            title: 'Thêm khách hàng mới',
            showBackButton: true,
            height: 80,
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(context.rw(16), context.rh(24), context.rw(16), context.rh(120)),
            sliver: SliverToBoxAdapter(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(context, "Thông tin liên hệ"),
                    _buildTextField(
                      context,
                      controller: _nameController,
                      label: 'Tên khách hàng *',
                      hint: 'Nhập họ và tên',
                      icon: Icons.person_outline_rounded,
                      validator: (v) => v!.isEmpty ? 'Vui lòng nhập tên' : null,
                    ),
                    SizedBox(height: context.rh(16)),
                    _buildTextField(
                      context,
                      controller: _emailController,
                      label: 'Email *',
                      hint: 'example@gmail.com',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v!.isEmpty) return 'Vui lòng nhập email';
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(v)) return 'Email không hợp lệ';
                        return null;
                      },
                    ),
                    SizedBox(height: context.rh(16)),
                    _buildTextField(
                      context,
                      controller: _phoneController,
                      label: 'Số điện thoại',
                      hint: 'Ví dụ: 0901234567',
                      icon: Icons.phone_android_rounded,
                      keyboardType: TextInputType.phone,
                    ),
                    SizedBox(height: context.rh(24)),
                    _buildSectionTitle(context, "Địa chỉ"),
                    _buildTextField(
                      context,
                      controller: _addressController,
                      label: 'Địa chỉ chi tiết',
                      hint: 'Số nhà, tên đường...',
                      icon: Icons.location_on_outlined,
                    ),
                    SizedBox(height: context.rh(16)),
                    _buildTextField(
                      context,
                      controller: _cityController,
                      label: 'Thành phố',
                      hint: 'Ví dụ: Hồ Chí Minh',
                      icon: Icons.map_outlined,
                    ),
                    SizedBox(height: context.rh(24)),
                    _buildSectionTitle(context, "Trạng thái"),
                    Container(
                      padding: EdgeInsets.all(context.rw(12)),
                      decoration: _fieldDecoration(context),
                      child: Row(
                        children: [
                          Icon(
                              _isActive
                                  ? Icons.check_circle_outline
                                  : Icons.block_flipped,
                              color: _isActive ? Colors.green : cs.error),
                          SizedBox(width: context.rw(12)),
                          Expanded(
                            child: Text(
                              _isActive
                                  ? "Đang hoạt động (Active)"
                                  : "Ngừng hoạt động (Inactive)",
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: context.sp(14),
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
                    SizedBox(height: context.rh(20)),
                    Text(
                      "Ngày khởi tạo: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}",
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
          padding: EdgeInsets.fromLTRB(context.rw(16), context.rh(12), context.rw(16), context.rh(30)),
          child: AppButton(
            text: "Lưu khách hàng",
            isLoading: customerVM.isLoading,
            onPressed: _saveCustomer,
          ),
        ),
      ),
    );
  }

  // --- Helpers ---

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.rh(12), left: context.rw(4)),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: context.sp(12),
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
        Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.sp(14))),
        SizedBox(height: context.rh(8)),
        Container(
          decoration: _fieldDecoration(context),
          child: TextFormField(
            controller: controller,
            validator: validator,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(icon, color: cs.primary, size: context.sp(20)),
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: context.rw(16), vertical: context.rh(14)),
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
