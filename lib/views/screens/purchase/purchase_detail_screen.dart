import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:manager/core/router/app_routes.dart';
import 'package:manager/core/utils/app_responsive.dart';
import 'package:manager/data/models/purchase.dart';
import 'package:manager/viewmodels/purchase_viewmodel.dart';
import 'package:manager/views/widgets/action_bottom_buttons.dart';
import 'package:manager/views/widgets/app_snackbar.dart';
import 'package:manager/views/widgets/custom_popup.dart';

import 'package:manager/views/widgets/detail/detail_status_badge.dart';
import 'package:provider/provider.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

class PurchaseDetailScreen extends StatefulWidget {
  final int id;

  const PurchaseDetailScreen({super.key, required this.id});

  @override
  State<PurchaseDetailScreen> createState() => _PurchaseDetailScreenState();
}

class _PurchaseDetailScreenState extends State<PurchaseDetailScreen> {
  final _currencyFormat = NumberFormat('#,##0', 'vi_VN');
  bool _isDeleting = false;

  Future<void> _fetchData() async {
    await context.read<PurchaseViewmodel>().fetchPurchaseById(widget.id);
  }

  Future<void> _onConfirmDelete(Purchase purchase) async {
    setState(() => _isDeleting = true);
    try {
      final success =
          await context.read<PurchaseViewmodel>().deletePurchase(purchase.id);
      if (mounted && success) {
        AppSnackbar.showSuccess(
            context, 'Đã xóa đơn nhập ${purchase.purchaseNumber}');
        context.pop();
      }
    } catch (e) {
      if (mounted) AppSnackbar.showError(context, 'Lỗi: $e');
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Selector<PurchaseViewmodel, Purchase?>(
      selector: (_, vm) => vm.purchaseData,
      builder: (context, purchase, _) {
        return DetailScaffold(
          appBarTitle: 'Chi tiết đơn nhập',
          onRefresh: _fetchData,
          bottomBar: purchase == null
              ? null
              : ActionBottomButtons(
                  isDeleting: _isDeleting,
                  editText: 'Chỉnh sửa',
                  deleteText: 'Xóa đơn',
                  onDelete: () => showPopup(
                    context: context,
                    title: 'Xác nhận xóa',
                    content:
                        'Bạn có chắc muốn xóa đơn nhập ${purchase.purchaseNumber}?',
                    type: AlertType.warning,
                    onOkPressed: () => _onConfirmDelete(purchase),
                  ),
                  onEdit: () =>
                      context.push(AppRoutes.purchaseEdit, extra: purchase),
                ),
          slivers: purchase == null
              ? [_buildNotFound()]
              : _buildContent(context, purchase),
        );
      },
    );
  }

  List<Widget> _buildContent(BuildContext context, Purchase purchase) {
    return [
      // Header gradient (đặc thù cho đơn nhập)
      SliverToBoxAdapter(
        child: _HeaderSection(purchase: purchase, formatter: _currencyFormat),
      ),

      // Tổng quan tài chính
      SliverToBoxAdapter(
        child: DetailInfoSection(
          title: 'Tổng quan tài chính',
          children: [
            DetailInfoRow(
              icon: Icons.receipt_long_rounded,
              label: 'Tạm tính',
              value: '${_currencyFormat.format(purchase.subtotal)} đ',
            ),
            if (purchase.discount > 0)
              DetailInfoRow(
                icon: Icons.local_offer_rounded,
                label: 'Chiết khấu',
                value: '-${_currencyFormat.format(purchase.discount)} đ',
              ),
            const Divider(),
            DetailInfoRow(
              icon: Icons.payment_rounded,
              label: 'Đã thanh toán',
              value: '${_currencyFormat.format(purchase.paymentMade)} đ',
              valueWidget: Text(
                '${_currencyFormat.format(purchase.paymentMade)} đ',
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: Colors.green),
              ),
            ),
            DetailInfoRow(
              icon: Icons.account_balance_rounded,
              label: 'Còn nợ',
              value: '${_currencyFormat.format(purchase.balanceDue)} đ',
              valueWidget: Text(
                '${_currencyFormat.format(purchase.balanceDue)} đ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: purchase.balanceDue > 0 ? Colors.red : Colors.green,
                ),
              ),
            ),
          ],
        ),
      ),

      // Danh sách mặt hàng
      SliverToBoxAdapter(
        child: DetailInfoSection(
          title: 'Danh sách mặt hàng (${purchase.items.length})',
          children: [
            ...purchase.items
                .map((item) =>
                    _ProductItemTile(item: item, formatter: _currencyFormat))
                .toList(),
          ],
        ),
      ),

      // Lịch sử thanh toán
      if (purchase.payments.isNotEmpty)
        SliverToBoxAdapter(
          child: DetailInfoSection(
            title: 'Lịch sử thanh toán',
            children: [
              ...purchase.payments
                  .map((payment) => _PaymentTile(
                      payment: payment, formatter: _currencyFormat))
                  .toList(),
            ],
          ),
        )
      else
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: context.rw(16), vertical: context.rh(8)),
            child: Container(
              padding: EdgeInsets.all(context.rw(16)),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .outlineVariant
                        .withOpacity(0.3)),
              ),
              child: const Center(child: Text('Chưa có lịch sử thanh toán')),
            ),
          ),
        ),
    ];
  }

  Widget _buildNotFound() {
    return const SliverFillRemaining(
      child: Center(child: Text('Không tìm thấy dữ liệu đơn nhập')),
    );
  }
}

// ===================== CÁC WIDGET CON RIÊNG =====================

class _HeaderSection extends StatelessWidget {
  final Purchase purchase;
  final NumberFormat formatter;

  const _HeaderSection({required this.purchase, required this.formatter});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isReceived = purchase.status.toLowerCase() == 'received';

    return Container(
      margin: EdgeInsets.all(context.rw(16)),
      padding: EdgeInsets.all(context.rw(20)),
      decoration: BoxDecoration(
        gradient:
            LinearGradient(colors: [cs.primary, cs.primary.withOpacity(0.8)]),
        borderRadius: BorderRadius.circular(context.rr(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DetailStatusBadge(
                status: StatusConfig(
                  label: purchase.status.toUpperCase(),
                  color: isReceived ? Colors.white : Colors.orange,
                ),
              ),
              Text(
                DateFormat('dd/MM/yyyy').format(purchase.date),
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
          SizedBox(height: context.rh(16)),
          Text(
            purchase.purchaseNumber,
            style: tt.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: context.rh(4)),
          Text(
            purchase.supplierName,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          Divider(height: context.rh(32), color: Colors.white24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TỔNG GIÁ TRỊ',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
              Text(
                '${formatter.format(purchase.total)} đ',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductItemTile extends StatelessWidget {
  final dynamic item;
  final NumberFormat formatter;

  const _ProductItemTile({required this.item, required this.formatter});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(Icons.inventory_2_rounded,
              size: 18, color: Theme.of(context).colorScheme.outline),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.billableQty} ${item.unit} x ${formatter.format(item.unitCost)}',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.outline,
                      fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '${formatter.format(item.lineTotal)} đ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final dynamic payment;
  final NumberFormat formatter;

  const _PaymentTile({required this.payment, required this.formatter});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: Colors.green.withOpacity(0.1),
            child: const Icon(Icons.check, color: Colors.green, size: 14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.method,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                ),
                Text(
                  DateFormat('dd/MM HH:mm').format(payment.date),
                  style: TextStyle(color: cs.outline, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            '+${formatter.format(payment.amount)} đ',
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.green),
          ),
        ],
      ),
    );
  }
}
