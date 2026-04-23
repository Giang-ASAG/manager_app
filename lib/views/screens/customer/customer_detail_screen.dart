import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:manager/core/extensions/l10n_extension.dart';
import 'package:manager/core/router/app_routes.dart';
import 'package:manager/core/utils/app_responsive.dart';
import 'package:manager/data/models/customer.dart';
import 'package:manager/viewmodels/customer_viewmodel.dart';
import 'package:manager/views/widgets/action_bottom_buttons.dart';
import 'package:manager/views/widgets/app_sliver_app_bar.dart';
import 'package:manager/views/widgets/app_snackbar.dart';
import 'package:manager/views/widgets/custom_popup.dart';
import 'package:provider/provider.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

class CustomerDetailScreen extends StatefulWidget {
  final Customer customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  bool _isLoading = true;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _startLoading();
  }

  Future<void> _startLoading() async {
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleDelete() async {
    setState(() => _isDeleting = true);
    try {
      final success = await context
          .read<CustomerViewmodel>()
          .deleteCustomer(widget.customer.id);
      if (mounted && success) {
        AppSnackbar.showSuccess(
            context,
            context.l10n.action_success(context.l10n.common_delete,
                context.l10n.customer.toLowerCase()));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(
            context,
            context.l10n.action_failed(context.l10n.common_delete,
                context.l10n.customer.toLowerCase()));
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final customer = widget.customer;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: cs.surfaceContainerLowest,
        body: Center(
          child: CircularProgressIndicator(color: cs.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      body: CustomScrollView(
        slivers: [
          AppSliverAppBar(
            title: context.l10n.supplier_detail,
            showBackButton: true,
            height: 80,
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── HERO CARD ──────────────────────────────────
                _buildHeroCard(context, customer, cs, textTheme),

                // ── THÔNG TIN LIÊN HỆ ───────────────────────────
                _buildSection(
                  context,
                  title: 'Thông tin liên hệ',
                  children: [
                    _buildRow(context, 'Số điện thoại', customer.phone),
                    _buildRow(context, 'Email', customer.email),
                    _buildRow(context, 'Địa chỉ', customer.address),
                  ],
                ),

                // ── CÔNG NỢ ─────────────────────────────────────
                _buildDebtCard(context, customer, cs),

                // ── NGÀY TẠO ────────────────────────────────────
                if (customer.createdAt != null)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Ngày tạo: ${customer.createdAt}',
                      style: textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: ActionBottomButtons(
        isDeleting: _isDeleting,
        editText: context.l10n.customer_edit,
        deleteText: context.l10n.customer_delete,
        onDelete: () {
          showPopup(
            context: context,
            onOkPressed: _handleDelete,
            onCancelPressed: () {},
            content: 'Bạn có muốn xóa khách hàng "${customer.name}" không?',
            title: 'Xóa khách hàng',
            type: AlertType.warning,
          );
        },
        onEdit: () {
          context.push(AppRoutes.customerEdit, extra: customer);
        },
      ),
      resizeToAvoidBottomInset: true,
    );
  }

  // --- CÁC WIDGET THÀNH PHẦN ---

  Widget _buildHeroCard(BuildContext context, Customer customer, ColorScheme cs,
      TextTheme textTheme) {
    final bool isActive = customer.status.toLowerCase() == 'active';
    final Color statusColor = isActive ? Colors.teal : cs.outline;
    final Color statusBg =
        isActive ? Colors.teal.withOpacity(0.1) : cs.outline.withOpacity(0.1);

    return _buildCard(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar với gradient + chữ cái đầu
              Container(
                width: context.rw(56),
                height: context.rw(56),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [cs.primary, cs.primary.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(context.rr(18)),
                ),
                alignment: Alignment.center,
                child: Text(
                  customer.name.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: context.sp(22),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: context.rw(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (customer.phone?.isNotEmpty == true) ...[
                      const SizedBox(height: 2),
                      Text(
                        customer.phone!,
                        style: textTheme.bodyMedium
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: context.rw(6),
                      runSpacing: context.rh(4),
                      children: [
                        // Status chip
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: context.rw(8),
                              vertical: context.rh(3)),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(context.rr(6)),
                          ),
                          child: Text(
                            customer.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: context.sp(11),
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ),
                        // if (customer.customerType?.isNotEmpty == true)
                        //   _buildChip(
                        //     context,
                        //     customer.customerType!,
                        //     cs.secondaryContainer,
                        //     cs.onSecondaryContainer,
                        //   ),
                        // if (customer.taxCode?.isNotEmpty == true)
                        //   _buildChip(
                        //     context,
                        //     'MST: ${customer.taxCode}',
                        //     cs.tertiaryContainer,
                        //     cs.onTertiaryContainer,
                        //   ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Quick action buttons (Call, Email)
          if (customer.phone != null || customer.email != null) ...[
            SizedBox(height: context.rh(14)),
            Row(
              children: [
                if (customer.phone != null) ...[
                  Expanded(
                    child: _buildActionButton(
                      context,
                      icon: Icons.call_rounded,
                      label: 'Gọi điện',
                      color: Colors.green,
                      onTap: () {
                        // TODO: launch phone dialer
                      },
                    ),
                  ),
                  if (customer.email != null) SizedBox(width: context.rw(8)),
                ],
                if (customer.email != null)
                  Expanded(
                    child: _buildActionButton(
                      context,
                      icon: Icons.email_rounded,
                      label: 'Gửi email',
                      color: cs.primary,
                      onTap: () {
                        // TODO: launch email client
                      },
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDebtCard(
      BuildContext context, Customer customer, ColorScheme cs) {
    // final double debt = customer. ?? 0;
    // final bool hasDebt = debt > 0;

    return _buildCard(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel(context, 'Công nợ & Giao dịch'),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 2.4,
            children: [
              // _buildStatTile(
              //   context,
              //   'Công nợ hiện tại',
              //   debt != 0 ? '${_currencyFormat.format(debt)} ₫' : '0 ₫',
              //   valueColor: hasDebt ? Colors.red.shade600 : Colors.teal,
              // ),
              // _buildStatTile(
              //   context,
              //   'Hạn mức nợ',
              //   customer.creditLimit != null
              //       ? '${_currencyFormat.format(customer.creditLimit)} ₫'
              //       : '—',
              // ),
              // _buildStatTile(
              //   context,
              //   'Tổng đơn hàng',
              //   customer.totalOrders != null
              //       ? '${customer.totalOrders} đơn'
              //       : '—',
              // ),
              // _buildStatTile(
              //   context,
              //   'Doanh thu',
              //   customer.totalRevenue != null
              //       ? '${_currencyFormat.format(customer.totalRevenue)} ₫'
              //       : '—',
              // ),
            ],
          ),
        ],
      ),
    );
  }

  // --- HELPER UI METHODS ---

  Widget _buildCard(BuildContext context, {required Widget child}) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin:
          EdgeInsets.fromLTRB(context.rw(16), 0, context.rw(16), context.rh(8)),
      padding: EdgeInsets.all(context.rw(16)),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(context.rr(16)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: child,
    );
  }

  Widget _buildSection(BuildContext context,
      {required String title, required List<Widget> children}) {
    return _buildCard(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel(context, title),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String title) {
    return Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
    );
  }

  Widget _buildRow(BuildContext context, String label, String? value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.rh(6)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: context.sp(13), color: Colors.grey),
          ),
          Flexible(
            child: Text(
              value?.isNotEmpty == true ? value! : '—',
              style: TextStyle(
                fontSize: context.sp(13),
                fontWeight: FontWeight.w500,
                color: value?.isNotEmpty == true
                    ? const Color(0xFF1A1A2E)
                    : Colors.grey,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile(BuildContext context, String label, String value,
      {Color? valueColor}) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(context.rw(10)),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(context.rr(10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: context.sp(11), color: Colors.grey),
          ),
          SizedBox(height: context.rh(2)),
          Text(
            value,
            style: TextStyle(
              fontSize: context.sp(13),
              fontWeight: FontWeight.w600,
              color: valueColor ?? cs.onSurface,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildChip(BuildContext context, String text, Color bg, Color fg) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: context.rw(8), vertical: context.rh(3)),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(context.rr(6)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: context.sp(11),
          fontWeight: FontWeight.w500,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(context.rr(10)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(context.rr(10)),
        child: Padding(
          padding: EdgeInsets.symmetric(
              vertical: context.rh(10), horizontal: context.rw(12)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: context.sp(16), color: color),
              SizedBox(width: context.rw(6)),
              Text(
                label,
                style: TextStyle(
                  fontSize: context.sp(13),
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
