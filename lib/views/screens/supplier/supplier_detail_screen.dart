import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:manager/core/extensions/l10n_extension.dart';
import 'package:manager/core/router/app_routes.dart';
import 'package:manager/core/utils/app_responsive.dart';
import 'package:manager/data/models/supplier.dart';
import 'package:manager/viewmodels/supplier_viewmodel.dart';
import 'package:manager/views/widgets/action_bottom_buttons.dart';
import 'package:manager/views/widgets/app_sliver_app_bar.dart';
import 'package:manager/views/widgets/app_snackbar.dart';
import 'package:manager/views/widgets/custom_popup.dart';
import 'package:provider/provider.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

class SupplierDetailScreen extends StatefulWidget {
  final Supplier supplier;

  const SupplierDetailScreen({super.key, required this.supplier});

  @override
  State<SupplierDetailScreen> createState() => _SupplierDetailScreenState();
}

class _SupplierDetailScreenState extends State<SupplierDetailScreen> {
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
          .read<SupplierViewmodel>()
          .deleteSupplier(widget.supplier.id!);
      if (mounted && success) {
        AppSnackbar.showSuccess(context, "Xóa thành công");
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, "Có lỗi xảy ra khi xóa");
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  // --- GIAO DIỆN CHÍNH ---

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final supplier = widget.supplier;

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
                _buildHeroCard(context, supplier, cs, textTheme),

                // ── THÔNG TIN LIÊN HỆ ───────────────────────────
                _buildSection(
                  context,
                  title: 'Thông tin liên hệ',
                  children: [
                    _buildRow(context, 'Người liên hệ', supplier.contactPerson),
                    _buildRow(context, 'Số điện thoại', supplier.phone),
                    _buildRow(context, 'Email', supplier.email),
                    _buildRow(
                      context,
                      'Địa chỉ',
                      [supplier.address, supplier.city]
                          .where((e) => e?.isNotEmpty == true)
                          .join(', ')
                          .nullIfEmpty,
                    ),
                  ],
                ),

                //  ── THÔNG TIN DOANH NGHIỆP ──────────────────────
                // _buildSection(
                //   context,
                //   title: 'Thông tin doanh nghiệp',
                //   children: [
                //     _buildRow(context, 'Mã số thuế', supplier.taxCode),
                //     _buildRow(context, 'Website', supplier.website),
                //     _buildRow(context, 'Ngân hàng', supplier.bankName),
                //     _buildRow(context, 'Số tài khoản', supplier.bankAccount),
                //   ],
                // ),

                // ── GHI CHÚ ─────────────────────────────────────
                // if (supplier.notes?.isNotEmpty == true)
                //   _buildSection(
                //     context,
                //     title: 'Ghi chú',
                //     children: [
                //       Padding(
                //         padding: const EdgeInsets.only(top: 4),
                //         child: Text(
                //           supplier.notes!,
                //           style: textTheme.bodyMedium?.copyWith(
                //             color: cs.onSurfaceVariant,
                //             height: 1.6,
                //           ),
                //         ),
                //       ),
                //     ],
                //   ),

                // ── NGÀY TẠO ────────────────────────────────────
                if (supplier.createdAt != null)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Ngày tạo: ${supplier.createdAt}',
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
        editText: context.l10n.supplier_edit,
        deleteText: context.l10n.supplier_delete,
        onDelete: () {
          showPopup(
            context: context,
            onOkPressed: _handleDelete,
            onCancelPressed: () {},
            content: context.l10n.confirmDeleteItem(supplier.name),
            title: context.l10n.supplier_delete,
            type: AlertType.warning,
          );
        },
        onEdit: () {
          context.push(AppRoutes.supplierEdit, extra: supplier);
        },
      ),
      resizeToAvoidBottomInset: true,
    );
  }

  // --- CÁC WIDGET THÀNH PHẦN ---

  Widget _buildHeroCard(BuildContext context, Supplier supplier, ColorScheme cs,
      TextTheme textTheme) {
    final bool isActive = supplier.status.toLowerCase() == 'active';
    final Color statusColor = isActive ? Colors.teal : cs.error;
    final Color statusBg =
        isActive ? Colors.teal.withOpacity(0.1) : cs.error.withOpacity(0.1);

    return _buildCard(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon doanh nghiệp (không dùng avatar chữ cái như customer)
              Container(
                width: context.rw(56),
                height: context.rw(56),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(context.rr(18)),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.business_rounded,
                  color: cs.primary,
                  size: context.sp(28),
                ),
              ),
              SizedBox(width: context.rw(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      supplier.name,
                      style: textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (supplier.contactPerson?.isNotEmpty == true) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.person_pin_rounded,
                              size: context.sp(14), color: cs.onSurfaceVariant),
                          SizedBox(width: context.rw(4)),
                          Text(
                            supplier.contactPerson!,
                            style: textTheme.bodyMedium
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    // Status chip
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: context.rw(8), vertical: context.rh(3)),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(context.rr(6)),
                      ),
                      child: Text(
                        supplier.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: context.sp(11),
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Quick action buttons (Call, Email)
          if (supplier.phone != null || supplier.email != null) ...[
            SizedBox(height: context.rh(14)),
            Row(
              children: [
                if (supplier.phone != null) ...[
                  Expanded(
                    child: _buildActionButton(
                      context,
                      icon: Icons.call_rounded,
                      label: 'Gọi điện',
                      color: Colors.green,
                      onTap: () {
                        // TODO: launchUrl(Uri.parse('tel:${supplier.phone}'));
                      },
                    ),
                  ),
                  if (supplier.email != null) SizedBox(width: context.rw(8)),
                ],
                if (supplier.email != null)
                  Expanded(
                    child: _buildActionButton(
                      context,
                      icon: Icons.email_rounded,
                      label: 'Gửi email',
                      color: cs.primary,
                      onTap: () {
                        // TODO: launchUrl(Uri.parse('mailto:${supplier.email}'));
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

// Extension tiện lợi để convert chuỗi rỗng thành null
extension _StringExt on String {
  String? get nullIfEmpty => isEmpty ? null : this;
}
