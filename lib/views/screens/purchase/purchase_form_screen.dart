import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:manager/core/extensions/l10n_extension.dart';
import 'package:manager/core/utils/app_responsive.dart';
import 'package:manager/data/models/payments.dart';
import 'package:manager/data/models/product.dart';
import 'package:manager/data/models/purchase.dart';
import 'package:manager/data/models/purchase_item.dart';
import 'package:manager/data/models/supplier.dart';
import 'package:manager/data/models/warehouse.dart';
import 'package:manager/viewmodels/product_viewmodel.dart';
import 'package:manager/viewmodels/purchase_viewmodel.dart';
import 'package:manager/viewmodels/supplier_viewmodel.dart';
import 'package:manager/viewmodels/warehouse_viewmodel.dart';
import 'package:manager/views/widgets/app_button.dart';
import 'package:manager/views/widgets/app_sliver_app_bar.dart';
import 'package:manager/views/widgets/app_snackbar.dart';
import 'package:provider/provider.dart';

class _LineItem {
  final Product product;
  double qty;
  double unitPrice;

  _LineItem({
    required this.product,
    this.qty = 1,
    required this.unitPrice,
  });

  double get lineTotal => qty * unitPrice;
}

const List<String> _kStatuses = [
  'Nháp',
  'Đã Đặt',
  'Đã Nhận',
  'Đã Thanh Toán',
  'Quá Hạn'
];

// ====================== MAIN SCREEN ======================

class PurchaseFormScreen extends StatefulWidget {
  const PurchaseFormScreen({super.key});

  @override
  State<PurchaseFormScreen> createState() => _PurchaseFormScreenState();
}

