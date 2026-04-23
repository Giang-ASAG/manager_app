import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:manager/core/extensions/l10n_extension.dart';
import 'package:manager/core/router/app_routes.dart';
import 'package:manager/core/utils/app_responsive.dart';
import 'package:manager/data/models/product.dart';
import 'package:manager/viewmodels/product_viewmodel.dart';
import 'package:manager/views/widgets/action_bottom_buttons.dart';
import 'package:manager/views/widgets/app_sliver_app_bar.dart';
import 'package:manager/views/widgets/app_snackbar.dart';
import 'package:manager/views/widgets/custom_popup.dart';
import 'package:provider/provider.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final NumberFormat _currencyFormat = NumberFormat('#,##0', 'vi_VN');
  bool _isLoading = true; // 1. Thêm biến loading khởi tạo là true
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _startLoading();
  }

  Future<void> _startLoading() async {
    // Giả lập thời gian loading 1 giây
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _confirmDelete() {
    showPopup(
      context: context,
      onCancelPressed: () {},
      onOkPressed: _handleDelete,
      type: AlertType.warning,
      title: "Cảnh báo",
      content: "Bạn có muốn xóa sản phẩm này không?",
    );
  }

  Future<void> _handleDelete() async {
    setState(() => _isDeleting = true);
    try {
      final succes = await context
          .read<ProductViewModel>()
          .deleteProduct(widget.product.id);
      if (mounted && succes) {
        AppSnackbar.showSuccess(
            context,
            context.l10n.action_success(
                context.l10n.common_delete, context.l10n.product));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(
            context,
            context.l10n.action_failed(
                context.l10n.common_delete, context.l10n.product));
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
    final product = widget.product;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: cs.surfaceContainerLowest,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: cs.primary),
              const SizedBox(height: 16),
              // Text(
              //   "Đang tải thông tin...",
              //   style:
              //       textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              // ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
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
                _buildHeroCard(context, product, cs, textTheme),

                // ── THÔNG SỐ KỸ THUẬT ──────────────────────────
                _buildSection(
                  context,
                  title: 'Thông số kỹ thuật',
                  children: [
                    _buildRow(context, 'Thông số', product.specifications),
                    _buildRow(
                      context,
                      'Trọng lượng',
                      product.weight != null ? '${product.weight} kg' : null,
                    ),
                    _buildRow(context, 'Độ dày', product.thickness),
                  ],
                ),

                // ── ĐƠN VỊ & TỒN KHO ───────────────────────────
                _buildUnitStockCard(context, product, cs),

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
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Ngày tạo: ${product.createdAt}',
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
        editText: context.l10n.product_edit,
        deleteText: context.l10n.product_delete,
        onDelete: () {
          showPopup(
            context: context,
            onOkPressed: _handleDelete,
            onCancelPressed: () {},
            content: context.l10n.confirmDeleteItem(product.name),
            title: context.l10n.product_delete,
            type: AlertType.warning,
          );
        },
        onEdit: () {
          context.push(AppRoutes.productEdit, extra: product);
        },
      ),
      resizeToAvoidBottomInset: true,
    );
  }

  // --- CÁC WIDGET THÀNH PHẦN ---

  Widget _buildHeroCard(BuildContext context, Product product, ColorScheme cs,
      TextTheme textTheme) {
    return _buildCard(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: context.rw(52),
                height: context.rw(52),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(context.rr(12)),
                ),
                child: Icon(Icons.inventory_2_rounded,
                    color: cs.onPrimaryContainer, size: context.sp(26)),
              ),
              SizedBox(width: context.rw(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name,
                        style: textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    if (product.displayName?.isNotEmpty == true) ...[
                      const SizedBox(height: 2),
                      Text(product.displayName!,
                          style: textTheme.bodyMedium
                              ?.copyWith(color: cs.onSurfaceVariant)),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: context.rw(6),
                      runSpacing: context.rh(4),
                      children: [
                        if (product.sku?.isNotEmpty == true)
                          _buildChip(context, product.sku!,
                              cs.secondaryContainer, cs.onSecondaryContainer),
                        _buildChip(context, product.status ?? 'Active',
                            cs.tertiaryContainer, cs.onTertiaryContainer),
                        if (product.category?.isNotEmpty == true)
                          _buildChip(context, product.category!,
                              cs.primaryContainer, cs.onPrimaryContainer),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: context.rh(14)),
          Row(
            children: [
              Expanded(
                child: _buildPriceTile(
                  context,
                  label: 'Giá nhập',
                  value: '${_currencyFormat.format(product.purchasePrice)} ₫',
                  bgColor: cs.surfaceContainerHighest,
                  labelColor: cs.onSurfaceVariant,
                  valueColor: cs.onSurface,
                ),
              ),
              SizedBox(width: context.rw(8)),
              Expanded(
                child: _buildPriceTile(
                  context,
                  label: 'Giá bán',
                  value: '${_currencyFormat.format(product.sellingPrice)} ₫',
                  bgColor: cs.primaryContainer,
                  labelColor: cs.onPrimaryContainer,
                  valueColor: cs.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUnitStockCard(
      BuildContext context, Product product, ColorScheme cs) {
    return _buildCard(
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
              _buildStatTile(context, 'Đơn vị tính', product.unit ?? '—'),
              _buildStatTile(
                context,
                'Đóng gói',
                product.packagingUnit != null && product.unitsPerPack != null
                    ? '${product.packagingUnit} / ${product.unitsPerPack} ${product.unit}'
                    : product.packagingUnit ?? '—',
              ),
              _buildStatTile(
                  context, 'Đơn vị hoá đơn', product.billableUnit ?? '—'),
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
              offset: const Offset(0, 2))
        ],
      ),
      child: child,
    );
  }

  Widget _buildSection(BuildContext context,
      {required String title, required List<Widget> children}) {
    return _buildCard(context,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildSectionLabel(context, title),
          const SizedBox(height: 8),
          ...children
        ]));
  }

  Widget _buildSectionLabel(BuildContext context, String title) {
    return Text(title.toUpperCase(),
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.8));
  }

  Widget _buildRow(BuildContext context, String label, String? value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.rh(6)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(fontSize: context.sp(13), color: Colors.grey)),
          Text(
            value?.isNotEmpty == true ? value! : '—',
            style: TextStyle(
              fontSize: context.sp(13),
              fontWeight: FontWeight.w500,
              color: value?.isNotEmpty == true
                  ? const Color(0xFF1A1A2E)
                  : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile(BuildContext context, String label, String value) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(context.rw(10)),
      decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(context.rr(10))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: TextStyle(fontSize: context.sp(11), color: Colors.grey)),
          SizedBox(height: context.rh(2)),
          Text(value,
              style: TextStyle(
                  fontSize: context.sp(13),
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildPriceTile(BuildContext context,
      {required String label,
      required String value,
      required Color bgColor,
      required Color labelColor,
      required Color valueColor}) {
    return Container(
      padding: EdgeInsets.all(context.rw(12)),
      decoration: BoxDecoration(
          color: bgColor, borderRadius: BorderRadius.circular(context.rr(10))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(fontSize: context.sp(11), color: labelColor)),
          SizedBox(height: context.rh(4)),
          Text(value,
              style: TextStyle(
                  fontSize: context.sp(15),
                  fontWeight: FontWeight.w600,
                  color: valueColor)),
        ],
      ),
    );
  }

  Widget _buildChip(BuildContext context, String text, Color bg, Color fg) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: context.rw(8), vertical: context.rh(3)),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(context.rr(6))),
      child: Text(text,
          style: TextStyle(
              fontSize: context.sp(11),
              fontWeight: FontWeight.w500,
              color: fg)),
    );
  }
}
