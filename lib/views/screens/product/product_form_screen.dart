import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart'; // Thêm import
import 'package:manager/core/extensions/l10n_extension.dart';
import 'package:manager/core/utils/app_responsive.dart';
import 'package:manager/data/models/product.dart';
import 'package:manager/viewmodels/categories_viewmodel.dart';
import 'package:manager/viewmodels/product_viewmodel.dart';
import 'package:manager/views/widgets/app_button.dart';
import 'package:manager/views/widgets/app_sliver_app_bar.dart';
import 'package:manager/views/widgets/app_snackbar.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product;

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _skuController = TextEditingController();
  final _specificationsController = TextEditingController();
  final _thicknessController = TextEditingController();
  final _weightController = TextEditingController();
  final _unitController = TextEditingController(text: 'Cái');
  final _packagingUnitController = TextEditingController();
  final _billableUnitController = TextEditingController();
  final _unitsPerPackController = TextEditingController();
  final _quantityController = TextEditingController(text: '0');
  final _purchasePriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedCategoryName;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  bool _isPageReady = false;
  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));

    _initPageData();
  }

  Future<void> _initPageData() async {
    await Future.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;

    await context.read<CategoriesViewModel>().fetchCategories();

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
      _unitsPerPackController.text = p.unitsPerPack != 0 ? p.unitsPerPack.toString() : '';
      _purchasePriceController.text = p.purchasePrice != 0 ? p.purchasePrice.toString() : '';
      _sellingPriceController.text = p.sellingPrice != 0 ? p.sellingPrice.toString() : '';
      _descriptionController.text = p.description ?? '';

      final categories = context.read<CategoriesViewModel>().categories;
      final match = categories.firstWhereOrNull((c) => c.name == p.category);
      if (match != null) _selectedCategoryName = match.name;
    }

    setState(() => _isPageReady = true);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
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
          AppSnackbar.showSuccess(context, _isEditing ? 'Cập nhật thành công' : 'Thêm mới thành công');
          context.pop();
        } else {
          AppSnackbar.showError(context, productVM.error ?? 'Lỗi thao tác');
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
      body: !_isPageReady
          ? Center(
        child: LoadingAnimationWidget.dotsTriangle(
          color: cs.tertiary, // Đồng bộ màu tertiary
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
                title: _isEditing ? context.l10n.product_edit : context.l10n.product_add,
                showBackButton: true,
                height: 80,
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(context.rw(16), context.rh(24), context.rw(16), context.rh(120)),
                sliver: SliverToBoxAdapter(
                  child: Form(
                    key: _formKey,
                    child: RepaintBoundary(
                      child: Column(
                        children: [
                          _buildSection(
                            context,
                            title: "Thông tin cơ bản",
                            icon: Icons.inventory_2_rounded,
                            children: [
                              _buildTextField(context, controller: _nameController, label: 'Tên sản phẩm', hint: 'Ví dụ: Bóng đèn LED 20W', icon: Icons.edit_note_rounded, isRequired: true, validator: (v) => v!.isEmpty ? 'Vui lòng nhập tên' : null),
                              SizedBox(height: context.rh(14)),
                              _buildTextField(context, controller: _displayNameController, label: 'Tên hiển thị', hint: 'Ví dụ: Đèn LED chiếu sáng', icon: Icons.label_important_outline_rounded),
                              SizedBox(height: context.rh(14)),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: _buildTextField(context, controller: _skuController, label: 'Mã hiệu (SKU)', hint: 'LED-20W', icon: Icons.qr_code_rounded)),
                                  SizedBox(width: context.rw(12)),
                                  Expanded(child: _buildCategoryDropdown(categoriesVM, cs)),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: context.rh(16)),
                          _buildSection(
                            context,
                            title: "Thông số kỹ thuật",
                            icon: Icons.settings_suggest_rounded,
                            children: [
                              _buildTextField(context, controller: _specificationsController, label: 'Thông số chi tiết', hint: 'Ví dụ: 220V, ánh sáng trắng', icon: Icons.tune_rounded),
                              SizedBox(height: context.rh(14)),
                              Row(
                                children: [
                                  Expanded(child: _buildTextField(context, controller: _thicknessController, label: 'Độ dày', hint: '10mm', icon: Icons.line_weight_rounded)),
                                  SizedBox(width: context.rw(12)),
                                  Expanded(child: _buildTextField(context, controller: _weightController, label: 'Trọng lượng (kg)', hint: '0.3', icon: Icons.monitor_weight_rounded, keyboardType: TextInputType.number)),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: context.rh(16)),
                          _buildSection(
                            context,
                            title: "Đơn vị & Tồn kho",
                            icon: Icons.garage_rounded,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: _buildTextField(context, controller: _unitController, label: 'Đơn vị tính', hint: 'Cái, Mét...', icon: Icons.straighten_rounded, isRequired: true, validator: (v) => v!.isEmpty ? 'Bắt buộc' : null)),
                                  SizedBox(width: context.rw(12)),
                                  Expanded(child: _buildTextField(context, controller: _billableUnitController, label: 'ĐV Hoá đơn', hint: 'Cái', icon: Icons.receipt_long_rounded)),
                                ],
                              ),
                              SizedBox(height: context.rh(14)),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: _buildTextField(context, controller: _packagingUnitController, label: 'ĐV Đóng gói', hint: 'Thùng...', icon: Icons.all_inbox_rounded)),
                                  SizedBox(width: context.rw(12)),
                                  Expanded(child: _buildTextField(context, controller: _unitsPerPackController, label: 'SL/Gói', hint: '10', icon: Icons.filter_9_plus_rounded, keyboardType: TextInputType.number)),
                                ],
                              ),
                              SizedBox(height: context.rh(14)),
                              _buildTextField(context, controller: _quantityController, label: 'Số lượng tồn kho ban đầu', hint: '0', icon: Icons.warehouse_rounded, keyboardType: TextInputType.number),
                            ],
                          ),
                          SizedBox(height: context.rh(16)),
                          _buildSection(
                            context,
                            title: "Giá cả & Ghi chú",
                            icon: Icons.payments_rounded,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: _buildTextField(context, controller: _purchasePriceController, label: 'Giá nhập (VNĐ)', hint: '0', icon: Icons.shopping_cart_checkout_rounded, keyboardType: TextInputType.number)),
                                  SizedBox(width: context.rw(12)),
                                  Expanded(child: _buildTextField(context, controller: _sellingPriceController, label: 'Giá bán (VNĐ)', hint: '0', icon: Icons.sell_rounded, isRequired: true, keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Bắt buộc' : null)),
                                ],
                              ),
                              SizedBox(height: context.rh(14)),
                              _buildTextField(context, controller: _descriptionController, label: 'Mô tả thêm', hint: 'Nhập thông tin ghi chú...', icon: Icons.description_outlined, maxLines: 3),
                            ],
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
      bottomSheet: _isPageReady ? _buildBottomSave(context, productVM) : null,
    );
  }

  // --- REUSABLE COMPONENTS (Đổi sang tông màu Tertiary) ---

  Widget _buildSection(BuildContext context, {required String title, required IconData icon, required List<Widget> children}) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
        boxShadow: [BoxShadow(color: cs.shadow.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(context.rw(16), context.rh(14), context.rw(16), context.rh(4)),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: cs.tertiaryContainer, borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, size: context.sp(15), color: cs.tertiary),
                ),
                SizedBox(width: context.rw(10)),
                Text(title.toUpperCase(),
                    style: TextStyle(fontSize: context.sp(11), fontWeight: FontWeight.w800, letterSpacing: 0.8, color: cs.tertiary)),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: cs.outlineVariant.withOpacity(0.4)),
          Padding(padding: EdgeInsets.all(context.rw(16)), child: Column(children: children)),
        ],
      ),
    );
  }

  Widget _buildTextField(BuildContext context, {required TextEditingController controller, required String label, required String hint, required IconData icon, TextInputType keyboardType = TextInputType.text, int maxLines = 1, String? Function(String?)? validator, bool isRequired = false}) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: context.sp(13), color: cs.onSurface)),
            if (isRequired) Text(' *', style: TextStyle(color: cs.error, fontSize: context.sp(13))),
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
            hintStyle: TextStyle(color: cs.outline.withOpacity(0.5), fontSize: context.sp(14)),
            prefixIcon: Icon(icon, color: cs.tertiary, size: context.sp(19)),
            filled: true,
            fillColor: cs.surfaceContainerLowest,
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cs.outlineVariant.withOpacity(0.6))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cs.tertiary, width: 1.6)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cs.error)),
            focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cs.error, width: 1.6)),
            contentPadding: EdgeInsets.symmetric(horizontal: context.rw(14), vertical: context.rh(13)),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown(CategoriesViewModel vm, ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Danh mục", style: TextStyle(fontWeight: FontWeight.w600, fontSize: context.sp(13))),
        SizedBox(height: context.rh(7)),
        DropdownButtonFormField<String>(
          value: _selectedCategoryName,
          isExpanded: true,
          style: TextStyle(fontSize: context.sp(14), color: cs.onSurface),
          decoration: InputDecoration(
            filled: true,
            fillColor: cs.surfaceContainerLowest,
            contentPadding: EdgeInsets.symmetric(horizontal: context.rw(14), vertical: context.rh(11)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cs.outlineVariant.withOpacity(0.6))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cs.tertiary, width: 1.6)),
          ),
          hint: Text('Chọn...', style: TextStyle(fontSize: context.sp(14), color: cs.outline.withOpacity(0.5))),
          items: vm.categories.map((c) => DropdownMenuItem(value: c.name, child: Text(c.name))).toList(),
          onChanged: (val) => setState(() => _selectedCategoryName = val),
        ),
      ],
    );
  }

  Widget _buildBottomSave(BuildContext context, ProductViewModel vm) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: cs.outlineVariant.withOpacity(0.3))),
        boxShadow: [BoxShadow(color: cs.shadow.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, -3))],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(context.rw(16), context.rh(12), context.rw(16), context.rh(12)),
          child: AppButton(text: context.l10n.product_save, isLoading: vm.isLoading, onPressed: _saveProduct),
        ),
      ),
    );
  }
}