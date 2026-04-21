import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:manager/core/extensions/l10n_extension.dart';
import 'package:manager/core/router/app_routes.dart';
import 'package:manager/data/models/invoice.dart';
import 'package:manager/viewmodels/invoice_viewmodel.dart';
import 'package:manager/views/widgets/app_search_field.dart';
import 'package:manager/views/widgets/app_sliver_app_bar.dart';
import 'package:manager/views/widgets/app_snackbar.dart';
import 'package:manager/views/widgets/custom_popup.dart';
import 'package:manager/views/widgets/ios_action_sheet.dart'; // ← Import action sheet
import 'package:manager/views/widgets/shared/app_add_button.dart';
import 'package:manager/views/widgets/shared/app_summary_card.dart';
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

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
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
                        (i.customerName?.toLowerCase().contains(query) ??
                            false);
                  }).toList();

            final totalRevenue =
                filtered.fold(0.0, (sum, item) => sum + (item.total ?? 0));

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                AppSliverAppBar(
                  title: context.l10n.invoice ?? 'Hóa đơn',
                  showBackButton: false,
                  height: 150,
                  actions: [
                    AppAddButton(
                      onPressed: () => context.push(AppRoutes.invoiceAdd),
                    ),
                  ],
                  bottom: AppSearchField(controller: searchController),
                ),
                CupertinoSliverRefreshControl(onRefresh: _onRefresh),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 80),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Summary Cards
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

                      // Section Title
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
      ),
    );
  }

  Future<void> _onRefresh() async {
    await context.read<InvoiceViewmodel>().fetchInvoices();
  }

  Widget _buildSectionTitle(ThemeData theme, int count) {
    return Text(
      '${context.l10n.invoice_list ?? "Danh sách hóa đơn"} ($count)',
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildInvoiceCard(Invoice invoice, ColorScheme cs, ThemeData theme) {
    final statusColor = _getStatusColor(invoice.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16), // Padding moves here
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: InkWell(
        // For tap functionality
        onTap: () => _showInvoiceMenu(invoice),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start, // Align top
          children: [
            // Leading Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.receipt_long_rounded, color: statusColor),
            ),
            const SizedBox(width: 12),

            // Title & Subtitle logic
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invoice.invoiceNumber,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    invoice.customerName,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  Text(
                    DateFormat('dd/MM/yyyy').format(invoice.date),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),

            // Trailing logic
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildStatusBadge(invoice.status, statusColor, theme),
                const SizedBox(height: 4),
                Text(
                  '${currencyFormat.format(invoice.total ?? 0)} đ',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if ((invoice.balanceDue ?? 0) > 0)
                  Text(
                    'Còn nợ: ${currencyFormat.format(invoice.balanceDue ?? 0)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.error,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Status Badge
  Widget _buildStatusBadge(String status, Color color, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
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

  // Menu Action (giống Category)
  void _showInvoiceMenu(Invoice invoice) {
    showIosActionSheet(
      context: context,
      name: invoice.invoiceNumber,
      onDetail: () {
        context.push(AppRoutes.invoiceDetail, extra: invoice.id);
      },
      onEdit: () {
        // context.push(AppRoutes.invoiceEdit, extra: invoice); // nếu có route edit
      },
      onDelete: () async {
        return false;
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80),
        child: Column(
          children: [
            Icon(Icons.receipt_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              context.l10n.no_data ?? "Không tìm thấy hóa đơn nào",
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
