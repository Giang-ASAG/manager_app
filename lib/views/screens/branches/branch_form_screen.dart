import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:manager/core/extensions/l10n_extension.dart';
import 'package:manager/core/utils/app_responsive.dart';
import 'package:manager/data/models/branch.dart';
import 'package:manager/viewmodels/branch_viewmodel.dart';
import 'package:manager/views/widgets/app_button.dart';
import 'package:manager/views/widgets/app_sliver_app_bar.dart';
import 'package:manager/views/widgets/app_snackbar.dart';
import 'package:provider/provider.dart';

class BranchFormScreen extends StatefulWidget {
  final Branch? initialBranch;

  const BranchFormScreen({
    super.key,
    this.initialBranch,
  });

  @override
  State<BranchFormScreen> createState() => _BranchFormScreenState();
}

class _BranchFormScreenState extends State<BranchFormScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController codeController;
  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController emailController;
  late TextEditingController addressController;
  late TextEditingController cityController;

  bool _isActive = true;
  bool _isPageReady = false;
  final _formKey = GlobalKey<FormState>();

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _initControllers();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _animController, curve: Curves.easeOutCubic));

    _preparePage();
  }

  void _initControllers() {
    codeController =
        TextEditingController(text: widget.initialBranch?.code ?? '');
    nameController =
        TextEditingController(text: widget.initialBranch?.name ?? '');
    phoneController =
        TextEditingController(text: widget.initialBranch?.phone ?? '');
    emailController =
        TextEditingController(text: widget.initialBranch?.email ?? '');
    addressController =
        TextEditingController(text: widget.initialBranch?.address ?? '');
    cityController =
        TextEditingController(text: widget.initialBranch?.city ?? '');
    _isActive = widget.initialBranch?.status != null
        ? widget.initialBranch!.status.toLowerCase() == 'active'
        : true;
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
    codeController.dispose();
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    addressController.dispose();
    cityController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit(
      BuildContext context, BranchViewModel vm, bool isEditing) async {
    if (!_formKey.currentState!.validate()) return;

    final branch = Branch(
      id: widget.initialBranch?.id ?? 0,
      code: codeController.text.trim(),
      name: nameController.text.trim(),
      phone: phoneController.text.trim().isEmpty
          ? null
          : phoneController.text.trim(),
      email: emailController.text.trim().isEmpty
          ? null
          : emailController.text.trim(),
      address: addressController.text.trim().isEmpty
          ? null
          : addressController.text.trim(),
      city: cityController.text.trim().isEmpty
          ? null
          : cityController.text.trim(),
      status: _isActive ? 'Active' : 'Inactive',
    );

    bool success = isEditing
        ? await vm.updateBranch(widget.initialBranch!.id, branch)
        : await vm.createBranch(branch);

    if (mounted) {
      if (success) {
        AppSnackbar.showSuccess(context,
            isEditing ? 'Cập nhật thành công!' : 'Thêm mới thành công!');
        context.pop();
      } else {
        AppSnackbar.showError(context, vm.error ?? 'Có lỗi xảy ra');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final vm = context.watch<BranchViewModel>();
    final isEditing = widget.initialBranch != null;

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
                      title: isEditing
                          ? 'Chỉnh sửa chi nhánh'
                          : 'Thêm chi nhánh mới',
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
                                        controller: codeController,
                                        label: 'Mã chi nhánh',
                                        hint: 'VD: CN001',
                                        icon: Icons.tag_rounded,
                                        isRequired: true,
                                        validator: (v) => v!.isEmpty
                                            ? 'Vui lòng nhập mã'
                                            : null),
                                    SizedBox(height: context.rh(14)),
                                    _buildTextField(context,
                                        controller: nameController,
                                        label: 'Tên chi nhánh',
                                        hint: 'VD: Chi nhánh Hà Nội',
                                        icon: Icons.business_rounded,
                                        isRequired: true,
                                        validator: (v) => v!.isEmpty
                                            ? 'Vui lòng nhập tên'
                                            : null),
                                  ],
                                ),
                                SizedBox(height: context.rh(16)),
                                _buildSection(
                                  context,
                                  title: "Thông tin liên lạc",
                                  icon: Icons.contact_phone_rounded,
                                  children: [
                                    _buildTextField(context,
                                        controller: phoneController,
                                        label: 'Số điện thoại',
                                        hint: '0123456789',
                                        icon: Icons.phone_android_rounded,
                                        keyboardType: TextInputType.phone),
                                    SizedBox(height: context.rh(14)),
                                    _buildTextField(
                                      context,
                                      controller: emailController,
                                      label: 'Email',
                                      hint: 'branch@company.com',
                                      icon: Icons.email_outlined,
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (v) {
                                        if (v != null &&
                                            v.isNotEmpty &&
                                            !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                                .hasMatch(v))
                                          return 'Email không hợp lệ';
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                                SizedBox(height: context.rh(16)),
                                _buildSection(
                                  context,
                                  title: "Địa chỉ trụ sở",
                                  icon: Icons.location_on_rounded,
                                  children: [
                                    _buildTextField(context,
                                        controller: addressController,
                                        label: 'Địa chỉ chi tiết',
                                        hint: 'Số nhà, tên đường...',
                                        icon: Icons.home_outlined,
                                        maxLines: 2),
                                    SizedBox(height: context.rh(14)),
                                    _buildTextField(context,
                                        controller: cityController,
                                        label: 'Thành phố/Tỉnh',
                                        hint: 'VD: Hà Nội',
                                        icon: Icons.map_outlined),
                                  ],
                                ),
                                SizedBox(height: context.rh(16)),
                                _buildSection(
                                  context,
                                  title: "Trạng thái vận hành",
                                  icon: Icons.settings_power_rounded,
                                  children: [_buildStatusToggle(context)],
                                ),
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
      bottomSheet:
          _isPageReady ? _buildBottomSave(context, vm, isEditing) : null,
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
                Text(title.toUpperCase(),
                    style: TextStyle(
                        fontSize: context.sp(11),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: cs.tertiary)),
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
      int maxLines = 1,
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
          maxLines: maxLines,
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

  Widget _buildStatusToggle(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: EdgeInsets.symmetric(
          horizontal: context.rw(14), vertical: context.rh(10)),
      decoration: BoxDecoration(
        color: _isActive
            ? Colors.green.withOpacity(0.07)
            : cs.error.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: _isActive
                ? Colors.green.withOpacity(0.3)
                : cs.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(_isActive ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: _isActive ? Colors.green : cs.error, size: context.sp(22)),
          SizedBox(width: context.rw(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_isActive ? "Đang hoạt động" : "Ngừng hoạt động",
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: context.sp(14),
                        color: _isActive ? Colors.green.shade700 : cs.error)),
                Text(
                    _isActive
                        ? "Chi nhánh khả dụng trên hệ thống"
                        : "Tạm ẩn chi nhánh này",
                    style:
                        TextStyle(fontSize: context.sp(11), color: cs.outline)),
              ],
            ),
          ),
          Switch(
              value: _isActive,
              onChanged: (val) => setState(() => _isActive = val),
              activeColor: Colors.green),
        ],
      ),
    );
  }

  Widget _buildBottomSave(
      BuildContext context, BranchViewModel vm, bool isEditing) {
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
            text: isEditing ? 'Cập nhật chi nhánh' : 'Thêm chi nhánh',
            isLoading: vm.isLoading,
            onPressed: () => _onSubmit(context, vm, isEditing),
          ),
        ),
      ),
    );
  }
}
