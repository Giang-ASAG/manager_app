import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:manager/core/extensions/l10n_extension.dart';
import 'package:manager/core/utils/app_responsive.dart';
import 'package:manager/data/models/invoice.dart';
import 'package:manager/viewmodels/invoice_viewmodel.dart';
import 'package:manager/views/widgets/detail/detail_status_badge.dart';
import 'package:provider/provider.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final int id;
  const InvoiceDetailScreen({super.key, required this.id});

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  final _currencyFormat = NumberFormat('#,##0', 'vi_VN');

  Future<void> _fetchData() async {
    await context.read<InvoiceViewmodel>().fetchInvoicebyId(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    return Selector<InvoiceViewmodel, Invoice?>(
      selector: (_, vm) => vm.invoiceDta,
      builder: (context, invoice, _) {
        return DetailScaffold(
          appBarTitle: context.l10n.invoice_detail,
          onRefresh: _fetchData,
          bottomBar: null, // Hóa đơn thường không có bottom actions (có thể thêm sau)
          slivers: invoice == null
              ? [_buildNotFound()]
              : _buildContent(context, invoice),
        );
      },
    );
  }

  List<Widget> _buildContent(BuildContext context, Invoice invoice) {
    final cs = Theme.of(context).colorScheme;
    final isPaid = invoice.status.toLowerCase() == 'paid';

    return [
      // Header Card (gradient đặc thù) - vẫn giữ style riêng nhưng wrap trong SliverToBoxAdapter
      SliverToBoxAdapter(
        child: _InvoiceHeaderCard(invoice: invoice, formatter: _currencyFormat),
      ),

      // Thông tin khách hàng (dùng DetailInfoSection)
      SliverToBoxAdapter(
        child: DetailInfoSection(
          title: 'Thông tin khách hàng',
          children: [
            DetailInfoRow(
              icon: Icons.person_outline_rounded,
              label: 'Khách hàng',
              value: invoice.customerName,
            ),
            if (invoice.customerPhone != null)
              DetailInfoRow(
                icon: Icons.phone_rounded,
                label: 'Số điện thoại',
                value: invoice.customerPhone,
              ),
            if (invoice.customerAddress != null)
              DetailInfoRow(
                icon: Icons.location_on_rounded,
                label: 'Địa chỉ',
                value: invoice.customerAddress,
              ),
          ],
        ),
      ),

      // Danh sách mặt hàng (dùng DetailInfoSection với children tùy chỉnh)
      SliverToBoxAdapter(
        child: DetailInfoSection(
          title: 'Chi tiết mặt hàng (${invoice.items.length})',
          children: [
            ...invoice.items.map((item) => _InvoiceItemTile(
              item: item,
              formatter: _currencyFormat,
            )).toList(),
          ],
        ),
      ),

      // Lịch sử thanh toán
      if (invoice.payments.isNotEmpty)
        SliverToBoxAdapter(
          child: DetailInfoSection(
            title: 'Lịch sử thanh toán',
            children: [
              ...invoice.payments.map((payment) => _PaymentTile(
                payment: payment,
                formatter: _currencyFormat,
              )).toList(),
            ],
          ),
        )
      else
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: context.rw(16), vertical: context.rh(8)),
            child: Container(
              padding: EdgeInsets.all(context.rw(16)),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cs.outlineVariant.withOpacity(0.3)),
              ),
              child: const Center(child: Text('Chưa có thanh toán nào')),
            ),
          ),
        ),
    ];
  }

  Widget _buildNotFound() {
    return const SliverFillRemaining(
      child: Center(child: Text('Không tìm thấy hóa đơn')),
    );
  }
}

// ===================== CÁC WIDGET CON RIÊNG =====================

class _InvoiceHeaderCard extends StatelessWidget {
  final Invoice invoice;
  final NumberFormat formatter;
  const _InvoiceHeaderCard({required this.invoice, required this.formatter});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isPaid = invoice.status.toLowerCase() == 'paid';

    return Container(
      margin: EdgeInsets.all(context.rw(16)),
      padding: EdgeInsets.all(context.rw(20)),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [cs.primary, cs.primary.withOpacity(0.8)]),
        borderRadius: BorderRadius.circular(context.rr(24)),
        boxShadow: [BoxShadow(color: cs.primary.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DetailStatusBadge(
                status: StatusConfig(
                  label: invoice.status.toUpperCase(),
                  color: isPaid ? Colors.white : Colors.orange,
                ),
              ),
              Text(
                DateFormat('dd/MM/yyyy').format(invoice.date),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          SizedBox(height: context.rh(16)),
          Text(
            invoice.invoiceNumber,
            style: tt.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          Divider(height: context.rh(32), color: Colors.white24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "TỔNG TIỀN HÓA ĐƠN",
                style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
              ),
              Text(
                "${formatter.format(invoice.total)} đ",
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InvoiceItemTile extends StatelessWidget {
  final dynamic item;
  final NumberFormat formatter;
  const _InvoiceItemTile({required this.item, required this.formatter});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(Icons.shopping_bag_rounded, size: 18, color: Theme.of(context).colorScheme.outline),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  "${item.qty} ${item.unit} x ${formatter.format(item.unitPrice ?? 0)}",
                  style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            "${formatter.format(item.lineTotal ?? 0)} đ",
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
            backgroundColor: Colors.blue.withOpacity(0.1),
            child: const Icon(Icons.payment, color: Colors.blue, size: 14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.method,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                if (payment.reference != null)
                  Text(
                    "Ref: ${payment.reference}",
                    style: TextStyle(color: cs.outline, fontSize: 11),
                  ),
              ],
            ),
          ),
          Text(
            "${formatter.format(payment.amount)} đ",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}