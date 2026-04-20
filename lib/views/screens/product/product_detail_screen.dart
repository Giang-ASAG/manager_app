import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:manager/core/extensions/l10n_extension.dart';
import 'package:manager/data/models/product.dart';
import 'package:manager/viewmodels/product_viewmodel.dart';
import 'package:manager/views/widgets/app_sliver_app_bar.dart';
import 'package:manager/views/widgets/app_snackbar.dart';
import 'package:manager/views/widgets/custom_popup.dart';
import 'package:provider/provider.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final currencyFormat = NumberFormat('#,##0', 'vi_VN');

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest, // hoặc cs.surface
      body: CustomScrollView(
        slivers: [
          AppSliverAppBar(
            title: context.l10n.product_detail,
            showBackButton: true,
            height: 80,
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── HERO CARD ──────────────────────────────────
                _buildCard(
                  context,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: cs.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.inventory_2_rounded,
                              color: cs.onPrimaryContainer,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (product.displayName?.isNotEmpty ==
                                    true) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    product.displayName!,
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    if (product.sku?.isNotEmpty == true)
                                      _buildChip(
                                        product.sku!,
                                        cs.secondaryContainer,
                                        cs.onSecondaryContainer,
                                      ),
                                    _buildChip(
                                      product.status ?? 'Active',
                                      cs.tertiaryContainer,
                                      cs.onTertiaryContainer,
                                    ),
                                    if (product.categoryId?.isNotEmpty == true)
                                      _buildChip(
                                        product.categoryId!,
                                        cs.primaryContainer,
                                        cs.onPrimaryContainer,
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _buildPriceTile(
                              context,
                              label: 'Giá nhập',
                              value:
                                  '${currencyFormat.format(product.purchasePrice)} ₫',
                              // Dùng surface variant cho giá nhập (màu ấm hơn)
                              bgColor: cs.surfaceContainerHighest,
                              labelColor: cs.onSurfaceVariant,
                              valueColor: cs.onSurface,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildPriceTile(
                              context,
                              label: 'Giá bán',
                              value:
                                  '${currencyFormat.format(product.sellingPrice)} ₫',
                              bgColor: cs.primaryContainer,
                              labelColor: cs.onPrimaryContainer,
                              valueColor: cs.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── THÔNG SỐ KỸ THUẬT ──────────────────────────
                _buildSection(
                  context,
                  title: 'Thông số kỹ thuật',
                  children: [
                    _buildRow('Thông số', product.specifications),
                    _buildRow(
                      'Trọng lượng',
                      product.weight != null ? '${product.weight} kg' : null,
                    ),
                    _buildRow('Độ dày', product.thinkness),
                  ],
                ),

                // ── ĐƠN VỊ & TỒN KHO ───────────────────────────
                _buildCard(
                  context,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionLabel(context, 'Đơn vị & Tồn kho'),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 2.6,
                        children: [
                          _buildStatTile(
                              context, 'Đơn vị tính', product.unit ?? '—'),
                          _buildStatTile(
                            context,
                            'Đóng gói',
                            product.packagingUnit != null &&
                                    product.unitsPerPack != null
                                ? '${product.packagingUnit} / ${product.unitsPerPack} ${product.unit}'
                                : product.packagingUnit ?? '—',
                          ),
                          _buildStatTile(
                            context,
                            'Đơn vị hoá đơn',
                            product.billableUnit ?? '—',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── MÔ TẢ ───────────────────────────────────────
                if (product.description?.isNotEmpty == true)
                  _buildSection(
                    context,
                    title: 'Mô tả',
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          product.description!,
                          style: textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                  ),

                // ── NGÀY TẠO ────────────────────────────────────
                if (product.createdAt != null)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Text(
                      'Ngày tạo: ${product.createdAt}',
                      style: textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),

                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),

      // ── BOTTOM ACTIONS ────────────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push(
                    '/products/${product.id}/edit',
                    extra: product,
                  ),
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: Text(context.l10n.product_edit),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    side: BorderSide(color: cs.outline),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _confirmDelete(context),
                  icon: const Icon(Icons.delete_rounded, size: 18),
                  label: Text(context.l10n.product_delete),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.error,
                    // Hoặc cs.primary nếu muốn giữ màu chính
                    foregroundColor: cs.onError,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── HELPERS ──────────────────────────────────────────────────

  Widget _buildCard(BuildContext context, {required Widget child}) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
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
    final textTheme = Theme.of(context).textTheme;

    return Text(
      title.toUpperCase(),
      style: textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
                fontSize: 13,
                color: Colors
                    .grey), // vẫn giữ tạm, hoặc thay bằng onSurfaceVariant
          ),
          Text(
            value?.isNotEmpty == true ? value! : '—',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: value?.isNotEmpty == true
                  ? const Color(0xFF1A1A2E) // Có thể thay bằng cs.onSurface
                  : Colors.grey,
              fontStyle: value?.isNotEmpty == true
                  ? FontStyle.normal
                  : FontStyle.italic,
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
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor ?? cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceTile(
    BuildContext context, {
    required String label,
    required String value,
    required Color bgColor,
    required Color labelColor,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: labelColor)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: fg,
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showPopup(
      context: context,
      onCancelPressed: () {},
      onOkPressed: () {
        context.read<ProductViewModel>().deleteProduct(product.id);
        AppSnackbar.showSuccess(context, "Xóa thành công");
      },
      type: AlertType.warning,
      title: "Cảnh báo",
      content: "Bạn có muốn xóa không?",
    );
  }
}
