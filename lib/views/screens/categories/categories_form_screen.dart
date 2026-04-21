import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:manager/core/extensions/l10n_extension.dart';
import 'package:manager/core/utils/app_responsive.dart';
import 'package:manager/data/models/category.dart';
import 'package:manager/viewmodels/categories_viewmodel.dart';
import 'package:manager/views/widgets/app_button.dart';
import 'package:manager/views/widgets/app_sliver_app_bar.dart';
import 'package:manager/views/widgets/app_snackbar.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class CategoriesFormScreen extends StatefulWidget {
  const CategoriesFormScreen({super.key});

  @override
  State<CategoriesFormScreen> createState() => _CategoriesFormScreenState();
}

class _CategoriesFormScreenState extends State<CategoriesFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Trạng thái mặc định là true (Active)
  bool _isActive = true;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveCategory() async {
    if (_formKey.currentState!.validate()) {
      final categoryVM = context.read<CategoriesViewModel>();

      final newCategory = Category(
        id: 0,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        // Chuyển đổi boolean sang string mapping với backend của bạn
        status: _isActive ? 'Active' : 'Inactive',
      );

      final success = await categoryVM.createCategory(newCategory);

      if (mounted) {
        if (success) {
          AppSnackbar.showSuccess(
              context,
              context.l10n.action_success(
                  context.l10n.common_add, context.l10n.category));
          context.pop();
        } else {
          AppSnackbar.showError(
              context,
              context.l10n.action_failed(
                  context.l10n.common_add, context.l10n.category));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final categoryVM = context.watch<CategoriesViewModel>();

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      body: CustomScrollView(
        slivers: [
          AppSliverAppBar(
            title: context.l10n.category_add,
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
                    _buildSectionTitle(context, "Thông tin danh mục"),

                    _buildTextField(
                      context,
                      controller: _nameController,
                      label: 'Tên danh mục *',
                      hint: 'Ví dụ: Thiết bị văn phòng',
                      icon: Icons.category_rounded,
                      validator: (v) =>
                          v!.isEmpty ? 'Tên không được để trống' : null,
                    ),

                    SizedBox(height: context.rh(20)),

                    _buildTextField(
                      context,
                      controller: _descriptionController,
                      label: 'Mô tả',
                      hint: 'Nhập mô tả danh mục...',
                      icon: Icons.description_rounded,
                      maxLines: 3,
                    ),

                    SizedBox(height: context.rh(24)),

                    // ── Trạng thái (Active/Inactive) ──────────────────
                    _buildSectionTitle(context, "Cài đặt hiển thị"),
                    Container(
                      padding: EdgeInsets.all(context.rw(12)),
                      decoration: _fieldDecoration(context),
                      child: Row(
                        children: [
                          Icon(
                              _isActive
                                  ? Icons.visibility_rounded
                                  : Icons.visibility_off_rounded,
                              color: _isActive ? cs.primary : cs.error),
                          SizedBox(width: context.rw(12)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isActive
                                      ? "Đang hoạt động"
                                      : "Ngừng hoạt động",
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: context.sp(14),
                                        color:
                                            _isActive ? cs.primary : cs.error,
                                      ),
                                ),
                                Text(
                                  "Trạng thái danh mục trên hệ thống",
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        fontSize: context.sp(12),
                                      ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isActive,
                            onChanged: (val) => setState(() => _isActive = val),
                            activeColor: cs.primary,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: context.rh(16)),

                    Text(
                      "Ngày tạo: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.outline,
                            fontStyle: FontStyle.italic,
                          ),
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
            text: "Lưu danh mục",
            isLoading: categoryVM.isLoading,
            onPressed: _saveCategory,
          ),
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.rh(12), left: context.rw(4)),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: context.sp(12),
              letterSpacing: 0.8,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
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
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: context.sp(14),
              ),
        ),
        SizedBox(height: context.rh(8)),
        Container(
          decoration: _fieldDecoration(context),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            validator: validator,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                  color: cs.onSurfaceVariant, fontWeight: FontWeight.normal),
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
      border: Border.all(color: cs.outline.withOpacity(0.3)),
      boxShadow: [
        BoxShadow(
            color: cs.shadow.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2)),
      ],
    );
  }
}
