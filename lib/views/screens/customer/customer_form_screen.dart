import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:manager/core/extensions/l10n_extension.dart';
import 'package:manager/core/utils/app_responsive.dart';
import 'package:manager/data/models/customer.dart';
import 'package:manager/viewmodels/customer_viewmodel.dart';
import 'package:manager/views/widgets/alerts/top_alert.dart';
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

class _CustomerFormScreenState extends State<CustomerFormScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();

  bool _isActive = true;
  bool _isEditMode = false;
  bool _isPageReady = false; // ← thêm flag loading

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim; // ← thêm slide animation

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.customer != null;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _animController, curve: Curves.easeOutCubic));

    if (_isEditMode && widget.customer != null) {
      final c = widget.customer!;
      _nameController.text = c.name ?? '';
      _emailController.text = c.email ?? '';
      _phoneController.text = c.phone ?? '';
      _addressController.text = c.address ?? '';
      _cityController.text = c.city ?? '';
      _isActive = c.status?.toLowerCase() == 'active' || c.status == '1';
    }

    _preparePage(); // ← gọi chuẩn bị loading
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
          TopAlert.success(
            context,
            _isEditMode
                ? context.l10n.action_success(context.l10n.common_update,
                    context.l10n.customer.toLowerCase())
                : context.l10n.action_success(context.l10n.common_add,
                    context.l10n.customer.toLowerCase()),
          );
          context.pop();
        } else {
          TopAlert.error(
            context,
            _isEditMode
                ? context.l10n.action_failed(context.l10n.common_update,
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
      body: !_isPageReady
          ? Center(
              child: LoadingAnimationWidget.dotsTriangle(
                color: cs.primary,
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
                          ? context.l10n.customer_edit
                          : context.l10n.customer_add,
                      showBackButton: true,
                      height: 80,
                    ),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        context.rw(16),
                        context.rh(24),
                        context.rw(16),
                        context.rh(120),
                      ),
                      sliver: SliverToBoxAdapter(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSection(
                                context,
                                title: "Thông tin liên hệ",
                                icon: Icons.person_pin_rounded,
                                children: [
                                  _buildTextField(
                                    context,
                                    controller: _nameController,
                                    label: 'Tên khách hàng',
                                    hint: 'Nhập họ và tên',
                                    icon: Icons.person_outline_rounded,
                                    isRequired: true,
                                    validator: (v) => v!.trim().isEmpty
                                        ? 'Vui lòng nhập tên'
                                        : null,
                                  ),
                                  SizedBox(height: context.rh(14)),
                                  _buildTextField(
                                    context,
                                    controller: _emailController,
                                    label: 'Email',
                                    hint: 'example@gmail.com',
                                    icon: Icons.email_outlined,
                                    isRequired: true,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (v) {
                                      if (v!.trim().isEmpty)
                                        return 'Vui lòng nhập email';
                                      if (!RegExp(
                                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                          .hasMatch(v)) {
                                        return 'Email không hợp lệ';
                                      }
                                      return null;
                                    },
                                  ),
                                  SizedBox(height: context.rh(14)),
                                  _buildTextField(
                                    context,
                                    controller: _phoneController,
                                    label: 'Số điện thoại',
                                    hint: '0901 234 567',
                                    icon: Icons.phone_android_rounded,
                                    keyboardType: TextInputType.phone,
                                  ),
                                ],
                              ),
                              SizedBox(height: context.rh(16)),
                              _buildSection(
                                context,
                                title: "Địa chỉ",
                                icon: Icons.location_on_rounded,
                                children: [
                                  _buildTextField(
                                    context,
                                    controller: _addressController,
                                    label: 'Địa chỉ chi tiết',
                                    hint: 'Số nhà, tên đường...',
                                    icon: Icons.home_outlined,
                                  ),
                                  SizedBox(height: context.rh(14)),
                                  _buildTextField(
                                    context,
                                    controller: _cityController,
                                    label: 'Thành phố',
                                    hint: 'Ví dụ: Hồ Chí Minh',
                                    icon: Icons.map_outlined,
                                  ),
                                ],
                              ),
                              SizedBox(height: context.rh(16)),
                              _buildSection(
                                context,
                                title: "Trạng thái",
                                icon: Icons.toggle_on_rounded,
                                children: [_buildStatusToggle(context)],
                              ),
                              if (_isEditMode &&
                                  widget.customer?.createdAt != null) ...[
                                SizedBox(height: context.rh(16)),
                                Center(
                                  child: Text(
                                    "Ngày tạo: ${DateFormat('dd/MM/yyyy').format(widget.customer!.createdAt!)}",
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: cs.outline),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      bottomSheet: _isPageReady ? _buildBottomSave(context, customerVM) : null,
    );
  }

  // ──────────────────────────────────────────────────────────────────
  //  Section Card
  // ──────────────────────────────────────────────────────────────────

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
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
            offset: const Offset(0, 2),
          ),
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
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: context.sp(15), color: cs.tertiary),
                ),
                SizedBox(width: context.rw(10)),
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: context.sp(11),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: cs.tertiary,
                  ),
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
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────
  //  Text Field
  // ──────────────────────────────────────────────────────────────────

  Widget _buildTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool isRequired = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: context.sp(13),
                color: cs.onSurface,
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 3),
              Text(
                '*',
                style: TextStyle(color: cs.error, fontSize: context.sp(13)),
              ),
            ],
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
              color: cs.outline.withOpacity(0.5),
              fontSize: context.sp(14),
            ),
            prefixIcon: Icon(icon, color: cs.tertiary, size: context.sp(19)),
            filled: true,
            fillColor: cs.surfaceContainerLowest,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: cs.outlineVariant.withOpacity(0.6)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: cs.primary, width: 1.6),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: cs.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: cs.error, width: 1.6),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: context.rw(14),
              vertical: context.rh(13),
            ),
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────
  //  Status Toggle
  // ──────────────────────────────────────────────────────────────────

  Widget _buildStatusToggle(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isActive = _isActive;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: EdgeInsets.symmetric(
          horizontal: context.rw(14), vertical: context.rh(10)),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.withOpacity(0.07)
            : cs.error.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isActive
              ? Colors.green.withOpacity(0.3)
              : cs.error.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              isActive ? Icons.check_circle_rounded : Icons.cancel_rounded,
              key: ValueKey(isActive),
              color: isActive ? Colors.green : cs.error,
              size: context.sp(22),
            ),
          ),
          SizedBox(width: context.rw(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    isActive ? "Đang hoạt động" : "Ngừng hoạt động",
                    key: ValueKey(isActive),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: context.sp(14),
                      color: isActive ? Colors.green.shade700 : cs.error,
                    ),
                  ),
                ),
                Text(
                  isActive
                      ? "Khách hàng đang được phép giao dịch"
                      : "Khách hàng tạm thời bị vô hiệu",
                  style: TextStyle(
                    fontSize: context.sp(11),
                    color: cs.outline,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isActive,
            onChanged: (val) => setState(() => _isActive = val),
            activeColor: Colors.green,
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────
  //  Bottom Save Bar
  // ──────────────────────────────────────────────────────────────────

  Widget _buildBottomSave(BuildContext context, CustomerViewmodel vm) {
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
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              context.rw(16), context.rh(12), context.rw(16), context.rh(12)),
          child: AppButton(
            text: context.l10n.customer_save,
            isLoading: vm.isLoading,
            onPressed: _saveCustomer,
          ),
        ),
      ),
    );
  }
}