class _PurchaseFormScreenState extends State<PurchaseFormScreen>
    with SingleTickerProviderStateMixin {
  // ← thêm mixin
  final _formKey = GlobalKey<FormState>();
  final _currencyFormatter = NumberFormat('#,##0', 'vi_VN');

  // ── Loading / animation ──────────────────────────────
  bool _isPageReady = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // Form State
  DateTime _purchaseDate = DateTime.now();
  String _status = 'Nháp';

  Supplier? _selectedSupplier;
  Warehouse? _selectedWarehouse;

  final List<_LineItem> _lineItems = [];
  double _discount = 0.0;
  double _paymentMade = 0.0;

  // Computed values
  double get _subtotal =>
      _lineItems.fold(0.0, (sum, item) => sum + item.lineTotal);

  double get _total => (_subtotal - _discount).clamp(0.0, double.infinity);

  double get _change => (_paymentMade - _total).clamp(0.0, double.infinity);

  double get _debt => (_total - _paymentMade).clamp(0.0, double.infinity);

  bool get _hasDebt => _paymentMade > 0 && _paymentMade < _total;

  // ── Lifecycle ────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductViewModel>().fetchProducts();
      context.read<SupplierViewmodel>().fetchSuppliers();
      context.read<WarehouseViewModel>().fetchWarehouses();
      context.read<PurchaseViewmodel>().fetchPurchases();
    });

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
    super.dispose();
  }

  // ==================== HANDLERS ====================

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _purchaseDate = picked);
  }

  void _addProduct(Product product) {
    setState(() {
      _lineItems.add(_LineItem(
        product: product,
        unitPrice: product.purchasePrice,
      ));
    });
  }

  void _removeItem(int index) {
    setState(() => _lineItems.removeAt(index));
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_lineItems.isEmpty) {
      AppSnackbar.showInfo(context, 'Vui lòng chọn ít nhất một sản phẩm');
      return;
    }
    if (_selectedSupplier == null) {
      AppSnackbar.showInfo(context, 'Vui lòng chọn nhà cung cấp');
      return;
    }
    if (_selectedWarehouse == null) {
      AppSnackbar.showInfo(context, 'Vui lòng chọn kho hàng');
      return;
    }

    String finalStatus;
    if (_paymentMade >= _total) {
      finalStatus = 'Paid';
    } else if (_paymentMade > 0) {
      finalStatus = 'Ordered';
    } else {
      finalStatus = 'Draft';
    }

    List<Payment> payList = [];
    if (_paymentMade > 0) {
      payList.add(Payment(
        id: 0,
        date: _purchaseDate,
        notes: 'Thanh toán ban đầu',
        isInitial: true,
        amount: _paymentMade,
        method: 'cash',
      ));
    }

    final purchaseItems = _lineItems
        .asMap()
        .entries
        .map((entry) => PurchaseItem(
              id: entry.key + 1,
              productId: entry.value.product.id,
              productName: entry.value.product.name,
              unitPrice: entry.value.unitPrice,
              qty: entry.value.qty,
              unit: entry.value.product.unit,
              billableQty: entry.value.qty,
              unitCost: entry.value.unitPrice,
              lineTotal: entry.value.lineTotal,
            ))
        .toList();

    final purchaseVM = context.read<PurchaseViewmodel>();
    final newPurchase = Purchase(
      id: 0,
      purchaseNumber: 'PO-00000${purchaseVM.purchases.length + 1}',
      supplierId: _selectedSupplier!.id ?? 0,
      supplierName: _selectedSupplier!.name,
      warehouseId: _selectedWarehouse!.id,
      warehouseName: _selectedWarehouse!.name,
      date: _purchaseDate,
      subtotal: _subtotal,
      discount: _discount,
      total: _total,
      amount: _total,
      paymentMade: _paymentMade,
      balanceDue: _debt,
      status: finalStatus,
      createdAt: DateTime.now(),
      payments: payList,
      items: purchaseItems,
    );

    final success = await purchaseVM.createPurchase(newPurchase);

    if (success) {
      AppSnackbar.showSuccess(
        context,
        context.l10n.action_success(context.l10n.common_add, 'đơn nhập hàng'),
      );
      Navigator.pop(context);
    } else {
      AppSnackbar.showError(
        context,
        context.l10n.action_failed(context.l10n.common_add, 'đơn nhập hàng'),
      );
    }
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final productVM = context.watch<ProductViewModel>();
    final supplierVM = context.watch<SupplierViewmodel>();
    final warehouseVM = context.watch<WarehouseViewModel>();
    final purchaseVM = context.watch<PurchaseViewmodel>();

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      // ── bottomSheet chỉ hiện khi trang đã sẵn sàng ──
      bottomSheet: _isPageReady
          ? Container(
              decoration: BoxDecoration(
                color: cs.surface,
                border: Border(
                    top: BorderSide(color: cs.outlineVariant.withOpacity(0.3))),
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
                  padding: EdgeInsets.fromLTRB(context.rw(16), context.rh(12),
                      context.rw(16), context.rh(12)),
                  child: AppButton(
                    text: 'Lưu Đơn Nhập',
                    isLoading: purchaseVM.isLoading,
                    onPressed: _submitForm,
                  ),
                ),
              ),
            )
          : null,
      body: !_isPageReady
          // ── Loading state ─────────────────────────────────
          ? Center(
              child: LoadingAnimationWidget.dotsTriangle(
                color: cs.primary,
                size: context.rw(32),
              ),
            )
          // ── Content với fade + slide ──────────────────────
          : FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Form(
                  key: _formKey,
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      AppSliverAppBar(
                        title: 'Tạo Đơn Nhập Hàng',
                        showBackButton: true,
                        height: 80,
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(0, 8, 0, 140),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            _buildPurchaseInfoCard(cs, purchaseVM.purchases),
                            _buildSectionLabel('Nhà Cung Cấp & Kho Hàng'),
                            _buildSupplierWarehouseSection(cs,
                                supplierVM.suppliers, warehouseVM.warehouses),
                            _buildSectionLabel('Sản Phẩm'),
                            _buildProductsSection(cs, productVM.products),
                            _buildSectionLabel('Tổng Kết'),
                            _buildSummarySection(cs),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // ==================== SECTIONS ====================

  Widget _buildPurchaseInfoCard(ColorScheme cs, List<Purchase> purchases) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LabeledField(
            label: 'Số Đơn Nhập',
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                  horizontal: context.rw(12), vertical: context.rh(12)),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withOpacity(0.6),
                border: Border.all(color: cs.outlineVariant),
                borderRadius: BorderRadius.circular(context.rr(10)),
              ),
              child: Text(
                'PO-00000${purchases.length + 1}',
                style: TextStyle(
                  fontSize: context.sp(14),
                  fontWeight: FontWeight.w500,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          ),
          SizedBox(height: context.rh(16)),
          Row(
            children: [
              Expanded(
                child: _LabeledField(
                  label: 'Ngày',
                  child: _TappableField(
                    value: DateFormat('dd/MM/yyyy').format(_purchaseDate),
                    icon: Icons.calendar_today_rounded,
                    onTap: _selectDate,
                    cs: cs,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _LabeledField(
                  label: 'Trạng Thái',
                  child: _StyledDropdown<String>(
                    value: _status,
                    items: _kStatuses,
                    onChanged: (v) => setState(() => _status = v ?? 'Nháp'),
                    cs: cs,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSupplierWarehouseSection(
      ColorScheme cs, List<Supplier> suppliers, List<Warehouse> warehouses) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Nhà Cung Cấp',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              TextButton(
                onPressed: () {
                  // TODO: Navigate to add supplier
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Thêm mới',
                  style: TextStyle(
                      color: cs.primary,
                      fontSize: context.sp(12),
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          SizedBox(height: context.rh(8)),
          _StyledDropdown<Supplier?>(
            value: _selectedSupplier,
            items: [null, ...suppliers],
            hint: 'Chọn nhà cung cấp',
            labelBuilder: (s) => s?.name ?? 'Chọn nhà cung cấp',
            onChanged: (s) => setState(() => _selectedSupplier = s),
            cs: cs,
          ),
          SizedBox(height: context.rh(20)),
          const Text('Kho Hàng Nhập',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          SizedBox(height: context.rh(8)),
          _StyledDropdown<Warehouse?>(
            value: _selectedWarehouse,
            items: [null, ...warehouses],
            hint: 'Chọn kho hàng',
            labelBuilder: (w) => w?.name ?? 'Chọn kho hàng',
            onChanged: (w) => setState(() => _selectedWarehouse = w),
            cs: cs,
          ),
          if (_selectedSupplier == null || _selectedWarehouse == null)
            Padding(
              padding: EdgeInsets.only(top: context.rh(8)),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 13, color: cs.outline),
                  SizedBox(width: context.rw(4)),
                  Text(
                    'Bắt buộc phải chọn nhà cung cấp và kho hàng',
                    style: TextStyle(
                        fontSize: context.sp(11.5), color: cs.outline),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductsSection(ColorScheme cs, List<Product> products) {
    final alreadyAddedIds = _lineItems.map((e) => e.product.id).toSet();

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _lineItems.isEmpty
                      ? 'Chưa có sản phẩm'
                      : '${_lineItems.length} sản phẩm',
                  style: TextStyle(
                      color: cs.onSurfaceVariant, fontSize: context.sp(13)),
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: () => _showProductPicker(products, alreadyAddedIds),
                icon: Icon(Icons.add_rounded, size: context.sp(18)),
                label: const Text('Thêm Sản Phẩm'),
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                      horizontal: context.rw(14), vertical: context.rh(8)),
                  textStyle: TextStyle(
                      fontSize: context.sp(13), fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_lineItems.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    Icon(Icons.inventory_2_outlined,
                        size: 48, color: cs.outlineVariant),
                    const SizedBox(height: 8),
                    Text(
                      'Nhấn "Thêm Sản Phẩm" để bắt đầu',
                      style:
                          TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Expanded(
                    flex: 4,
                    child: Text('Sản Phẩm',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5)),
                  ),
                  const Expanded(
                    flex: 3,
                    child: Text('SL / Đơn Giá',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Thành Tiền',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: cs.primary),
                    ),
                  ),
                  const SizedBox(width: 32),
                ],
              ),
            ),
            const SizedBox(height: 4),
            ..._lineItems.asMap().entries.map((entry) {
              return _LineItemRow(
                key: ValueKey(entry.value.product.id),
                item: entry.value,
                currency: _currencyFormatter,
                cs: cs,
                onQtyChanged: (qty) => setState(() => entry.value.qty = qty),
                onPriceChanged: (price) =>
                    setState(() => entry.value.unitPrice = price),
                onDelete: () => _removeItem(entry.key),
              );
            }),
          ],
        ],
      ),
    );
  }

  void _showProductPicker(List<Product> products, Set<int> alreadyAdded) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProductPickerSheet(
        products: products,
        alreadyAdded: alreadyAdded,
        onProductSelected: _addProduct,
      ),
    );
  }

  Widget _buildSummarySection(ColorScheme cs) {
    final isDebtState = _hasDebt;
    final changeOrDebt = isDebtState ? _debt : _change;

    return _Card(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _LabeledField(
                  label: 'Giảm Giá (VNĐ)',
                  child: _StyledTextFormField(
                    hint: '0',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (v) =>
                        setState(() => _discount = double.tryParse(v) ?? 0),
                    cs: cs,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _LabeledField(
                  label: 'Đã Thanh Toán (VNĐ)',
                  child: _StyledTextFormField(
                    hint: '0',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (v) =>
                        setState(() => _paymentMade = double.tryParse(v) ?? 0),
                    cs: cs,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: context.rh(20)),
          Container(
            padding: EdgeInsets.all(context.rw(16)),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withOpacity(0.4),
              borderRadius: BorderRadius.circular(context.rr(16)),
            ),
            child: Column(
              children: [
                _SummaryRow(
                  label: 'Tạm tính',
                  value: '${_currencyFormatter.format(_subtotal)} đ',
                  cs: cs,
                ),
                const Divider(height: 20),
                _SummaryRow(
                  label: 'Giảm giá',
                  value: '- ${_currencyFormatter.format(_discount)} đ',
                  valueColor: cs.error,
                  cs: cs,
                ),
                const Divider(height: 20),
                _SummaryRow(
                  label: 'Tổng cộng',
                  value: '${_currencyFormatter.format(_total)} đ',
                  isBold: true,
                  cs: cs,
                ),
                const Divider(height: 20),
                _SummaryRow(
                  label: 'Đã thanh toán',
                  value: '${_currencyFormatter.format(_paymentMade)} đ',
                  valueColor: Colors.green,
                  cs: cs,
                ),
                const SizedBox(height: 12),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDebtState
                        ? cs.errorContainer.withOpacity(0.45)
                        : Colors.green.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isDebtState
                                ? Icons.arrow_downward_rounded
                                : Icons.arrow_upward_rounded,
                            size: 16,
                            color:
                                isDebtState ? cs.error : Colors.green.shade700,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isDebtState ? 'Còn nợ' : 'Trả dư',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: isDebtState
                                  ? cs.error
                                  : Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${_currencyFormatter.format(changeOrDebt)} đ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDebtState ? cs.error : Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String title) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          context.rw(20), context.rh(16), context.rw(16), context.rh(8)),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
              fontSize: context.sp(11),
              color: Theme.of(context).colorScheme.outline,
            ),
      ),
    );
  }
}

// ====================== LINE ITEM ROW ======================

class _LineItemRow extends StatefulWidget {
  const _LineItemRow({
    super.key,
    required this.item,
    required this.currency,
    required this.cs,
    required this.onQtyChanged,
    required this.onPriceChanged,
    required this.onDelete,
  });

  final _LineItem item;
  final NumberFormat currency;
  final ColorScheme cs;
  final ValueChanged<double> onQtyChanged;
  final ValueChanged<double> onPriceChanged;
  final VoidCallback onDelete;

  @override
  State<_LineItemRow> createState() => _LineItemRowState();
}

class _LineItemRowState extends State<_LineItemRow> {
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _priceCtrl;

  @override
  void initState() {
    super.initState();
    _qtyCtrl = TextEditingController(text: widget.item.qty.toStringAsFixed(0));
    _priceCtrl =
        TextEditingController(text: widget.item.unitPrice.toStringAsFixed(0));
  }

  @override
  void didUpdateWidget(covariant _LineItemRow old) {
    super.didUpdateWidget(old);
    if (widget.item.qty != (double.tryParse(_qtyCtrl.text) ?? 0)) {
      _qtyCtrl.text = widget.item.qty.toStringAsFixed(0);
    }
    if (widget.item.unitPrice != (double.tryParse(_priceCtrl.text) ?? 0)) {
      _priceCtrl.text = widget.item.unitPrice.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final cs = widget.cs;

    return Container(
      margin: EdgeInsets.only(bottom: context.rh(8)),
      padding: EdgeInsets.all(context.rw(12)),
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
        borderRadius: BorderRadius.circular(context.rr(12)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: context.sp(13.5)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.product.category != null)
                  Text(
                    item.product.category!,
                    style: TextStyle(
                        fontSize: context.sp(11.5), color: cs.outline),
                  ),
              ],
            ),
          ),
          SizedBox(width: context.rw(12)),
          Expanded(
            flex: 3,
            child: Column(
              children: [
                _MiniNumberField(
                  controller: _qtyCtrl,
                  hint: 'SL',
                  suffix: item.product.unit,
                  cs: cs,
                  onChanged: (v) =>
                      widget.onQtyChanged(double.tryParse(v) ?? 1),
                ),
                SizedBox(height: context.rh(6)),
                _MiniNumberField(
                  controller: _priceCtrl,
                  hint: 'Đơn giá',
                  suffix: 'đ',
                  cs: cs,
                  onChanged: (v) =>
                      widget.onPriceChanged(double.tryParse(v) ?? 0),
                ),
              ],
            ),
          ),
          SizedBox(width: context.rw(12)),
          Expanded(
            flex: 2,
            child: Text(
              '${widget.currency.format(item.lineTotal)} đ',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: cs.primary,
                fontSize: context.sp(13.5),
              ),
            ),
          ),
          IconButton(
            onPressed: widget.onDelete,
            icon: Icon(Icons.close_rounded,
                color: cs.error, size: context.sp(20)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

// ====================== PRODUCT PICKER ======================

class _ProductPickerSheet extends StatefulWidget {
  const _ProductPickerSheet({
    super.key,
    required this.products,
    required this.alreadyAdded,
    required this.onProductSelected,
  });

  final List<Product> products;
  final Set<int> alreadyAdded;
  final ValueChanged<Product> onProductSelected;

  @override
  State<_ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends State<_ProductPickerSheet> {
  String _searchText = '';
  String _selectedCategory = 'Tất cả';

  List<String> get _categories => [
        'Tất cả',
        ...widget.products
            .map((p) => p.category ?? '')
            .where((c) => c.isNotEmpty)
            .toSet()
            .toList()
          ..sort(),
      ];

  List<Product> get _filteredProducts => widget.products.where((p) {
        final matchCat =
            _selectedCategory == 'Tất cả' || p.category == _selectedCategory;
        final matchSearch = _searchText.isEmpty ||
            p.name.toLowerCase().contains(_searchText.toLowerCase());
        return matchCat && matchSearch;
      }).toList();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final currency = NumberFormat('#,##0', 'vi_VN');

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.symmetric(vertical: context.rh(12)),
              width: context.rw(40),
              height: context.rh(4),
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(context.rr(2)),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                  context.rw(16), 0, context.rw(16), context.rh(8)),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Chọn Sản Phẩm',
                        style: TextStyle(
                            fontSize: context.sp(18),
                            fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Tìm sản phẩm...',
                  prefixIcon: Icon(Icons.search_rounded, size: context.sp(20)),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(context.rr(12))),
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: context.rw(12), vertical: context.rh(10)),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _searchText = v),
              ),
            ),
            SizedBox(height: context.rh(12)),
            SizedBox(
              height: context.rh(38),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: context.rw(16)),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => SizedBox(width: context.rw(8)),
                itemBuilder: (_, i) {
                  final cat = _categories[i];
                  return ChoiceChip(
                    label:
                        Text(cat, style: TextStyle(fontSize: context.sp(12))),
                    selected: _selectedCategory == cat,
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                },
              ),
            ),
            SizedBox(height: context.rh(8)),
            const Divider(height: 1),
            Expanded(
              child: _filteredProducts.isEmpty
                  ? Center(
                      child: Text('Không tìm thấy sản phẩm',
                          style: TextStyle(color: cs.onSurfaceVariant)),
                    )
                  : ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      itemCount: _filteredProducts.length,
                      separatorBuilder: (_, __) => Divider(
                          height: 1, color: cs.outlineVariant.withOpacity(0.4)),
                      itemBuilder: (_, i) {
                        final product = _filteredProducts[i];
                        final isAdded =
                            widget.alreadyAdded.contains(product.id);

                        return ListTile(
                          dense: true,
                          title: Text(
                            product.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: context.sp(13),
                              color: isAdded ? cs.outline : cs.onSurface,
                            ),
                          ),
                          subtitle: Text(
                            '${product.category ?? 'Chưa phân loại'} · ${product.unit}',
                            style: TextStyle(
                                fontSize: context.sp(11.5), color: cs.outline),
                          ),
                          trailing: isAdded
                              ? Chip(
                                  label: Text('Đã thêm',
                                      style:
                                          TextStyle(fontSize: context.sp(11))),
                                  padding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${currency.format(product.purchasePrice)} đ',
                                      style: TextStyle(
                                        fontSize: context.sp(13),
                                        fontWeight: FontWeight.bold,
                                        color: cs.primary,
                                      ),
                                    ),
                                    SizedBox(height: context.rh(2)),
                                    Icon(Icons.add_circle_rounded,
                                        size: context.sp(20),
                                        color: Colors.green),
                                  ],
                                ),
                          onTap: isAdded
                              ? null
                              : () {
                                  widget.onProductSelected(product);
                                  Navigator.pop(context);
                                },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ====================== REUSABLE COMPONENTS ======================

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _StyledTextFormField extends StatelessWidget {
  const _StyledTextFormField({
    this.controller,
    required this.hint,
    required this.cs,
    this.validator,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
  });

  final TextEditingController? controller;
  final String hint;
  final ColorScheme cs;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: cs.outlineVariant, fontSize: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cs.primary, width: 1.6),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
      ),
    );
  }
}

