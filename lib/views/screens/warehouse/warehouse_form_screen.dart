import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart'; // Thêm import này
import 'package:manager/core/extensions/l10n_extension.dart';
import 'package:manager/core/utils/app_responsive.dart';
import 'package:manager/data/models/branch.dart';
import 'package:manager/data/models/warehouse.dart';
import 'package:manager/viewmodels/branch_viewmodel.dart';
import 'package:manager/viewmodels/warehouse_viewmodel.dart';
import 'package:manager/views/widgets/alerts/top_alert.dart';
import 'package:manager/views/widgets/app_button.dart';
import 'package:manager/views/widgets/app_sliver_app_bar.dart';
import 'package:manager/views/widgets/app_snackbar.dart';
import 'package:provider/provider.dart';

class WarehouseFormScreen extends StatefulWidget {
  final Warehouse? warehouse;

  const WarehouseFormScreen({super.key, this.warehouse});

  @override
  State<WarehouseFormScreen> createState() => _WarehouseFormScreenState();
}

class _WarehouseFormScreenState extends State<WarehouseFormScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController codeCtrl;
  late TextEditingController nameCtrl;
  late TextEditingController phoneCtrl;
  late TextEditingController addressCtrl;
  late TextEditingController cityCtrl;

  String selectedStatus = 'active';
  bool _isPageReady = false;

  bool get _isEditMode => widget.warehouse != null;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  Branch? selectedBranch;

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    codeCtrl = TextEditingController(text: widget.warehouse?.code ?? '');
    nameCtrl = TextEditingController(text: widget.warehouse?.name ?? '');
    phoneCtrl = TextEditingController(text: widget.warehouse?.phone ?? '');
    addressCtrl = TextEditingController(text: widget.warehouse?.address ?? '');
    cityCtrl = TextEditingController(text: widget.warehouse?.city ?? '');

    final status = (widget.warehouse?.status ?? 'active').toLowerCase();
    selectedStatus =
        (status == 'active' || status == 'inactive') ? status : 'active';

    // Setup animations
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _animController, curve: Curves.easeOutCubic));

    // Trigger branch loading safely
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final branchVM = context.read<BranchViewModel>();
      if (branchVM.branches.isEmpty && !branchVM.isLoading) {
        branchVM.fetchBranches();
      }

      // Set selected branch for edit mode (after possible fetch)
      if (_isEditMode && widget.warehouse != null) {
        _setInitialBranch(branchVM);
      }

      _preparePage();
    });
  }

  void _setInitialBranch(BranchViewModel branchVM) {
    if (branchVM.branches.isNotEmpty) {
      selectedBranch = branchVM.branches.firstWhere(
        (b) => b.id == widget.warehouse!.branchId,
        orElse: () => branchVM.branches.first,
      );
    }
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
    codeCtrl.dispose();
    nameCtrl.dispose();
    phoneCtrl.dispose();
    addressCtrl.dispose();
    cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      if (selectedBranch == null) {
        TopAlert.error(context, 'Vui lòng chọn chi nhánh');
        return;
      }

      final vm = context.read<WarehouseViewModel>();
      final warehouseData = Warehouse(
        id: widget.warehouse?.id ?? 0,
        branchId: selectedBranch!.id,
        branchName: selectedBranch!.name,
        code: codeCtrl.text.trim(),
        name: nameCtrl.text.trim(),
        phone: phoneCtrl.text.trim(),
        address: addressCtrl.text.trim(),
        city: cityCtrl.text.trim(),
        status: selectedStatus,
        createdAt: widget.warehouse?.createdAt ?? DateTime.now(),
      );

      bool success = _isEditMode
          ? await vm.updateWarehouse(widget.warehouse!.id, warehouseData)
          : await vm.createWarehouse(warehouseData);

      if (mounted) {
        if (success) {
          TopAlert.success(
              context,
              _isEditMode
                  ? context.l10n.action_success(
                      context.l10n.common_edit, context.l10n.warehouse)
                  : context.l10n.action_success(
                      context.l10n.common_add, context.l10n.warehouse));
          context.pop();
        } else {
          debugPrint(vm.error);
          TopAlert.error(context, vm.error ?? 'Lỗi hệ thống');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final warehouseVM = context.watch<WarehouseViewModel>();

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
                          ? context.l10n.warehouse_edit
                          : context.l10n.warehouse_add,
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
                                        controller: codeCtrl,
                                        label: 'Mã kho hàng',
                                        hint: 'Ví dụ: WH001',
                                        icon: Icons.qr_code_2_rounded,
                                        isRequired: true,
                                        validator: (v) => v!.trim().isEmpty
                                            ? 'Vui lòng nhập mã'
                                            : null),
                                    SizedBox(height: context.rh(14)),
                                    _buildTextField(context,
                                        controller: nameCtrl,
                                        label: 'Tên kho hàng',
                                        hint: 'Ví dụ: Kho Tân Bình',
                                        icon: Icons.warehouse_rounded,
                                        isRequired: true,
                                        validator: (v) => v!.trim().isEmpty
                                            ? 'Vui lòng nhập tên'
                                            : null),
                                    SizedBox(height: context.rh(14)),
                                    _buildBranchDropdown(context),
                                  ],
                                ),
                                SizedBox(height: context.rh(16)),
                                _buildSection(
                                  context,
                                  title: "Thông tin liên lạc",
                                  icon: Icons.contact_phone_rounded,
                                  children: [
                                    _buildTextField(context,
                                        controller: phoneCtrl,
                                        label: 'Điện thoại',
                                        hint: '028xxxxxxxx',
                                        icon: Icons.phone_android_rounded,
                                        isRequired: true,
                                        keyboardType: TextInputType.phone,
                                        validator: (v) => v!.trim().isEmpty
                                            ? 'Vui lòng nhập số điện thoại'
                                            : null),
                                  ],
                                ),
                                SizedBox(height: context.rh(16)),
                                _buildSection(
                                  context,
                                  title: "Vị trí địa lý",
                                  icon: Icons.location_on_rounded,
                                  children: [
                                    _buildTextField(context,
                                        controller: addressCtrl,
                                        label: 'Địa chỉ chi tiết',
                                        hint: 'KCN, số nhà, đường...',
                                        icon: Icons.home_outlined,
                                        isRequired: true,
                                        validator: (v) => v!.trim().isEmpty
                                            ? 'Vui lòng nhập địa chỉ'
                                            : null),
                                    SizedBox(height: context.rh(14)),
                                    _buildTextField(context,
                                        controller: cityCtrl,
                                        label: 'Tỉnh/Thành phố',
                                        hint: 'Bình Dương',
                                        icon: Icons.map_outlined,
                                        isRequired: true,
                                        validator: (v) => v!.trim().isEmpty
                                            ? 'Bắt buộc'
                                            : null),
                                  ],
                                ),
                                SizedBox(height: context.rh(16)),
                                _buildSection(
                                  context,
                                  title: "Cài đặt trạng thái",
                                  icon: Icons.settings_power_rounded,
                                  children: [_buildStatusToggle(context)],
                                ),
                                if (_isEditMode &&
                                    widget.warehouse?.createdAt != null) ...[
                                  SizedBox(height: context.rh(24)),
                                  Text(
                                    "Ngày tạo: ${DateFormat('dd/MM/yyyy').format(widget.warehouse!.createdAt!)}",
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
      bottomSheet: _isPageReady ? _buildBottomSave(context, warehouseVM) : null,
    );
  }

  Widget _buildBranchDropdown(BuildContext context) {
    return Consumer<BranchViewModel>(
      builder: (context, vm, _) {
        if (vm.isLoading) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: context.rh(12)),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: context.rw(10)),
                Text("Đang tải chi nhánh..."),
              ],
            ),
          );
        }

        if (vm.branches.isEmpty) {
          return Text(
            "Không có chi nhánh nào",
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          );
        }

        // Auto-select first branch if none selected (for add mode)
        if (selectedBranch == null && vm.branches.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => selectedBranch = vm.branches.first);
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Chi nhánh",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: context.sp(13),
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: context.rh(7)),
            Container(
              padding: EdgeInsets.symmetric(horizontal: context.rw(12)),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .outlineVariant
                      .withOpacity(0.6),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Branch>(
                  value: selectedBranch,
                  isExpanded: true,
                  icon: Icon(Icons.keyboard_arrow_down_rounded,
                      color: Theme.of(context).colorScheme.tertiary),
                  items: vm.branches.map((b) {
                    return DropdownMenuItem(
                      value: b,
                      child: Row(
                        children: [
                          Icon(Icons.business_rounded,
                              size: context.sp(18),
                              color: Theme.of(context).colorScheme.tertiary),
                          SizedBox(width: context.rw(10)),
                          Expanded(
                            child: Text(
                              b.name,
                              style: TextStyle(fontSize: context.sp(14)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => selectedBranch = value);
                  },
                ),
              ),
            ),
          ],
        );
      },
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

  Widget _buildStatusToggle(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isActive = selectedStatus == 'active';

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
                : cs.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(isActive ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: isActive ? Colors.green : cs.error, size: context.sp(22)),
          SizedBox(width: context.rw(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isActive ? "Đang hoạt động" : "Ngừng hoạt động",
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: context.sp(14),
                        color: isActive ? Colors.green.shade700 : cs.error)),
                Text(
                    isActive
                        ? "Kho đang tiếp nhận & xuất hàng"
                        : "Kho tạm thời đóng cửa",
                    style:
                        TextStyle(fontSize: context.sp(11), color: cs.outline)),
              ],
            ),
          ),
          Switch(
            value: isActive,
            onChanged: (val) =>
                setState(() => selectedStatus = val ? 'active' : 'inactive'),
            activeColor: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSave(BuildContext context, WarehouseViewModel vm) {
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
            text: context.l10n.warehouse_save,
            isLoading: vm.isLoading,
            onPressed: _submit,
          ),
        ),
      ),
    );
  }
}
