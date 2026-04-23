import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:manager/core/extensions/l10n_extension.dart';
import 'package:manager/data/models/purchase.dart';
import 'package:manager/viewmodels/purchase_viewmodel.dart';
import 'package:manager/views/widgets/action_bottom_buttons.dart';
import 'package:manager/views/widgets/app_sliver_app_bar.dart';
import 'package:manager/views/widgets/custom_popup.dart';
import 'package:provider/provider.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

class PurchaseDetailScreen extends StatefulWidget {
  const PurchaseDetailScreen({super.key, required this.id});

  final int id;

  @override
  State<PurchaseDetailScreen> createState() => _PurchaseDetailScreenState();
}

class _PurchaseDetailScreenState extends State<PurchaseDetailScreen> {
  final currencyFormat = NumberFormat('#,##0', 'vi_VN');
  bool _hasMinimumLoadingTimePassed = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) setState(() => _hasMinimumLoadingTimePassed = true);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PurchaseViewmodel>().fetchPurchaseById(widget.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PurchaseViewmodel>();
    final purchase = vm.purchaseData;
    final bool isDeleting = false;
    final shouldShowLoading = !_hasMinimumLoadingTimePassed || purchase == null;

    if (shouldShowLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      body: CustomScrollView(
        slivers: [
          AppSliverAppBar(
            title: "Chi tiết đơn nhập",
            showBackButton: true,
            height: 80,
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── SECTION 1: Thông tin chung ──
                _buildCard(
                  context,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildStatusBadge(purchase.status, cs),
                          const Spacer(),
                          Text(
                            DateFormat('dd/MM/yyyy').format(purchase.date),
                            style: tt.bodySmall?.copyWith(color: cs.outline),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        purchase.purchaseNumber,
                        style: tt.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        purchase.supplierName,
                        style: tt.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        Icons.warehouse_rounded,
                        purchase.warehouseName,
                        cs,
                      ),
                      const SizedBox(height: 4),
                      _buildInfoRow(
                        Icons.calendar_today_rounded,
                        "Tạo lúc: ${DateFormat('dd/MM/yyyy').format(purchase.createdAt)}",
                        cs,
                      ),
                      const SizedBox(height: 20),
                      _buildPriceSummary(context, purchase),
                    ],
                  ),
                ),

                // ── SECTION 2: Tổng quan tài chính ──
                _buildSectionLabel(context, "Tổng quan tài chính"),
                _buildCard(
                  context,
                  child: Column(
                    children: [
                      _buildFinanceRow(context, "Tạm tính", purchase.subtotal),
                      const Divider(height: 20),
                      _buildFinanceRow(context, "Chiết khấu", purchase.discount,
                          isNegative: true),
                      const Divider(height: 20),
                      _buildFinanceRow(
                          context, "Đã thanh toán", purchase.paymentMade,
                          highlight: true),
                      const Divider(height: 20),
                      _buildFinanceRow(
                        context,
                        "Còn nợ",
                        purchase.balanceDue,
                        isDebt: true,
                      ),
                    ],
                  ),
                ),

                // ── SECTION 3: Lịch sử thanh toán ──
                _buildSectionLabel(context, "Lịch sử thanh toán"),
                if (purchase.payments.isEmpty)
                  _buildEmptyState(context, "Chưa có thanh toán nào")
                else
                  ...purchase.payments.map(
                    (p) => _buildCard(
                      context,
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: cs.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.payment_rounded,
                                color: cs.primary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.method,
                                  style: tt.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Ref: ${p.reference ?? 'Không có'}",
                                  style:
                                      tt.bodySmall?.copyWith(color: cs.outline),
                                ),
                                if (p.notes != null && p.notes!.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    p.notes!,
                                    style: tt.bodySmall
                                        ?.copyWith(color: cs.outline),
                                  ),
                                ],
                                const SizedBox(height: 2),
                                Text(
                                  DateFormat('dd/MM/yyyy').format(p.date),
                                  style:
                                      tt.bodySmall?.copyWith(color: cs.outline),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            "${currencyFormat.format(p.amount)} đ",
                            style: tt.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: cs.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // ── SECTION 4: Chi tiết mặt hàng ──
                _buildSectionLabel(context, "Chi tiết mặt hàng"),
                _buildCard(
                  context,
                  child: Column(
                    children: purchase.items.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return Column(
                        children: [
                          if (index != 0) const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Index badge
                                Container(
                                  width: 28,
                                  height: 28,
                                  margin:
                                      const EdgeInsets.only(right: 12, top: 2),
                                  decoration: BoxDecoration(
                                    color: cs.secondaryContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: cs.onSecondaryContainer,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.productName,
                                        style: tt.bodyLarge?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "${item.billableQty} ${item.unit} × ${currencyFormat.format(item.unitCost)} đ",
                                        style: tt.bodySmall
                                            ?.copyWith(color: cs.outline),
                                      ),
                                      if (item.totalUnits != null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          "Tổng đơn vị: ${item.totalUnits!.toStringAsFixed(0)}",
                                          style: tt.bodySmall
                                              ?.copyWith(color: cs.outline),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  "${currencyFormat.format(item.lineTotal)} đ",
                                  style: tt.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: cs.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: ActionBottomButtons(
        isDeleting: isDeleting,
        editText: 'context.l10n.supplier_edit',
        deleteText: 'context.l10n.supplier_delete',
        onDelete: () {
          showPopup(
            context: context,
            onOkPressed: () {},
            onCancelPressed: () {},
            content: context.l10n.confirmDeleteItem(purchase.purchaseNumber),
            title: context.l10n.supplier_delete,
            type: AlertType.warning,
          );
        },
        onEdit: () {
          // context.push(AppRoutes.supplierEdit, extra: supplier);
        },
      ),
      resizeToAvoidBottomInset: true,
    );
  }

  // ── HELPERS ──────────────────────────────────────────────────

  Widget _buildCard(BuildContext context, {required Widget child}) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSectionLabel(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: Theme.of(context).colorScheme.outline,
            ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, ColorScheme cs) {
    final isReceived = status == 'Received';
    final isPending = status == 'Pending';

    Color bg;
    Color fg;

    if (isReceived) {
      bg = Colors.green.withOpacity(0.1);
      fg = Colors.green;
    } else if (isPending) {
      bg = Colors.orange.withOpacity(0.1);
      fg = Colors.orange;
    } else {
      bg = cs.errorContainer;
      fg = cs.onErrorContainer;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, ColorScheme cs) {
    return Row(
      children: [
        Icon(icon, size: 14, color: cs.outline),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: cs.outline, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceSummary(BuildContext context, Purchase data) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Tổng đơn nhập",
              style: TextStyle(fontWeight: FontWeight.w500)),
          Text(
            "${currencyFormat.format(data.total)} đ",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: cs.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceRow(
    BuildContext context,
    String label,
    double value, {
    bool isNegative = false,
    bool highlight = false,
    bool isDebt = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    Color valueColor = cs.onSurface;
    if (isDebt) valueColor = value > 0 ? cs.error : Colors.green;
    if (highlight) valueColor = cs.primary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: tt.bodyMedium?.copyWith(color: cs.outline)),
        Text(
          "${isNegative ? '- ' : ''}${currencyFormat.format(value)} đ",
          style: tt.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    final cs = Theme.of(context).colorScheme;
    return _buildCard(
      context,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            message,
            style: TextStyle(color: cs.outline, fontSize: 13),
          ),
        ),
      ),
    );
  }
}
