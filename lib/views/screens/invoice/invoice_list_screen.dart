import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:manager/core/extensions/l10n_extension.dart';
import 'package:manager/core/router/app_routes.dart';
import 'package:manager/data/models/invoice.dart';
import 'package:manager/viewmodels/invoice_viewmodel.dart';
import 'package:manager/views/widgets/app_search_field.dart';
import 'package:manager/views/widgets/app_sliver_app_bar.dart';
import 'package:manager/views/widgets/app_snackbar.dart';
import 'package:manager/views/widgets/custom_popup.dart';
import 'package:manager/views/widgets/ios_action_sheet.dart';
import 'package:manager/views/widgets/shared/app_add_button.dart';
import 'package:manager/views/widgets/shared/app_square_icon.dart';
import 'package:manager/views/widgets/shared/app_summary_card.dart';
import 'package:provider/provider.dart';

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController searchController = TextEditingController();
  final NumberFormat currencyFormat = NumberFormat.decimalPattern('vi_VN');

  bool _isPageReady = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _preparePage();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InvoiceViewmodel>().fetchInvoices();
    });
    searchController.addListener(() => setState(() {}));
  }

  void _initAnimations() {
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _animController, curve: Curves.easeOutCubic));
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
    searchController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await context.read<InvoiceViewmodel>().fetchInvoices();
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
            final bool showLoading =
                !_isPageReady || (vm.isLoading && vm.invoices.isEmpty);

            if (showLoading) {
              return Center(
                child: LoadingAnimationWidget.dotsTriangle(
                  color: cs.primary,
                  size: 32,
                ),
              );
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

            return FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    AppSliverAppBar(
                      title: context.l10n.invoice,
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
                            ...filtered
                                .map((i) => _buildInvoiceCard(i, cs, theme)),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
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
    final bool hasDebt = (invoice.balanceDue ?? 0) > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _showInvoiceMenu(invoice),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // ── TOP ROW ──────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar icon
                  AppSquareIcon(
                      icon: Icons.receipt_outlined, status: invoice.status),
                  const SizedBox(width: 16),

                  // Main info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Invoice number + status badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                invoice.invoiceNumber,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: cs.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            _buildStatusBadge(
                                invoice.status, statusColor, theme),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Customer name
                        Row(
                          children: [
                            Icon(Icons.person_pin_rounded,
                                size: 14, color: cs.outline),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                invoice.customerName ?? 'N/A',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Date
                        Row(
                          children: [
                            Icon(Icons.calendar_today_rounded,
                                size: 13, color: cs.outline),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('dd/MM/yyyy').format(invoice.date),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.outline,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // ── DIVIDER ──────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Divider(
                  height: 1,
                  color: cs.outlineVariant.withOpacity(0.5),
                ),
              ),

              // ── BOTTOM ROW ───────────────────────────
              Row(
                children: [
                  Icon(Icons.monetization_on_outlined,
                      size: 16, color: cs.outline),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${currencyFormat.format(invoice.total ?? 0)} đ',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Debt badge (thay thế cho nút gọi của Supplier)
                  if (hasDebt)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: cs.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              size: 13, color: cs.error),
                          const SizedBox(width: 4),
                          Text(
                            'Nợ: ${currencyFormat.format(invoice.balanceDue ?? 0)} đ',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: cs.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_outline_rounded,
                              size: 13, color: Colors.green),
                          const SizedBox(width: 4),
                          Text(
                            'Đã thanh toán',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
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

  // Menu Action
  void _showInvoiceMenu(Invoice invoice) {
    showIosActionSheet(
      context: context,
      name: invoice.invoiceNumber,
      onDetail: () {
        context.push(AppRoutes.invoiceDetail, extra: invoice.id);
      },
      onEdit: () {
        // context.push(AppRoutes.invoiceEdit, extra: invoice);
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
              context.l10n.no_data,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
