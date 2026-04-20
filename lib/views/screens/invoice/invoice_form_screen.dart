import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:manager/data/models/customer.dart';
import 'package:manager/data/models/invoice.dart';
import 'package:manager/data/models/invoice_item.dart';
import 'package:manager/data/models/payments.dart';
import 'package:manager/data/models/product.dart';
import 'package:manager/viewmodels/customer_viewmodel.dart';
import 'package:manager/viewmodels/invoice_viewmodel.dart';
import 'package:manager/viewmodels/product_viewmodel.dart';
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

const List<String> _kStatuses = ['Nhập', 'Đã Gửi', 'Đã Thanh Toán', 'Quá Hạn'];

// ====================== MAIN SCREEN ======================
class InvoiceFormScreen extends StatefulWidget {
  const InvoiceFormScreen({super.key});

  @override
  State<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
}

class _InvoiceFormScreenState extends State<InvoiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currencyFormatter = NumberFormat('#,##0', 'vi_VN');

  // Form State
  DateTime _invoiceDate = DateTime.now();
  String _status = 'Nhập';

  Customer? _selectedCustomer;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  final List<_LineItem> _lineItems = [];
  double _discount = 0.0;
  double _cashReceived = 0.0;

  // Computed values
  double get _subtotal =>
      _lineItems.fold(0.0, (sum, item) => sum + item.lineTotal);

  double get _total => (_subtotal - _discount).clamp(0.0, double.infinity);

  double get _change => (_cashReceived - _total).clamp(0.0, double.infinity);

  double get _debt => (_total - _cashReceived).clamp(0.0, double.infinity);

  bool get _hasDebt => _cashReceived > 0 && _cashReceived < _total;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductViewModel>().fetchProducts();
      context.read<CustomerViewmodel>().fetchCustomers();
      context.read<InvoiceViewmodel>().fetchInvoices();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // ==================== HANDLERS ====================

  void _onCustomerSelected(Customer? customer) {
    if (customer == null) return;
    setState(() {
      _selectedCustomer = customer;
      _nameController.text = customer.name;
      _phoneController.text = customer.phone ?? '';
      _addressController.text = customer.address ?? '';
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _invoiceDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _invoiceDate = picked);
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
      AppSnackbar.showInfo(context, "Vui lòng chọn ít nhất một sản phẩm");
      return;
    }

    if (_selectedCustomer == null && _nameController.text.trim().isEmpty) {
      AppSnackbar.showInfo(context, "Vui lòng chọn thông tin khách hàng");
      return;
    }

    // ==================== XỬ LÝ STATUS THEO ENUM BACKEND ====================
    String finalStatus;

    if (_cashReceived >= _total) {
      finalStatus = 'Paid'; // Đã thanh toán đủ
    } else if (_cashReceived > 0) {
      finalStatus = 'Sent'; // Đã gửi (có thanh toán một phần)
    } else {
      finalStatus = 'Draft'; // Chỉ nhập, chưa gửi
    }

    // Nếu muốn hỗ trợ Overdue, có thể kiểm tra ngày hết hạn sau

    // ==================== TẠO PAYMENTS ====================
    List<Payment> payList = [];
    if (_cashReceived > 0) {
      payList.add(Payment(
        id: 0,
        date: _invoiceDate,
        notes: 'Thanh toán ban đầu',
        isInitial: true,
        amount: _cashReceived,
        method: 'cash',
      ));
    }

    // ==================== TẠO INVOICE ITEMS ====================
    final invoiceItems = _lineItems
        .map((item) => InvoiceItem(
              productId: item.product.id,
              productName: item.product.name,
              unitPrice: item.unitPrice,
              qty: item.qty,
              unit: item.product.unit ?? '',
              lineTotal: item.lineTotal,
            ))
        .toList();

    // ==================== TẠO INVOICE ====================
    final newInvoice = Invoice(
      id: 0,
      invoiceNumber:
          'INV0-00000${context.read<InvoiceViewmodel>().invoices.length + 1}',
      customerName: _nameController.text.trim(),
      customerId: _selectedCustomer?.id ?? 0,
      customerAddress: _addressController.text.trim(),
      customerPhone: _phoneController.text.trim(),
      date: _invoiceDate,
      subtotal: _subtotal,
      discount: _discount,
      total: _total,
      amount: _total,
      paymentReceived: _cashReceived,
      balanceDue: _debt,
      status: finalStatus,
      payments: payList,
      items: invoiceItems,
    );

    final success =
        await context.read<InvoiceViewmodel>().createInvoice(newInvoice);

    if (success) {
      AppSnackbar.showSuccess(context, "Tạo hóa đơn thành công");
      Navigator.pop(context);
    } else {
      AppSnackbar.showError(context, "Tạo hóa đơn thất bại");
    }
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final productVM = context.watch<ProductViewModel>();
    final customerVM = context.watch<CustomerViewmodel>();
    final invoiceVM = context.watch<InvoiceViewmodel>();
    final isLoading = productVM.isLoading || customerVM.isLoading;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      body: Form(
        key: _formKey,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  const AppSliverAppBar(
                    title: 'Tạo Hóa Đơn Mới',
                    showBackButton: true,
                    height: 80,
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(0, 8, 0, 140),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildInvoiceInfoCard(cs, invoiceVM.invoices),
                        _buildSectionLabel('Thông Tin Khách Hàng'),
                        _buildCustomerSection(cs, customerVM.customers),
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
      bottomSheet: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
          child: AppButton(
            text: "Lưu hóa đơn",
            isLoading: productVM.isLoading,
            onPressed: _submitForm,
          ),
        ),
      ),
    );
  }

  // ==================== SECTIONS ====================

  Widget _buildInvoiceInfoCard(ColorScheme cs, List<Invoice> invoices) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LabeledField(
            label: 'Số Hóa Đơn',
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withOpacity(0.6),
                border: Border.all(color: cs.outlineVariant),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'INV0-00000${invoices.length + 1}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _LabeledField(
                  label: 'Ngày',
                  child: _TappableField(
                    value: DateFormat('dd/MM/yyyy').format(_invoiceDate),
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
                    onChanged: (v) => setState(() => _status = v ?? 'Nhập'),
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

  Widget _buildCustomerSection(ColorScheme cs, List<Customer> customers) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Chọn Khách Hàng',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Navigate to add new customer
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
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _StyledDropdown<Customer?>(
            value: _selectedCustomer,
            items: [null, ...customers],
            hint: 'Tìm và chọn khách hàng',
            labelBuilder: (c) => c?.name ?? 'Tìm và chọn khách hàng',
            onChanged: _onCustomerSelected,
            cs: cs,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _LabeledField(
                  label: 'Tên Khách Hàng',
                  child: _StyledTextFormField(
                    controller: _nameController,
                    hint: 'Nhập tên khách hàng',
                    validator: (v) =>
                        v?.trim().isEmpty ?? true ? 'Vui lòng nhập tên' : null,
                    cs: cs,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _LabeledField(
                  label: 'Điện Thoại',
                  child: _StyledTextFormField(
                    controller: _phoneController,
                    hint: 'Số điện thoại',
                    keyboardType: TextInputType.phone,
                    cs: cs,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _LabeledField(
            label: 'Địa Chỉ',
            child: _StyledTextFormField(
              controller: _addressController,
              hint: 'Địa chỉ giao hàng',
              cs: cs,
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
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: () => _showProductPicker(products, alreadyAddedIds),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Thêm Sản Phẩm'),
                style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  textStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
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
            // Table header
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
          // Discount + Cash inputs
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
                  label: 'Tiền Nhận (VNĐ)',
                  child: _StyledTextFormField(
                    hint: '0',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (v) =>
                        setState(() => _cashReceived = double.tryParse(v) ?? 0),
                    cs: cs,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Summary box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withOpacity(0.4),
              borderRadius: BorderRadius.circular(16),
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
                  value: '${_currencyFormatter.format(_cashReceived)} đ',
                  valueColor: Colors.green,
                  cs: cs,
                ),
                const SizedBox(height: 12),
                // Tiền thừa / Tiền thiếu
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
                            isDebtState ? 'Tiền thiếu' : 'Tiền thừa',
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
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
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
  void didUpdateWidget(covariant _LineItemRow oldWidget) {
    super.didUpdateWidget(oldWidget);
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
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Product info
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13.5),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.product.categoryId != null)
                  Text(
                    item.product.categoryId!,
                    style: TextStyle(fontSize: 11.5, color: cs.outline),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Qty + Price inputs
          Expanded(
            flex: 3,
            child: Column(
              children: [
                _MiniNumberField(
                  controller: _qtyCtrl,
                  hint: 'SL',
                  suffix: item.product.unit ?? '',
                  cs: cs,
                  onChanged: (v) =>
                      widget.onQtyChanged(double.tryParse(v) ?? 1),
                ),
                const SizedBox(height: 6),
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
          const SizedBox(width: 12),
          // Line total
          Expanded(
            flex: 2,
            child: Text(
              '${widget.currency.format(item.lineTotal)} đ',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: cs.primary,
                fontSize: 13.5,
              ),
            ),
          ),
          // Delete
          IconButton(
            onPressed: widget.onDelete,
            icon: Icon(Icons.close_rounded, color: cs.error, size: 20),
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
            .map((p) => p.categoryId ?? '')
            .where((c) => c.isNotEmpty)
            .toSet()
            .toList()
          ..sort(),
      ];

  List<Product> get _filteredProducts => widget.products.where((p) {
        final matchCat =
            _selectedCategory == 'Tất cả' || p.categoryId == _selectedCategory;
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
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Chọn Sản Phẩm',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Tìm sản phẩm...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _searchText = v),
              ),
            ),
            const SizedBox(height: 12),
            // Category chips
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final cat = _categories[i];
                  return ChoiceChip(
                    label: Text(cat, style: const TextStyle(fontSize: 12)),
                    selected: _selectedCategory == cat,
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            // Product list
            Expanded(
              child: _filteredProducts.isEmpty
                  ? Center(
                      child: Text(
                        'Không tìm thấy sản phẩm',
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
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
                              fontSize: 13,
                              color: isAdded ? cs.outline : cs.onSurface,
                            ),
                          ),
                          subtitle: Text(
                            '${product.categoryId ?? 'Chưa phân loại'} · ${product.unit ?? ''}',
                            style: TextStyle(fontSize: 11.5, color: cs.outline),
                          ),
                          trailing: isAdded
                              ? const Chip(
                                  label: Text('Đã thêm',
                                      style: TextStyle(fontSize: 11)),
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
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: cs.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    const Icon(Icons.add_circle_rounded,
                                        size: 20, color: Colors.green),
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
