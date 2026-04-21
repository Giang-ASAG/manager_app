import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:manager/core/extensions/l10n_extension.dart';
import 'package:manager/core/router/app_routes.dart';
import 'package:manager/core/utils/app_responsive.dart';
import 'package:manager/data/models/product.dart';
import 'package:manager/viewmodels/product_viewmodel.dart';
import 'package:manager/views/widgets/app_search_field.dart';
import 'package:manager/views/widgets/app_sliver_app_bar.dart';
import 'package:manager/views/widgets/app_snackbar.dart';
import 'package:manager/views/widgets/custom_popup.dart';
import 'package:manager/views/widgets/ios_action_sheet.dart'; // ← Giả sử bạn có file này
import 'package:manager/views/widgets/shared/app_add_button.dart';
import 'package:provider/provider.dart';

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

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
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
                  bottom: AppSearchField(controller: searchController),
                ),
                CupertinoSliverRefreshControl(onRefresh: _onRefresh),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    context.rw(16),
                    context.rh(24),
                    context.rw(16),
                    context.rh(80),
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildSectionTitle(theme, filteredProducts.length),
                      const SizedBox(height: 12),
                      if (filteredProducts.isEmpty)
                        _buildEmptyState()
                      else
                        ...filteredProducts.map(
                          (p) => _buildProductCard(p, cs, theme),
                        ),
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
    await context.read<ProductViewModel>().fetchProducts();
  }

  Widget _buildSectionTitle(ThemeData theme, int count) {
    return Text(
      '${context.l10n.product_list} ($count)',
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        fontSize: context.sp(15),
      ),
    );
  }

  Widget _buildProductCard(Product p, ColorScheme cs, ThemeData theme) {
    final priceFormatter = NumberFormat("#,###", "vi_VN");
    final String formattedPrice = "${priceFormatter.format(p.sellingPrice)} đ";

    return Container(
      margin: EdgeInsets.only(bottom: context.rh(12)),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(context.rr(24)),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: context.rw(16),
          vertical: context.rh(12),
        ),
        onTap: () => showIosActionSheet(
          context: context,
          name: p.name,
          onEdit: () {
            // TODO: Thay bằng route edit nếu bạn đã có
            // context.push(AppRoutes.productEdit, extra: p);
          },
          onDetail: () {
            context.push(AppRoutes.productDetail, extra: p);
          },
          onDelete: () async {
            return context.read<ProductViewModel>().deleteProduct(p.id!);
          },
        ),

        // ===== ICON =====
        leading: Container(
          width: context.rw(64),
          height: context.rw(64),
          decoration: BoxDecoration(
            color: cs.primaryContainer.withOpacity(0.4),
            borderRadius: BorderRadius.circular(context.rr(16)),
          ),
          child: Icon(
            Icons.inventory_2_rounded,
            color: cs.primary,
            size: context.sp(28),
          ),
        ),

        // ===== TITLE & INFO =====
        title: Row(
          children: [
            Expanded(
              child: Text(
                p.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: context.sp(15),
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _buildUnitBadge(p, cs, theme),
          ],
        ),

        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  'Kho: ${p.unitsPerPack ?? 0}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: (p.unitsPerPack ?? 0) < 5
                        ? cs.error
                        : cs.onSurfaceVariant,
                    fontWeight: (p.unitsPerPack ?? 0) < 5
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: context.sp(12),
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
                fontSize: context.sp(15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitBadge(Product p, ColorScheme cs, ThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.rw(8),
        vertical: context.rh(4),
      ),
      decoration: BoxDecoration(
        color: cs.secondaryContainer.withOpacity(0.6),
        borderRadius: BorderRadius.circular(context.rr(6)),
      ),
      child: Text(
        p.unit,
        style: theme.textTheme.labelSmall?.copyWith(
          color: cs.error,
          fontWeight: FontWeight.bold,
          fontSize: context.sp(11),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: context.rh(80)),
        child: Column(
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: context.sp(80),
              color: Colors.grey.shade300,
            ),
            SizedBox(height: context.rh(16)),
            Text(
              context.l10n.no_data ?? 'Không tìm thấy sản phẩm',
              style: TextStyle(
                fontSize: context.sp(16),
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: context.rh(8)),
            Text(
              context.l10n.no_data ?? 'Thử tìm kiếm với từ khóa khác',
              style: TextStyle(
                fontSize: context.sp(14),
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
