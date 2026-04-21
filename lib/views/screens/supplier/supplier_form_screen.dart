import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:manager/core/extensions/l10n_extension.dart';
import 'package:manager/core/utils/app_responsive.dart';
import 'package:manager/data/models/supplier.dart';
import 'package:manager/viewmodels/supplier_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:manager/views/widgets/app_button.dart';
import 'package:manager/views/widgets/app_sliver_app_bar.dart';
import 'package:manager/views/widgets/app_snackbar.dart';

class SupplierFormScreen extends StatefulWidget {
  final Supplier? supplier;

  const SupplierFormScreen({super.key, this.supplier});

  @override
  State<SupplierFormScreen> createState() => _SupplierFormScreenState();
}

class _SupplierFormScreenState extends State<SupplierFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();

  bool _isActive = true;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.supplier != null;

    if (_isEditMode && widget.supplier != null) {
      final s = widget.supplier!;
      _nameController.text = s.name ?? '';
      _contactPersonController.text = s.contactPerson ?? '';
      _emailController.text = s.email ?? '';
      _phoneController.text = s.phone ?? '';
      _addressController.text = s.address ?? '';
      _cityController.text = s.city ?? '';
      //_isActive = s.status?.toLowerCase() == 'active' || s.status == '1';
    }
  }

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

      final Supplier supplierData = Supplier(
        id: _isEditMode ? widget.supplier!.id : 0,
        name: _nameController.text.trim(),
        contactPerson: _contactPersonController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
      );

      bool success = false;

      if (_isEditMode) {
        success =
            await supplierVM.updateSupplier(widget.supplier!.id!, supplierData);
      } else {
        success = await supplierVM.createSupplier(supplierData);
      }

      if (mounted) {
        if (success) {
          AppSnackbar.showSuccess(
            context,
            _isEditMode
                ? context.l10n.action_success(
                    context.l10n.common_edit, context.l10n.supplier)
                : context.l10n.action_success(
                    context.l10n.common_add, context.l10n.supplier),
          );
          context.pop();
        } else {
          AppSnackbar.showError(
              context,
              _isEditMode
                  ? context.l10n.action_failed(context.l10n.common_edit,
                      context.l10n.supplier.toLowerCase())
                  : context.l10n.action_failed(context.l10n.common_add,
                      context.l10n.supplier.toLowerCase()));
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
          AppSliverAppBar(
            title: _isEditMode
                ? context.l10n.supplier_edit
                : context.l10n.supplier_add,
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
                    _buildSectionTitle(context, "Thông tin định danh"),
                    _buildTextField(
                      context,
                      controller: _nameController,
                      label: 'Tên nhà cung cấp *',
                      hint: 'Ví dụ: Công ty Thép Hòa Phát',
                      icon: Icons.business_rounded,
                      validator: (v) => v!.trim().isEmpty
                          ? 'Vui lòng nhập tên nhà cung cấp'
                          : null,
                    ),
                    SizedBox(height: context.rh(16)),
                    _buildTextField(
                      context,
                      controller: _contactPersonController,
                      label: 'Người liên hệ',
                      hint: 'Tên nhân viên kinh doanh/đại diện',
                      icon: Icons.person_pin_rounded,
                    ),
                    SizedBox(height: context.rh(24)),
                    _buildSectionTitle(context, "Thông tin liên lạc"),
                    _buildTextField(
                      context,
                      controller: _emailController,
                      label: 'Email *',
                      hint: 'sales@supplier.com',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        final value = v?.trim() ?? '';
                        if (value.isEmpty) return 'Vui lòng nhập email';
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(value)) {
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
                      hint: 'Ví dụ: 028xxxxxxxx',
                      icon: Icons.phone_android_rounded,
                      keyboardType: TextInputType.phone,
                    ),
                    SizedBox(height: context.rh(24)),
                    _buildSectionTitle(context, "Địa chỉ"),
                    _buildTextField(
                      context,
                      controller: _addressController,
                      label: 'Địa chỉ kho/văn phòng',
                      hint: 'KCN, số nhà, đường...',
                      icon: Icons.location_on_outlined,
                    ),
                    SizedBox(height: context.rh(16)),
                    _buildTextField(
                      context,
                      controller: _cityController,
                      label: 'Tỉnh/Thành phố',
                      hint: 'Ví dụ: Bình Dương',
                      icon: Icons.map_outlined,
                    ),
                    SizedBox(height: context.rh(24)),
                    if (_isEditMode && widget.supplier?.createdAt != null)
                      Text(
                        "Ngày đăng ký: ${widget.supplier?.createdAt}",
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
            text: context.l10n.supplier_save,
            isLoading: supplierVM.isLoading,
            onPressed: _saveSupplier,
          ),
        ),
      ),
    );
  }

  // ==================== Helper Widgets (giữ nguyên) ====================

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
                  horizontal: context.rw(16), vertical: context.rh(14)),
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
