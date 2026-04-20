import 'package:flutter/cupertino.dart'; // ← Thêm import này
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:manager/core/router/app_routes.dart';
import 'package:manager/data/models/invoice.dart';
import 'package:manager/viewmodels/invoice_viewmodel.dart';
import 'package:manager/views/widgets/app_search_field.dart';
import 'package:manager/views/widgets/app_sliver_app_bar.dart';
import 'package:manager/views/widgets/shared/app_summary_card.dart';
import 'package:manager/views/widgets/shared/app_add_button.dart';
import 'package:provider/provider.dart';

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  final TextEditingController searchController = TextEditingController();
  final NumberFormat currencyFormat = NumberFormat.decimalPattern('vi_VN');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InvoiceViewmodel>().fetchInvoices();
    });
    searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Consumer<InvoiceViewmodel>(
        builder: (_, vm, __) {
          if (vm.isLoading && vm.invoices.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final query = searchController.text.trim().toLowerCase();
          final filtered = query.isEmpty
              ? vm.invoices
              : vm.invoices.where((i) {
                  return i.invoiceNumber.toLowerCase().contains(query) ||
                      i.customerName.toLowerCase().contains(query);
                }).toList();

          // Tính tổng doanh thu từ danh sách đang hiển thị
          final totalRevenue =
              filtered.fold(0.0, (sum, item) => sum + item.total);

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            // Bắt buộc cho Cupertino refresh
            slivers: [
              // ==================== APP BAR ====================
              AppSliverAppBar(
                title: 'Hóa đơn',
                showBackButton: false,
                height: 150,
                actions: [
                  AppAddButton(
                    onPressed: () => context.push(AppRoutes.invoiceAdd),
                  ),
                ],
                bottom: AppSearchField(controller: searchController),
              ),

              // ==================== CUPERTINO REFRESH CONTROL ====================
              CupertinoSliverRefreshControl(
                onRefresh: _onRefresh,
              ),

              // ==================== CONTENT ====================
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 80),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Row(
                      children: [
                        Expanded(
                          child: AppSummaryCard(
                            label: "Số lượng",
                            value: "${filtered.length}",
                            icon: Icons.description_outlined,
                            color: cs.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AppSummaryCard(
                            label: "Tổng tiền",
                            value: currencyFormat.format(totalRevenue),
                            icon: Icons.monetization_on_outlined,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle(theme, filtered.length),
                    const SizedBox(height: 12),
                    if (filtered.isEmpty)
                      _buildEmptyState()
                    else
                      ...filtered.map((i) => _buildInvoiceCard(i, cs, theme)),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Hàm refresh riêng
  Future<void> _onRefresh() async {
    await context.read<InvoiceViewmodel>().fetchInvoices();
  }

  // ─── WIDGETS ───────────────────────────────────────────────────────────────

  Widget _buildSectionTitle(ThemeData theme, int count) {
    return Text(
      'Danh sách hóa đơn ($count)',
      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildInvoiceCard(Invoice invoice, ColorScheme cs, ThemeData theme) {
    final statusColor = _getStatusColor(invoice.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        onTap: () => context.push(AppRoutes.invoiceDetail, extra: invoice.id),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.receipt_long, color: statusColor),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                invoice.invoiceNumber,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildStatusBadge(invoice.status, statusColor),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              invoice.customerName,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              DateFormat('dd/MM/yyyy').format(invoice.date),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${currencyFormat.format(invoice.total)} đ',
              style: TextStyle(
                color: cs.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (invoice.balanceDue > 0)
              Text(
                'Còn nợ: ${currencyFormat.format(invoice.balanceDue)}',
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'sent':
        return Colors.blue;
      case 'overdue':
        return Colors.red;
      case 'draft':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 80),
        child: Column(
          children: [
            Icon(Icons.receipt_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "Không tìm thấy hóa đơn nào",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
