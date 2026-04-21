import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:manager/core/extensions/l10n_extension.dart';
import 'package:manager/data/models/product.dart';
import 'package:manager/viewmodels/categories_viewmodel.dart';
import 'package:manager/viewmodels/product_viewmodel.dart';
import 'package:manager/views/widgets/app_button.dart';
import 'package:manager/views/widgets/app_sliver_app_bar.dart';
import 'package:manager/views/widgets/app_snackbar.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';

class ProductFormScreen extends StatefulWidget {
  ProductFormScreen({super.key, this.product});

  Product? product;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // ── Thông tin cơ bản ──────────────────────────────────────────
  final _nameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _skuController = TextEditingController();

  // ── Thông số kỹ thuật ─────────────────────────────────────────
  final _specificationsController = TextEditingController();
  final _thicknessController = TextEditingController();
  final _weightController = TextEditingController();

  // ── Đơn vị & Tồn kho ─────────────────────────────────────────
  final _unitController = TextEditingController(text: 'Cái');
  final _packagingUnitController = TextEditingController();
  final _billableUnitController = TextEditingController();
  final _unitsPerPackController = TextEditingController();
  final _quantityController = TextEditingController(text: '0');

  // ── Giá cả ────────────────────────────────────────────────────
  final _purchasePriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();

  // ── Mô tả ─────────────────────────────────────────────────────
  final _descriptionController = TextEditingController();

