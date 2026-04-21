import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:manager/core/utils/app_responsive.dart';
import 'package:manager/data/models/branch.dart';
import 'package:manager/viewmodels/branch_viewmodel.dart';
import 'package:manager/views/widgets/app_button.dart';
import 'package:manager/views/widgets/app_sliver_app_bar.dart';
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

class _BranchFormScreenState extends State<BranchFormScreen> {
  late TextEditingController codeController;
  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController emailController;
  late TextEditingController addressController;
  late TextEditingController cityController;

  bool _isActive = true;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _initControllers();
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

  @override
  void dispose() {
    codeController.dispose();
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    addressController.dispose();
    cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.initialBranch != null;
    final title = isEditing ? 'Chỉnh sửa chi nhánh' : 'Thêm chi nhánh mới';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          AppSliverAppBar(
            title: title,
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
              child: Consumer<BranchViewModel>(
                builder: (_, vm, __) {
                  return Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle(context, "Thông tin chi nhánh"),
                        _buildTextField(
                          controller: codeController,
                          label: 'Mã chi nhánh',
                          hint: 'VD: CN001',
                          icon: Icons.tag_rounded,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Vui lòng nhập mã chi nhánh';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: context.rh(16)),
                        _buildTextField(
                          controller: nameController,
                          label: 'Tên chi nhánh',
                          hint: 'VD: Chi nhánh Hà Nội',
                          icon: Icons.location_on_rounded,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Vui lòng nhập tên chi nhánh';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: context.rh(16)),
                        _buildTextField(
                          controller: phoneController,
                          label: 'Điện thoại',
                          hint: 'VD: 0123456789',
                          icon: Icons.phone_rounded,
                          keyboardType: TextInputType.phone,
                        ),
                        SizedBox(height: context.rh(16)),
                        _buildTextField(
                          controller: emailController,
                          label: 'Email',
                          hint: 'VD: branch@company.com',
                          icon: Icons.email_rounded,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value != null &&
                                value.isNotEmpty &&
                                !RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
                                    .hasMatch(value)) {
                              return 'Email không hợp lệ';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: context.rh(24)),
                        _buildSectionTitle(context, "Địa chỉ"),
                        _buildTextField(
                          controller: addressController,
                          label: 'Địa chỉ chi tiết',
                          hint: 'VD: 123 Đường ABC, Quận XYZ',
                          icon: Icons.home_rounded,
                          maxLines: 3,
                        ),
                        SizedBox(height: context.rh(16)),
                        _buildTextField(
                          controller: cityController,
                          label: 'Thành phố',
                          hint: 'VD: Hà Nội',
                          icon: Icons.domain_rounded,
                        ),
                        SizedBox(height: context.rh(24)),
                        _buildSectionTitle(context, "Trạng thái"),
                        _buildStatusDropdown(context),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      bottomSheet: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            context.rw(16),
            context.rh(12),
            context.rw(16),
            context.rh(30),
          ),
          child: Consumer<BranchViewModel>(
            builder: (_, vm, __) {
              return AppButton(
                text: isEditing ? 'Cập nhật' : 'Thêm mới',
                isLoading: vm.isLoading,
                onPressed: vm.isLoading
                    ? null
                    : () => _onSubmit(context, vm, isEditing),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: context.sp(14),
          ),
        ),
        SizedBox(height: context.rh(8)),
        Container(
          decoration: _fieldDecoration(),
          child: TextFormField(
            controller: controller,
            validator: validator,
            keyboardType: keyboardType,
            maxLines: maxLines,
            minLines: maxLines == 1 ? 1 : null,
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

  Widget _buildStatusDropdown(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trạng thái',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: context.sp(14),
          ),
        ),
        SizedBox(height: context.rh(8)),
        Container(
          padding: EdgeInsets.all(context.rw(12)),
          decoration: _fieldDecoration(),
          child: Row(
            children: [
              Icon(
                _isActive ? Icons.check_circle_outline : Icons.block_flipped,
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
      ],
    );
  }

  BoxDecoration _fieldDecoration() {
    final cs = Theme.of(context).colorScheme;
    return BoxDecoration(
      color: cs.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: cs.outline.withOpacity(0.2)),
    );
  }

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

  Future<void> _onSubmit(
      BuildContext context, BranchViewModel vm, bool isEditing) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final branch = Branch(
      id: widget.initialBranch?.id ?? 0,
      code: codeController.text,
      name: nameController.text,
      phone: phoneController.text.isEmpty ? null : phoneController.text,
      email: emailController.text.isEmpty ? null : emailController.text,
      address: addressController.text.isEmpty ? null : addressController.text,
      city: cityController.text.isEmpty ? null : cityController.text,
      status: _isActive ? 'Active' : 'Inactive',
    );

    bool success = false;

    if (isEditing) {
      success = await vm.updateBranch(widget.initialBranch!.id, branch);
    } else {
      success = await vm.createBranch(branch);
    }

    if (!mounted) return;

    if (success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing ? 'Cập nhật thành công!' : 'Thêm mới thành công!',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      context.pop();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            vm.error ?? 'Có lỗi xảy ra',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }
}
