import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:manager/data/models/invoice.dart';
import 'package:manager/viewmodels/invoice_viewmodel.dart';
import 'package:manager/views/widgets/app_sliver_app_bar.dart';
import 'package:provider/provider.dart';

class InvoiceDetailScreen extends StatefulWidget {
  const InvoiceDetailScreen({super.key, required this.id});

  final int id;

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  final currencyFormat = NumberFormat('#,##0', 'vi_VN');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InvoiceViewmodel>().fetchInvoicebyId(widget.id);
    });
  }

  @override
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final invoiceData = context.watch<InvoiceViewmodel>().invoiceDta;

    // 👉 Loading / null
    if (invoiceData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      body: CustomScrollView(
        slivers: [
          const AppSliverAppBar(
            title: 'Chi tiết hóa đơn',
            showBackButton: true,
            height: 80,
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // SECTION 1
                _buildCard(
                  context,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildStatusBadge(invoiceData.status, cs),
                          const Spacer(),
                          Text(
                            invoiceData.date.toString(),
                            style: textTheme.bodySmall
                                ?.copyWith(color: cs.outline),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        invoiceData.invoiceNumber,
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        invoiceData.customerName,
                        style: textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(Icons.phone_android_rounded,
                          invoiceData.customerName, cs),
                      const SizedBox(height: 4),
                      _buildInfoRow(Icons.location_on_rounded,
                          invoiceData.customerAddress!, cs),
                      const SizedBox(height: 20),
                      _buildPriceSummary(context, currencyFormat, invoiceData),
                    ],
                  ),
                ),

                // SECTION 2: Payments
                _buildSectionLabel(context, "Lịch sử thanh toán"),
                ...invoiceData.payments.map((p) => _buildCard(
                      context,
                      child: Row(
                        children: [
                          const Icon(Icons.payment),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.method),
                                Text("Ref: ${p.reference}"),
                              ],
                            ),
                          ),
                          Text("${currencyFormat.format(p.amount)} đ"),
                        ],
                      ),
                    )),

                // SECTION 3: Items
                _buildSectionLabel(context, "Chi tiết mặt hàng"),
                _buildCard(
                  context,
                  child: Column(
                    children: invoiceData.items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          // Giúp text lệch phía trên khi bị xuống dòng
                          children: [
                            // 1. Tên sản phẩm & Chi tiết số lượng
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productName,
                                    style: textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: cs.onSurface,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${item.qty} ${item.unit}  ×  ${currencyFormat.format(item.unitPrice)} đ",
                                    style: textTheme.bodySmall?.copyWith(
                                      color: cs.outline,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 16),
                            // Khoảng cách an toàn giữa tên và giá

                            // 2. Thành tiền
                            Text(
                              "${currencyFormat.format(item.lineTotal)} đ",
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: cs
                                    .primary, // Làm nổi bật số tiền cần thanh toán
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── HELPERS (Giữ nguyên logic giao diện) ──────────────────────

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
              offset: const Offset(0, 4)),
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
    final isPaid = status == "Paid";
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isPaid ? Colors.green.withOpacity(0.1) : cs.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: isPaid ? Colors.green : cs.onErrorContainer,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, ColorScheme cs) {
    return Row(
      children: [
        Icon(icon, size: 14, color: cs.outline),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text, style: TextStyle(color: cs.outline, fontSize: 13)),
        ),
      ],
    );
  }

  Widget _buildPriceSummary(
      BuildContext context, NumberFormat format, Invoice data) {
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
          const Text("Tổng thanh toán",
              style: TextStyle(fontWeight: FontWeight.w500)),
          Text(
            "${format.format(data.total)} đ",
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
}