  String? _selectedCategoryName;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context
          .read<CategoriesViewModel>()
          .fetchCategories(); // await ở đây
      if (_isEditing && mounted) {
        final categories = context.read<CategoriesViewModel>().categories;
        final match = categories.firstWhereOrNull(
          (c) => c.name == widget.product!.category,
        );
        if (match != null) {
          setState(() => _selectedCategoryName = match.name);
        }
      }
    });

    if (_isEditing) {
      final p = widget.product!;
      _nameController.text = p.name;
      _displayNameController.text = p.displayName ?? '';
      _skuController.text = p.sku ?? '';
      _specificationsController.text = p.specifications ?? '';
      _thicknessController.text = p.thickness ?? '';
      _weightController.text = p.weight != 0 ? p.weight.toString() : '';
      _unitController.text = p.unit.isNotEmpty ? p.unit : 'Cái';
      _packagingUnitController.text = p.packagingUnit ?? '';
      _billableUnitController.text = p.billableUnit ?? '';
      _unitsPerPackController.text =
          p.unitsPerPack != 0 ? p.unitsPerPack.toString() : '';
      _purchasePriceController.text =
          p.purchasePrice != 0 ? p.purchasePrice.toString() : '';
      _sellingPriceController.text =
          p.sellingPrice != 0 ? p.sellingPrice.toString() : '';
      _descriptionController.text = p.description ?? '';
      // _selectedCategoryName = p.category;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _displayNameController.dispose();
    _skuController.dispose();
    _specificationsController.dispose();
    _thicknessController.dispose();
    _weightController.dispose();
    _unitController.dispose();
    _packagingUnitController.dispose();
    _billableUnitController.dispose();
    _unitsPerPackController.dispose();
    _quantityController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      final productVM = context.read<ProductViewModel>();

      final product = Product(
        id: _isEditing ? widget.product!.id : 0,
        name: _nameController.text.trim(),
        displayName: _displayNameController.text.trim(),
        category: _selectedCategoryName,
        sku: _skuController.text.trim(),
        specifications: _specificationsController.text.trim(),
        thickness: _thicknessController.text.trim(),
        weight: double.tryParse(_weightController.text) ?? 0.0,
        unit: _unitController.text.trim(),
        packagingUnit: _packagingUnitController.text.trim(),
        billableUnit: _billableUnitController.text.trim(),
        unitsPerPack: int.tryParse(_unitsPerPackController.text) ?? 0,
        purchasePrice: double.tryParse(_purchasePriceController.text) ?? 0.0,
        sellingPrice: double.tryParse(_sellingPriceController.text) ?? 0.0,
        description: _descriptionController.text.trim(),
        status: 'Active',
      );

      final success = _isEditing
          ? await productVM.updateProduct(widget.product!.id, product)
          : await productVM.createProduct(product);

      if (mounted) {
        if (success) {
          AppSnackbar.showSuccess(
            context,
            _isEditing
                ? context.l10n.action_success(context.l10n.common_edit,
                    context.l10n.product.toLowerCase())
                : context.l10n.action_success(context.l10n.common_add,
                    context.l10n.product.toLowerCase()),
          );
          context.pop();
        } else {
          AppSnackbar.showError(
            context,
            _isEditing
                ? context.l10n.action_failed(context.l10n.common_edit,
                    context.l10n.product.toLowerCase())
                : context.l10n.action_failed(context.l10n.common_add,
                    context.l10n.product.toLowerCase()),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final categoriesVM = context.watch<CategoriesViewModel>();
    final productVM = context.watch<ProductViewModel>();

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      body: CustomScrollView(
        slivers: [
          AppSliverAppBar(
            title: _isEditing
                ? context.l10n.product_edit
                : context.l10n.product_add,
            showBackButton: true,
            height: 80,
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
            sliver: SliverToBoxAdapter(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── THÔNG TIN CƠ BẢN ──────────────────────
                    _buildSectionTitle(context, "Thông tin cơ bản"),
                    _buildTextField(
                      context,
                      controller: _nameController,
                      label: 'Tên sản phẩm *',
                      hint: 'Ví dụ: Bóng đèn LED 20W',
                      icon: Icons.inventory_2_rounded,
                      validator: (v) =>
                          v!.isEmpty ? 'Không được để trống' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      context,
                      controller: _displayNameController,
                      label: 'Tên hiển thị',
                      hint: 'Ví dụ: Đèn LED chiếu sáng',
                      icon: Icons.label_rounded,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            context,
                            controller: _skuController,
                            label: 'Mã hiệu (SKU)',
                            hint: 'LED-20W',
                            icon: Icons.qr_code_rounded,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildCategoryDropdown(categoriesVM, cs),
                        ),
                      ],
                    ),

                    // ── THÔNG SỐ KỸ THUẬT ─────────────────────
                    const SizedBox(height: 24),
                    _buildSectionTitle(context, "Thông số kỹ thuật"),
                    _buildTextField(
                      context,
                      controller: _specificationsController,
                      label: 'Thông số',
                      hint: 'Ví dụ: 220V, ánh sáng trắng',
                      icon: Icons.tune_rounded,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            context,
                            controller: _thicknessController,
                            label: 'Độ dày',
                            hint: '10mm',
                            icon: Icons.line_weight_rounded,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            context,
                            controller: _weightController,
                            label: 'Trọng lượng (kg)',
                            hint: '0.3',
                            icon: Icons.monitor_weight_rounded,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),

                    // ── ĐƠN VỊ & TỒN KHO ──────────────────────
                    const SizedBox(height: 24),
                    _buildSectionTitle(context, "Đơn vị & Tồn kho"),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            context,
                            controller: _unitController,
                            label: 'Đơn vị tính *',
                            hint: 'Cái, Mét, Tấm...',
                            icon: Icons.straighten_rounded,
                            validator: (v) =>
                                v!.isEmpty ? 'Không được để trống' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            context,
                            controller: _billableUnitController,
                            label: 'Đơn vị tính hoá đơn',
                            hint: 'Cái',
                            icon: Icons.receipt_long_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            context,
                            controller: _packagingUnitController,
                            label: 'Đơn vị đóng gói',
                            hint: 'Hộp, Thùng...',
                            icon: Icons.move_to_inbox_rounded,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            context,
                            controller: _unitsPerPackController,
                            label: 'Số lượng / gói',
                            hint: '10',
                            icon: Icons.storage_rounded,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      context,
                      controller: _quantityController,
                      label: 'Số lượng tồn kho',
                      hint: '0',
                      icon: Icons.warehouse_rounded,
                      keyboardType: TextInputType.number,
                    ),

                    // ── GIÁ CẢ ────────────────────────────────
                    const SizedBox(height: 24),
                    _buildSectionTitle(context, "Giá cả (VNĐ)"),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            context,
                            controller: _purchasePriceController,
                            label: 'Giá nhập',
                            hint: '0',
                            icon: Icons.download_rounded,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            context,
                            controller: _sellingPriceController,
                            label: 'Giá bán *',
                            hint: '0',
                            icon: Icons.upload_rounded,
                            keyboardType: TextInputType.number,
                            validator: (v) =>
                                v!.isEmpty ? 'Không được để trống' : null,
                          ),
                        ),
                      ],
                    ),

                    // ── MÔ TẢ ─────────────────────────────────
                    const SizedBox(height: 16),
                    _buildTextField(
                      context,
                      controller: _descriptionController,
                      label: 'Ghi chú / Mô tả',
                      hint: 'Nhập thông tin thêm...',
                      icon: Icons.notes_rounded,
                      maxLines: 3,
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
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
          child: AppButton(
            text: context.l10n.product_save,
            isLoading: productVM.isLoading,
            onPressed: _saveProduct,
          ),
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────

  Widget _buildSectionTitle(BuildContext context, String title) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown(CategoriesViewModel vm, ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Danh mục",
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: _fieldDecoration(context),
          child: DropdownButtonFormField<String>(
            value: _selectedCategoryName,
            isExpanded: true,
            decoration: const InputDecoration(border: InputBorder.none),
            hint: Text(
              'Chọn danh mục',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            items: vm.categories
                .map((c) => DropdownMenuItem(
                      value: c.name,
                      child: Text(c.name),
                    ))
                .toList(),
            onChanged: (val) => setState(() => _selectedCategoryName = val),
            icon: Icon(Icons.arrow_drop_down, color: cs.onSurfaceVariant),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: _fieldDecoration(context),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            validator: validator,
            style: textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
              prefixIcon: Icon(
                icon,
                color: cs.primary,
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
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
      border: Border.all(
        color: cs.outline.withOpacity(0.6),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: cs.shadow.withOpacity(0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}
