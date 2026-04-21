import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:manager/core/extensions/l10n_extension.dart';
import 'package:manager/core/utils/app_responsive.dart';
import 'package:manager/data/models/customer.dart';
import 'package:manager/viewmodels/customer_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:manager/views/widgets/app_button.dart';
import 'package:manager/views/widgets/app_sliver_app_bar.dart';
import 'package:manager/views/widgets/app_snackbar.dart';

class CustomerFormScreen extends StatefulWidget {
  final Customer? customer;

  const CustomerFormScreen({super.key, this.customer});

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();

  bool _isActive = true;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.customer != null;

    if (_isEditMode && widget.customer != null) {
      final c = widget.customer!;
      _nameController.text = c.name ?? '';
      _emailController.text = c.email ?? '';
      _phoneController.text = c.phone ?? '';
      _addressController.text = c.address ?? '';
      _cityController.text = c.city ?? '';
      _isActive = c.status?.toLowerCase() == 'active' || c.status == '1';
    }
  }

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

      final Customer customerData = Customer(
        id: _isEditMode ? widget.customer!.id : 0,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        status: _isActive ? "Active" : "Inactive",
      );

      bool success = true;

      if (_isEditMode) {
        success =
            await customerVM.updateCustomer(customerData.id, customerData);
      } else {
        success = await customerVM.createCustomer(customerData);
      }

      if (mounted) {
        if (success) {
          AppSnackbar.showSuccess(
            context,
            _isEditMode
                ? context.l10n.action_success(context.l10n.common_edit,
                    context.l10n.customer.toLowerCase())
                : context.l10n.action_success(context.l10n.common_add,
                    context.l10n.customer.toLowerCase()),
          );
          context.pop(); // Quay lại màn hình trước
        } else {
          AppSnackbar.showError(
            context,
            _isEditMode
                ? context.l10n.action_failed(context.l10n.common_edit,
                    context.l10n.customer.toLowerCase())
                : context.l10n.action_failed(context.l10n.common_add,
                    context.l10n.customer.toLowerCase()),
          );
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
          AppSliverAppBar(
            title: _isEditMode
                ? context.l10n.customer_edit
                : context.l10n.customer_add,
            showBackButton: true,
            height: 80,
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(context.rw(16), context.rh(24),
                context.rw(16), context.rh(120)),
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
                      validator: (v) =>
                          v!.trim().isEmpty ? 'Vui lòng nhập tên' : null,
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
                        if (v!.trim().isEmpty) return 'Vui lòng nhập email';
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(v)) {
                          return 'Email không hợp lệ';
                        }
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
                            color: _isActive ? Colors.green : cs.error,
                          ),
                          SizedBox(width: context.rw(12)),
                          Expanded(
                            child: Text(
                              _isActive
                                  ? "Đang hoạt động (Active)"
                                  : "Ngừng hoạt động (Inactive)",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: context.sp(14),
                                color: _isActive ? Colors.green : cs.error,
                              ),
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
                    if (_isEditMode && widget.customer?.createdAt != null)
                      Text(
                        "Ngày tạo: ${DateFormat('dd/MM/yyyy').format(widget.customer!.createdAt!)}",
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
          padding: EdgeInsets.fromLTRB(
              context.rw(16), context.rh(12), context.rw(16), context.rh(30)),
          child: AppButton(
            text: context.l10n.customer_save,
            isLoading: customerVM.isLoading,
            onPressed: _saveCustomer,
          ),
        ),
      ),
    );
  }

  // ==================== Helper Widgets ====================

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
        Text(label,
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: context.sp(14))),
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
              contentPadding: EdgeInsets.symmetric(
                horizontal: context.rw(16),
                vertical: context.rh(14),
              ),
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
