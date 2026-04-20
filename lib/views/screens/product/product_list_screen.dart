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
import 'package:manager/views/widgets/shared/app_summary_card.dart';
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
    // Fetch data khi mở màn hình (dùng addPostFrameCallback để tránh lỗi build)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductViewModel>().fetchProducts();
    });

    // Chỉ cần setState để UI build lại mỗi khi người dùng gõ phím
    searchController.addListener(() {
      setState(() {});
    });
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

          // LỌC DỮ LIỆU TRỰC TIẾP TẠI ĐÂY
          // Luôn đồng bộ với vm.products mới nhất
          final query = searchController.text.trim().toLowerCase();
          final filteredProducts = query.isEmpty
              ? vm.products
              : vm.products.where((p) {
                  return p.name.toLowerCase().contains(query);
                }).toList();

          return CustomScrollView(
            slivers: [
              AppSliverAppBar(
                  title: context.l10n.product,
                  showBackButton: true,
                  height: 150,
                  actions: [
                    AppAddButton(
                      onPressed: () => context.push(AppRoutes.productAdd),
                    ),
                  ],
                  bottom: AppSearchField(controller: searchController)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 80),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Truyền số lượng vào
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
                      ...filteredProducts.map(_buildProductCard),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ==================== PRODUCT CARD ====================
  Widget _buildProductCard(Product p) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Format giá tiền (Ví dụ: 100.000 đ)
    final priceFormatter = NumberFormat("#,###", "vi_VN");
    final String formattedPrice = "${priceFormatter.format(p.sellingPrice)} đ";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24), // Bo góc lớn hiện đại
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
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // 1. Hình ảnh hoặc Icon đại diện
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.inventory_2_rounded,
                    color: cs.primary, size: 28),
              ),
              const SizedBox(width: 16),

              // 2. Thông tin chính
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
                        // Badge Đơn vị
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
                    // Giá bán
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

              // 3. Nút thao tác
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded, color: cs.outline),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    onSelected: (value) {
                      if (value == 'delete') {
                        showPopup(
                            context: context,
                            onCancelPressed: () {},
                            onOkPressed: () {
                              context
                                  .read<ProductViewModel>()
                                  .deleteProduct(p.id!);
                              AppSnackbar.showSuccess(
                                  context, "Xóa thành công");
                            },
                            type: AlertType.warning,
                            title: "Cảnh báo",
                            content: "Bạn có muốn xóa sản phẩm này không?");
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 8),
                            Text(context.l10n.common_edit),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded,
                                size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text(context.l10n.common_delete,
                                style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== EMPTY SEARCH RESULT ====================
  Widget _buildEmptySearchResult() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
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
