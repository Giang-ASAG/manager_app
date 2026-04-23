import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:manager/core/router/app_routes.dart';
import 'package:manager/core/utils/app_responsive.dart';
import 'package:manager/data/models/product.dart';
import 'package:manager/viewmodels/product_viewmodel.dart';
import 'package:manager/views/widgets/action_bottom_buttons.dart';
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
    // Gọi refresh danh sách sản phẩm từ ViewModel nếu cần
    await context.read<ProductViewModel>().fetchProducts();
  }

  Future<void> _handleDelete(Product p) async {
    setState(() => _isDeleting = true);
    try {
      final success =
          await context.read<ProductViewModel>().deleteProduct(p.id);
      if (mounted && success) {
        AppSnackbar.showSuccess(context, "Đã xóa sản phẩm ${p.name}");
        context.pop();
      }
    } catch (e) {
      if (mounted) AppSnackbar.showError(context, "Không thể xóa sản phẩm này");
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
          appBarTitle: 'Chi tiết sản phẩm',
          onRefresh: _fetchData,
          bottomBar: product == null
              ? null
              : ActionBottomButtons(
                  isDeleting: _isDeleting,
                  editText: 'Chỉnh sửa',
                  deleteText: 'Xóa sản phẩm',
                  onDelete: () => showPopup(
                    context: context,
                    title: "Xác nhận xóa",
                    content:
                        "Bạn có chắc chắn muốn xóa sản phẩm ${product.name}?",
                    type: AlertType.warning,
                    onOkPressed: () => _handleDelete(product),
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
      // Hero Card (thông tin chung + giá)
      SliverToBoxAdapter(
        child: DetailHeroCard(
          icon: Icons.inventory_2_rounded,
          title: product.name,
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (product.sku != null && product.sku!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    "SKU: ${product.sku}",
                    style: TextStyle(color: cs.outline, fontSize: 12),
                  ),
                ),
              DetailStatusBadge(status: StatusConfig.activeInactive(isActive)),
            ],
          ),
        ),
      ),

      // Giá nhập & bán (dùng DetailInfoSection)
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
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: cs.primary),
              ),
            ),
          ],
        ),
      ),

      // Thông số kỹ thuật (chỉ hiển thị nếu có dữ liệu)
      if (_hasSpecifications(product))
        SliverToBoxAdapter(
          child: DetailInfoSection(
            title: 'Thông số kỹ thuật',
            children: [
              if (product.weight != null)
                DetailInfoRow(
                    icon: Icons.fitness_center_rounded,
                    label: 'Trọng lượng',
                    value: '${product.weight} kg'),
              if (product.thickness != null && product.thickness!.isNotEmpty)
                DetailInfoRow(
                    icon: Icons.straighten_rounded,
                    label: 'Độ dày',
                    value: product.thickness),
              if (product.specifications != null &&
                  product.specifications!.isNotEmpty)
                DetailInfoRow(
                    icon: Icons.description_rounded,
                    label: 'Thông số khác',
                    value: product.specifications),
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
                value: product.unit ?? '—'),
            DetailInfoRow(
                icon: Icons.receipt_rounded,
                label: 'Đơn vị hóa đơn',
                value: product.billableUnit ?? '—'),
            DetailInfoRow(
                icon: Icons.backpack,
                label: 'Quy cách',
                value: product.packagingUnit ?? '—'),
            DetailInfoRow(
                icon: Icons.numbers_rounded,
                label: 'Số lượng/gói',
                value: product.unitsPerPack?.toString() ?? '—'),
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
                style: TextStyle(height: 1.5, fontSize: 13),
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
    return const SliverFillRemaining(
      child: Center(child: Text('Sản phẩm không tồn tại hoặc đã bị xóa')),
    );
  }
}
