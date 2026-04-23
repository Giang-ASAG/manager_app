import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:manager/core/extensions/l10n_extension.dart';
import 'package:manager/core/router/app_routes.dart';
import 'package:manager/core/utils/app_responsive.dart';
import 'package:manager/data/models/product.dart';
import 'package:manager/viewmodels/product_viewmodel.dart';
import 'package:manager/views/widgets/app_search_field.dart';
import 'package:manager/views/widgets/app_sliver_app_bar.dart';
import 'package:manager/views/widgets/ios_action_sheet.dart';
import 'package:manager/views/widgets/shared/app_add_button.dart';
import 'package:manager/views/widgets/shared/app_square_icon.dart';
import 'package:manager/views/widgets/shared/app_summary_card.dart';
import 'package:provider/provider.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController searchController = TextEditingController();

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
      context.read<ProductViewModel>().fetchProducts();
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
    await context.read<ProductViewModel>().fetchProducts();
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
            final bool showLoading =
                !_isPageReady || (vm.isLoading && vm.products.isEmpty);

            if (showLoading) {
              return Center(
                child: LoadingAnimationWidget.dotsTriangle(
                  color: cs.primary,
                  size: 32,
                ),
              );
            }

            final query = searchController.text.trim().toLowerCase();
            final filteredProducts = query.isEmpty
                ? vm.products
                : vm.products
                .where((p) => p.name.toLowerCase().contains(query))
                .toList();

            return FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: CustomScrollView(
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
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, int count) {
    return AppSummaryCard(
      label: context.l10n.product_list,
      value: "$count",
      icon: Icons.inventory_2_rounded,
      color: Colors.orange,
    );
  }

  // ==================== CARD SẢN PHẨM NÂNG CẤP ====================
  Widget _buildProductCard(Product p, ColorScheme cs, ThemeData theme) {
    final priceFormatter = NumberFormat("#,###", "vi_VN");
    final isActive = p.status?.toLowerCase() == 'active';
    final statusColor = isActive ? Colors.green : cs.error;

    return Container(
      margin: EdgeInsets.only(bottom: context.rh(12)),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(context.rr(20)),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: cs.shadow.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(context.rr(20)),
        child: InkWell(
          borderRadius: BorderRadius.circular(context.rr(20)),
          onTap: () => showIosActionSheet(
            context: context,
            name: p.name,
            onEdit: () => context.push(AppRoutes.productEdit, extra: p),
            onDetail: () => context.push(AppRoutes.productDetail, extra: p),
            onDelete: () async =>
                context.read<ProductViewModel>().deleteProduct(p.id!),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.rw(16),
              vertical: context.rh(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon bên trái
                AppSquareIcon(
                  icon: Icons.inventory_2_rounded,
                  status: p.status ?? 'active',
                ),
                SizedBox(width: context.rw(14)),

                // Nội dung bên phải
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dòng 1: Tên + status badge
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              p.name,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: context.sp(14),
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: context.rw(8)),
                          _buildStatusBadge(isActive, statusColor, theme),
                        ],
                      ),
                      SizedBox(height: context.rh(4)),

                      // Dòng 2: Mã sản phẩm (nếu có)
                      if (p.sku != null && p.sku!.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(bottom: context.rh(4)),
                          child: _buildInfoChip(
                            icon: Icons.tag_rounded,
                            text: p.sku!,
                            cs: cs,
                            theme: theme,
                          ),
                        ),

                      // Dòng 3: Đơn vị tính
                      _buildInfoChip(
                        icon: Icons.scale_rounded,
                        text: 'Đơn vị: ${p.unit ?? 'Cái'}',
                        cs: cs,
                        theme: theme,
                      ),

                      SizedBox(height: context.rh(6)),

                      // Divider + thông tin chi tiết
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: context.rh(8)),
                        child: Divider(
                          height: 1,
                          color: cs.outlineVariant.withOpacity(0.4),
                        ),
                      ),

                      // Thông tin giá bán, tồn kho, category
                      _buildProductDetails(p, cs, theme, priceFormatter),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String text,
    required ColorScheme cs,
    required ThemeData theme,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon,
            size: context.sp(12), color: cs.onSurfaceVariant.withOpacity(0.6)),
        SizedBox(width: context.rw(4)),
        Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
            fontSize: context.sp(12),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildProductDetails(
      Product p, ColorScheme cs, ThemeData theme, NumberFormat formatter) {
    final rows = <Widget>[];

    // Giá bán
    rows.add(
      _buildDetailRow(
        icon: Icons.attach_money_rounded,
        label: 'Giá bán:',
        value: '${formatter.format(p.sellingPrice)} đ',
        cs: cs,
        theme: theme,
        valueColor: cs.primary,
        valueWeight: FontWeight.bold,
      ),
    );

    // Giá nhập (nếu có)
    if (p.purchasePrice > 0) {
      rows.add(
        _buildDetailRow(
          icon: Icons.trending_down_rounded,
          label: 'Giá nhập:',
          value: '${formatter.format(p.purchasePrice)} đ',
          cs: cs,
          theme: theme,
        ),
      );
    }

    // Tồn kho
    rows.add(
      _buildDetailRow(
        icon: Icons.inventory_rounded,
        label: 'Tồn kho:',
        value: '${p.quantity ?? 0} ${p.unit ?? ''}',
        cs: cs,
        theme: theme,
        valueColor: (p.quantity ?? 0) < 5 ? cs.error : null,
      ),
    );

    // Danh mục
    if (p.category != null && p.category!.isNotEmpty) {
      rows.add(
        _buildDetailRow(
          icon: Icons.category_rounded,
          label: 'Danh mục:',
          value: p.category!,
          cs: cs,
          theme: theme,
        ),
      );
    }

    // Mô tả (nếu có)
    if (p.description != null && p.description!.isNotEmpty) {
      rows.add(
        _buildDetailRow(
          icon: Icons.description_rounded,
          label: 'Mô tả:',
          value: p.description!,
          cs: cs,
          theme: theme,
          maxLines: 2,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows
          .expand((w) => [w, SizedBox(height: context.rh(4))])
          .toList()
        ..removeLast(),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required ColorScheme cs,
    required ThemeData theme,
    Color? valueColor,
    FontWeight? valueWeight,
    int maxLines = 1,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: context.rh(1)),
          child: Icon(icon,
              size: context.sp(12),
              color: cs.onSurfaceVariant.withOpacity(0.5)),
        ),
        SizedBox(width: context.rw(6)),
        SizedBox(
          width: context.rw(70),
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant.withOpacity(0.7),
              fontSize: context.sp(11),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: valueColor ?? cs.onSurfaceVariant,
              fontWeight: valueWeight ?? FontWeight.normal,
              fontSize: context.sp(11),
            ),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(bool isActive, Color color, ThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.rw(8),
        vertical: context.rh(3),
      ),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.withOpacity(0.2)
            : color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(context.rr(20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: context.rw(5),
            height: context.rw(5),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: context.rw(4)),
          Text(
            isActive ? 'Active' : 'Inactive',
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: context.sp(10),
              letterSpacing: 0.2,
            ),
          ),
        ],
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