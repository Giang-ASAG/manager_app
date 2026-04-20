import 'package:flutter/cupertino.dart'; // ← Thêm import này
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:manager/core/extensions/l10n_extension.dart';
import 'package:manager/core/router/app_routes.dart';
import 'package:manager/data/models/product.dart';
import 'package:manager/viewmodels/product_viewmodel.dart';
import 'package:manager/views/widgets/app_search_field.dart';
import 'package:manager/views/widgets/app_sliver_app_bar.dart';
import 'package:manager/views/widgets/app_snackbar.dart';
import 'package:manager/views/widgets/custom_popup.dart';
import 'package:manager/views/widgets/shared/app_add_button.dart';
import 'package:provider/provider.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductViewModel>().fetchProducts();
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
      body: Consumer<ProductViewModel>(
        builder: (_, vm, __) {
          if (vm.isLoading && vm.products.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final query = searchController.text.trim().toLowerCase();
          final filteredProducts = query.isEmpty
              ? vm.products
              : vm.products
                  .where((p) => p.name.toLowerCase().contains(query))
                  .toList();

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            // Quan trọng cho refresh mượt
            slivers: [
              // ==================== APP BAR ====================
              AppSliverAppBar(
                title: context.l10n.product,
                showBackButton: true,
                height: 150,
                actions: [
                  AppAddButton(
                    onPressed: () => context.push(AppRoutes.productAdd),
                  ),
                ],
                bottom: AppSearchField(controller: searchController),
              ),

              // ==================== CUPERTINO REFRESH ====================
              CupertinoSliverRefreshControl(
                onRefresh: _onRefresh,
              ),

              // ==================== CONTENT ====================
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 80),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 10),
                    Text(
                      '${context.l10n.product_list} (${filteredProducts.length})',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (filteredProducts.isEmpty)
                      _buildEmptySearchResult()
                    else
                      ...filteredProducts.map((p) => _buildProductCard(p)),
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
    await context.read<ProductViewModel>().fetchProducts();
  }

  // ==================== PRODUCT CARD ====================
  Widget _buildProductCard(Product p) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final priceFormatter = NumberFormat("#,###", "vi_VN");
    final String formattedPrice = "${priceFormatter.format(p.sellingPrice)} đ";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => context.push(AppRoutes.productDetail, extra: p),
        onLongPress: () => _showDeleteDialog(p), // Thêm long press hỗ trợ
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Ảnh / Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.inventory_2_rounded,
                  color: cs.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),

              // Thông tin
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Đơn vị
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: cs.secondaryContainer.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            p.unit ?? "Cái",
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: cs.onSecondaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Tồn kho
                        Text(
                          'Kho: ${p.unitsPerPack ?? 0}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: (p.unitsPerPack ?? 0) < 5
                                ? cs.error
                                : cs.onSurfaceVariant,
                            fontWeight: (p.unitsPerPack ?? 0) < 5
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      formattedPrice,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Menu hành động
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded, color: cs.outline),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                onSelected: (value) {
                  if (value == 'delete') {
                    _showDeleteDialog(p);
                  } else if (value == 'edit') {
                    // TODO: Điều hướng chỉnh sửa
                    // context.push(AppRoutes.productEdit, extra: p);
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18, color: cs.primary),
                        const SizedBox(width: 8),
                        Text(context.l10n.common_edit),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded,
                            size: 18, color: cs.error),
                        const SizedBox(width: 8),
                        Text(
                          context.l10n.common_delete,
                          style: TextStyle(color: cs.error),
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

  // Dialog xác nhận xóa (tách riêng cho sạch và dễ quản lý)
  void _showDeleteDialog(Product p) {
    showPopup(
      context: context,
      type: AlertType.warning,
      title: "Cảnh báo",
      content: "Bạn có muốn xóa sản phẩm này không?",
      onCancelPressed: () {},
      onOkPressed: () async {
        final success =
            await context.read<ProductViewModel>().deleteProduct(p.id!);

        if (success) {
          AppSnackbar.showSuccess(context, "Xóa thành công");
        } else {
          AppSnackbar.showError(
              context, "Xóa thất bại"); // Nên có hàm showError
        }
      },
    );
  }

  // ==================== EMPTY STATE ====================
  Widget _buildEmptySearchResult() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80),
        child: Column(
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Không tìm thấy sản phẩm',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Thử tìm kiếm với từ khóa khác',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
