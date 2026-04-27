import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:manager/core/extensions/l10n_extension.dart';
import 'package:manager/core/utils/app_responsive.dart';
import 'package:manager/data/models/supplier.dart';
import 'package:manager/viewmodels/supplier_viewmodel.dart';
import 'package:manager/views/widgets/alerts/top_alert.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart'; // Thêm import

import 'package:manager/views/widgets/app_button.dart';
import 'package:manager/views/widgets/app_sliver_app_bar.dart';
import 'package:manager/views/widgets/app_snackbar.dart';

class SupplierFormScreen extends StatefulWidget {
  final Supplier? supplier;

  const SupplierFormScreen({super.key, this.supplier});

  @override
  State<SupplierFormScreen> createState() => _SupplierFormScreenState();
}

class _SupplierFormScreenState extends State<SupplierFormScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();

  bool _isPageReady = false;

  bool get _isEditMode => widget.supplier != null;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _animController, curve: Curves.easeOutCubic));

    if (_isEditMode) {
      final s = widget.supplier!;
      _nameController.text = s.name ?? '';
      _contactPersonController.text = s.contactPerson ?? '';
      _emailController.text = s.email ?? '';
      _phoneController.text = s.phone ?? '';
      _addressController.text = s.address ?? '';
      _cityController.text = s.city ?? '';
    }

    _preparePage();
  }

  Future<void> _preparePage() async {
    await Future.delayed(const Duration(milliseconds: 450));
    if (mounted) {
      setState(() => _isPageReady = true);
      _animController.forward();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
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
      final supplierData = Supplier(
        id: _isEditMode ? widget.supplier!.id : 0,
        name: _nameController.text.trim(),
        contactPerson: _contactPersonController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
      );

      bool success = _isEditMode
          ? await supplierVM.updateSupplier(widget.supplier!.id!, supplierData)
          : await supplierVM.createSupplier(supplierData);

      if (mounted) {
        if (success) {
          TopAlert.success(context, _isEditMode
              ? context.l10n.action_success(
              context.l10n.common_edit, context.l10n.supplier)
              : context.l10n.action_success(
              context.l10n.common_add, context.l10n.supplier),
          );
          context.pop();
        } else {
          TopAlert.error(context, supplierVM.error ?? 'Lỗi hệ thống');
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
      body: !_isPageReady
          ? Center(
              child: LoadingAnimationWidget.dotsTriangle(
                color: cs.tertiary,
                size: context.rw(32),
              ),
            )
          : FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    AppSliverAppBar(
                      title: _isEditMode
                          ? context.l10n.supplier_edit
                          : context.l10n.supplier_add,
                      showBackButton: true,
                      height: 80,
                    ),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(context.rw(16),
                          context.rh(24), context.rw(16), context.rh(120)),
                      sliver: SliverToBoxAdapter(
                        child: Form(
                          key: _formKey,
                          child: RepaintBoundary(
                            child: Column(
                              children: [
                                _buildSection(
                                  context,
                                  title: "Thông tin định danh",
                                  icon: Icons.badge_rounded,
                                  children: [
                                    _buildTextField(context,
                                        controller: _nameController,
                                        label: 'Tên nhà cung cấp',
                                        hint: 'Công ty Thép Hòa Phát',
                                        icon: Icons.business_rounded,
                                        isRequired: true,
                                        validator: (v) => v!.trim().isEmpty
                                            ? 'Vui lòng nhập tên'
                                            : null),
                                    SizedBox(height: context.rh(14)),
                                    _buildTextField(context,
                                        controller: _contactPersonController,
                                        label: 'Người liên hệ',
                                        hint: 'Tên nhân viên đại diện',
                                        icon: Icons.person_pin_rounded),
                                  ],
                                ),
                                SizedBox(height: context.rh(16)),
                                _buildSection(
                                  context,
                                  title: "Thông tin liên lạc",
                                  icon: Icons.contact_phone_rounded,
                                  children: [
                                    _buildTextField(
                                      context,
                                      controller: _emailController,
                                      label: 'Email',
                                      hint: 'sales@supplier.com',
                                      icon: Icons.email_outlined,
                                      isRequired: true,
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (v) {
                                        final val = v?.trim() ?? '';
                                        if (val.isEmpty)
                                          return 'Vui lòng nhập email';
                                        if (!RegExp(
                                                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                            .hasMatch(val))
                                          return 'Email không hợp lệ';
                                        return null;
                                      },
                                    ),
                                    SizedBox(height: context.rh(14)),
                                    _buildTextField(context,
                                        controller: _phoneController,
                                        label: 'Số điện thoại',
                                        hint: '028xxxxxxxx',
                                        icon: Icons.phone_android_rounded,
                                        keyboardType: TextInputType.phone),
                                  ],
                                ),
                                SizedBox(height: context.rh(16)),
                                _buildSection(
                                  context,
                                  title: "Vị trí địa chỉ",
                                  icon: Icons.location_on_rounded,
                                  children: [
                                    _buildTextField(context,
                                        controller: _addressController,
                                        label: 'Địa chỉ trụ sở',
                                        hint: 'Số nhà, đường...',
                                        icon: Icons.home_outlined),
                                    SizedBox(height: context.rh(14)),
                                    _buildTextField(context,
                                        controller: _cityController,
                                        label: 'Tỉnh/Thành phố',
                                        hint: 'Bình Dương',
                                        icon: Icons.map_outlined),
                                  ],
                                ),
                                if (_isEditMode &&
                                    widget.supplier?.createdAt != null) ...[
                                  SizedBox(height: context.rh(24)),
                                  Text(
                                    "Ngày tạo: ${widget.supplier!.createdAt!}",
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                            color: cs.outline,
                                            fontStyle: FontStyle.italic),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      bottomSheet: _isPageReady ? _buildBottomSave(context, supplierVM) : null,
    );
  }

  // --- REUSABLE COMPONENTS ---

  Widget _buildSection(BuildContext context,
      {required String title,
      required IconData icon,
      required List<Widget> children}) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
              color: cs.shadow.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
                context.rw(16), context.rh(14), context.rw(16), context.rh(4)),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                      color: cs.tertiaryContainer,
                      borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, size: context.sp(15), color: cs.tertiary),
                ),
                SizedBox(width: context.rw(10)),
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                      fontSize: context.sp(11),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: cs.tertiary),
                ),
              ],
            ),
          ),
          Divider(
              height: 1,
              thickness: 1,
              color: cs.outlineVariant.withOpacity(0.4)),
          Padding(
              padding: EdgeInsets.all(context.rw(16)),
              child: Column(children: children)),
        ],
      ),
    );
  }

  Widget _buildTextField(BuildContext context,
      {required TextEditingController controller,
      required String label,
      required String hint,
      required IconData icon,
      TextInputType keyboardType = TextInputType.text,
      String? Function(String?)? validator,
      bool isRequired = false}) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: context.sp(13),
                    color: cs.onSurface)),
            if (isRequired)
              Text(' *',
                  style: TextStyle(color: cs.error, fontSize: context.sp(13))),
          ],
        ),
        SizedBox(height: context.rh(7)),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          style: TextStyle(fontSize: context.sp(14)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
                color: cs.outline.withOpacity(0.5), fontSize: context.sp(14)),
            prefixIcon: Icon(icon, color: cs.tertiary, size: context.sp(19)),
            filled: true,
            fillColor: cs.surfaceContainerLowest,
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    BorderSide(color: cs.outlineVariant.withOpacity(0.6))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: cs.tertiary, width: 1.6)),
            errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: cs.error)),
            focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: cs.error, width: 1.6)),
            contentPadding: EdgeInsets.symmetric(
                horizontal: context.rw(14), vertical: context.rh(13)),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomSave(BuildContext context, SupplierViewmodel vm) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        border:
            Border(top: BorderSide(color: cs.outlineVariant.withOpacity(0.3))),
        boxShadow: [
          BoxShadow(
              color: cs.shadow.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, -3))
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              context.rw(16), context.rh(12), context.rw(16), context.rh(12)),
          child: AppButton(
            text: context.l10n.supplier_save,
            isLoading: vm.isLoading,
            onPressed: _saveSupplier,
          ),
        ),
      ),
    );
  }
}
