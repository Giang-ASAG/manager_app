import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:manager/core/extensions/l10n_extension.dart';
import 'package:manager/core/extensions/string_extension.dart';
import 'package:manager/core/router/app_routes.dart';
import 'package:manager/core/utils/app_responsive.dart';
import 'package:manager/data/models/product.dart';
import 'package:manager/viewmodels/product_viewmodel.dart';
import 'package:manager/views/widgets/action_bottom_buttons.dart';
import 'package:manager/views/widgets/alerts/top_alert.dart';
import 'package:manager/views/widgets/app_snackbar.dart';
import 'package:manager/views/widgets/custom_popup.dart';
import 'package:manager/views/widgets/detail/detail_status_badge.dart';
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
  bool _isDeleting = false;

  Future<void> _fetchData() async {
    //await context.read<ProductViewModel>().fetchProducts();
  }

  Future<void> _handleDelete(Product p) async {
    setState(() => _isDeleting = true);
    try {
      final success =
          await context.read<ProductViewModel>().deleteProduct(p.id);
      if (mounted && success) {
        TopAlert.success(
            context, context.l10n.confirmDeleteItem(p.name.toLowerCase()));
        context.pop();
      }
    } catch (e) {
      if (mounted) TopAlert.success(context, "Không thể xóa sản phẩm này");
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Selector<ProductViewModel, Product?>(
      selector: (_, vm) => vm.products.cast<Product?>().firstWhere(
            (p) => p?.id == widget.product.id,
            orElse: () => widget.product,
          ),
      builder: (context, product, _) {
        return DetailScaffold(
          appBarTitle: context.l10n.product_detail,
          onRefresh: _fetchData,
          bottomBar: product == null
              ? null
              : ActionBottomButtons(
                  isDeleting: _isDeleting,
                  editText: context.l10n.product_edit.capitalizeFirstOnly(),
                  deleteText: context.l10n.product_delete.capitalizeFirstOnly(),
                  onDelete: () => showPopup(
                    context: context,
                    title: context.l10n.common_warning.capitalizeFirstOnly(),
                    content: context.l10n.confirmDeleteItem(product.name),
                    type: AlertType.warning,
                    onOkPressed: () => _handleDelete(product),
                    onCancelPressed: () {},
                  ),
                  onEdit: () =>
                      context.push(AppRoutes.productEdit, extra: product),
                ),
          slivers: product == null
              ? [_buildNotFound()]
              : _buildContent(context, product),
        );
      },
    );
  }

  List<Widget> _buildContent(BuildContext context, Product product) {
    final isActive = product.status?.toLowerCase() == 'active';
    final cs = Theme.of(context).colorScheme;

    return [
      // Hero Card
      SliverToBoxAdapter(
        child: DetailHeroCard(
          icon: Icons.inventory_2_rounded,
          title: product.name,
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (product.sku != null && product.sku!.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(bottom: context.rh(4)),
                  child: Text(
                    "SKU: ${product.sku}",
                    style: TextStyle(
                      color: cs.outline,
                      fontSize: context.sp(12),
                    ),
                  ),
                ),
              DetailStatusBadge(status: StatusConfig.activeInactive(isActive)),
            ],
          ),
        ),
      ),

      // Giá nhập & bán
      SliverToBoxAdapter(
        child: DetailInfoSection(
          title: 'Giá cả',
          children: [
            DetailInfoRow(
              icon: Icons.trending_down_rounded,
              label: 'Giá nhập',
              value: '${_currencyFormat.format(product.purchasePrice)} ₫',
            ),
            DetailInfoRow(
              icon: Icons.trending_up_rounded,
              label: 'Giá bán',
              value: '${_currencyFormat.format(product.sellingPrice)} ₫',
              valueWidget: Text(
                '${_currencyFormat.format(product.sellingPrice)} ₫',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: context.sp(14),
                  color: cs.primary,
                ),
              ),
            ),
          ],
        ),
      ),

      // Thông số kỹ thuật
      if (_hasSpecifications(product))
        SliverToBoxAdapter(
          child: DetailInfoSection(
            title: 'Thông số kỹ thuật',
            children: [
              if (product.weight != null)
                DetailInfoRow(
                  icon: Icons.fitness_center_rounded,
                  label: 'Trọng lượng',
                  value: '${product.weight} kg',
                ),
              if (product.thickness != null && product.thickness!.isNotEmpty)
                DetailInfoRow(
                  icon: Icons.straighten_rounded,
                  label: 'Độ dày',
                  value: product.thickness,
                ),
              if (product.specifications != null &&
                  product.specifications!.isNotEmpty)
                DetailInfoRow(
                  icon: Icons.description_rounded,
                  label: 'Thông số khác',
                  value: product.specifications,
                ),
            ],
          ),
        ),

      // Đơn vị & tồn kho
      SliverToBoxAdapter(
        child: DetailInfoSection(
          title: 'Đơn vị & Tồn kho',
          children: [
            DetailInfoRow(
              icon: Icons.scale_rounded,
              label: 'Đơn vị tính',
              value: product.unit ?? '—',
            ),
            DetailInfoRow(
              icon: Icons.receipt_rounded,
              label: 'Đơn vị hóa đơn',
              value: product.billableUnit ?? '—',
            ),
            DetailInfoRow(
              icon: Icons.backpack,
              label: 'Quy cách',
              value: product.packagingUnit ?? '—',
            ),
            DetailInfoRow(
              icon: Icons.numbers_rounded,
              label: 'Số lượng/gói',
              value: product.unitsPerPack?.toString() ?? '—',
            ),
          ],
        ),
      ),

      // Mô tả chi tiết
      if (product.description != null && product.description!.isNotEmpty)
        SliverToBoxAdapter(
          child: DetailInfoSection(
            title: 'Mô tả chi tiết',
            children: [
              Text(
                product.description!,
                style: TextStyle(
                  height: 1.5,
                  fontSize: context.sp(13),
                ),
              ),
            ],
          ),
        ),
    ];
  }

  bool _hasSpecifications(Product product) {
    return (product.weight != null) ||
        (product.thickness != null && product.thickness!.isNotEmpty) ||
        (product.specifications != null && product.specifications!.isNotEmpty);
  }

  Widget _buildNotFound() {
    return SliverFillRemaining(
      child: Center(
        child: Builder(
          builder: (context) => Text(
            'Sản phẩm không tồn tại hoặc đã bị xóa',
            style: TextStyle(fontSize: context.sp(14)),
          ),
        ),
      ),
    );
  }
}
