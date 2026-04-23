import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart'; // Thêm import
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

class _CategoriesFormScreenState extends State<CategoriesFormScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isActive = true;
  bool _isPageReady = false;

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

    _preparePage();
  }

  Future<void> _preparePage() async {
    // Đợi transition hoàn tất tương tự các màn hình khác
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
          AppSnackbar.showError(context, categoryVM.error ?? 'Lỗi');
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
                title: context.l10n.category_add,
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
                    child: RepaintBoundary(
                      child: Column(
                        children: [
                          // --- THÔNG TIN DANH MỤC ---
                          _buildSection(
                            context,
                            title: "Thông tin danh mục",
                            icon: Icons.category_rounded,
                            children: [
                              _buildTextField(
                                context,
                                controller: _nameController,
                                label: 'Tên danh mục',
                                hint: 'Ví dụ: Thiết bị văn phòng',
                                icon: Icons.edit_note_rounded,
                                isRequired: true,
                                validator: (v) => v!.isEmpty
                                    ? 'Tên không được để trống'
                                    : null,
                              ),
                              SizedBox(height: context.rh(14)),
                              _buildTextField(
                                context,
                                controller: _descriptionController,
                                label: 'Mô tả',
                                hint: 'Nhập mô tả danh mục...',
                                icon: Icons.description_rounded,
                                maxLines: 3,
                              ),
                            ],
                          ),
                          SizedBox(height: context.rh(16)),

                          // --- TRẠNG THÁI ---
                          _buildSection(
                            context,
                            title: "Trạng thái hiển thị",
                            icon: Icons.settings_power_rounded,
                            children: [_buildStatusToggle(context)],
                          ),

                          SizedBox(height: context.rh(24)),
                          Center(
                            child: Text(
                              "Ngày tạo: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                color: cs.outline,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
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
      bottomSheet: _isPageReady ? _buildBottomSave(context, categoryVM) : null,
    );
  }

  // --- REUSABLE COMPONENTS (Tertiary Theme) ---

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
              offset: const Offset(0, 2)),
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

  Widget _buildTextField(BuildContext context,
      {required TextEditingController controller,
        required String label,
        required String hint,
        required IconData icon,
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
              borderSide: BorderSide(color: cs.outlineVariant.withOpacity(0.6)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: cs.tertiary, width: 1.6),
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
              : cs.error.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isActive ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: _isActive ? Colors.green : cs.error,
            size: context.sp(22),
          ),
          SizedBox(width: context.rw(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isActive ? "Đang hoạt động" : "Ngừng hoạt động",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: context.sp(14),
                    color: _isActive ? Colors.green.shade700 : cs.error,
                  ),
                ),
                Text(
                  _isActive
                      ? "Hiển thị danh mục trong hệ thống"
                      : "Ẩn danh mục này khỏi danh sách",
                  style: TextStyle(fontSize: context.sp(11), color: cs.outline),
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

  Widget _buildBottomSave(BuildContext context, CategoriesViewModel vm) {
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
              offset: const Offset(0, -3)),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              context.rw(16), context.rh(12), context.rw(16), context.rh(12)),
          child: AppButton(
            text: "Lưu danh mục",
            isLoading: vm.isLoading,
            onPressed: _saveCategory,
          ),
        ),
      ),
    );
  }
}