class _StyledDropdown<T> extends StatelessWidget {
  const _StyledDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
    required this.cs,
    this.labelBuilder,
    this.hint,
  });

  final T value;
  final List<T> items;
  final String Function(T)? labelBuilder;
  final ValueChanged<T?> onChanged;
  final ColorScheme cs;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      hint: hint != null
          ? Text(hint!,
              style: TextStyle(color: cs.outlineVariant, fontSize: 13))
          : null,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cs.primary, width: 1.6),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
      ),
      style: const TextStyle(fontSize: 13, color: Colors.black87),
      items: items
          .map((e) => DropdownMenuItem<T>(
                value: e,
                child: Text(
                  labelBuilder?.call(e) ?? e.toString(),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: const TextStyle(fontSize: 13),
                ),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _TappableField extends StatelessWidget {
  const _TappableField({
    required this.value,
    required this.icon,
    required this.onTap,
    required this.cs,
  });

  final String value;
  final IconData icon;
  final VoidCallback onTap;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: cs.outlineVariant),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
            Icon(icon, size: 18, color: cs.outline),
          ],
        ),
      ),
    );
  }
}

class _MiniNumberField extends StatelessWidget {
  const _MiniNumberField({
    required this.controller,
    required this.hint,
    required this.suffix,
    required this.cs,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final String suffix;
  final ColorScheme cs;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: onChanged,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        suffixText: suffix,
        suffixStyle: TextStyle(fontSize: 12, color: cs.outline),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: cs.primary),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        isDense: true,
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    required this.cs,
    this.isBold = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final ColorScheme cs;
  final bool isBold;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 15 : 13.5,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 16 : 13.5,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
