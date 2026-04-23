import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:manager/core/router/app_routes.dart';
import 'package:manager/core/utils/app_responsive.dart';
import 'package:manager/data/models/purchase.dart';
import 'package:manager/viewmodels/purchase_viewmodel.dart';
import 'package:manager/views/widgets/app_search_field.dart';
import 'package:manager/views/widgets/app_sliver_app_bar.dart';
import 'package:manager/views/widgets/ios_action_sheet.dart';
import 'package:manager/views/widgets/shared/app_add_button.dart';
import 'package:manager/views/widgets/shared/app_square_icon.dart';
import 'package:manager/views/widgets/shared/app_summary_card.dart';
import 'package:provider/provider.dart';

class PurchaseListScreen extends StatefulWidget {
  const PurchaseListScreen({super.key});

  @override
  State<PurchaseListScreen> createState() => _PurchaseListScreenState();
}

class _PurchaseListScreenState extends State<PurchaseListScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController searchController = TextEditingController();
  final NumberFormat currencyFormat = NumberFormat.decimalPattern('vi_VN');

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
      context.read<PurchaseViewmodel>().fetchPurchases();
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
    await context.read<PurchaseViewmodel>().fetchPurchases();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Consumer<PurchaseViewmodel>(
          builder: (_, vm, __) {
            final bool showLoading =
                !_isPageReady || (vm.isLoading && vm.purchases.isEmpty);

            if (showLoading) {
              return Center(
                child: LoadingAnimationWidget.dotsTriangle(
                  color: cs.primary,
                  size: 32,
                ),
              );
            }

            final query = searchController.text.trim().toLowerCase();
            final filtered = query.isEmpty
                ? vm.purchases
                : vm.purchases.where((p) {
                    return p.purchaseNumber.toLowerCase().contains(query) ||
                        p.supplierName.toLowerCase().contains(query);
                  }).toList();

            final totalAmount =
                filtered.fold(0.0, (sum, pay) => sum + (pay.amount ?? 0));

            return FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics()),
                  slivers: [
                    AppSliverAppBar(
                      title: 'Đơn mua hàng',
                      showBackButton: false,
                      height: 160,
                      actions: [
                        AppAddButton(
                          onPressed: () => context.push(AppRoutes.purchaseAdd),
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
                          // Summary Cards - Nâng cấp
                          Row(
                            children: [
                              Expanded(
                                child: AppSummaryCard(
                                  label: "Số lượng",
                                  value: "${filtered.length}",
                                  icon: Icons.description_outlined,
                                  color: cs.primary,
                                ),
                              ),
                              SizedBox(width: context.rw(12)),
                              Expanded(
                                child: AppSummaryCard(
                                  label: "Tổng tiền",
                                  value:
                                      "đ${currencyFormat.format(totalAmount)}",
                                  icon: Icons.attach_money_rounded,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: context.rh(24)),

                          if (filtered.isEmpty)
                            _buildEmptyState()
                          else
                            ...filtered.map(
                                (p) => _buildPurchaseCard(p, cs, theme, vm)),
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

  Widget _buildPurchaseCard(Purchase purchase, ColorScheme cs, ThemeData theme,
      PurchaseViewmodel vm) {
    // Đồng bộ logic: Received = Green (Paid/Done), Các trạng thái khác = Orange (Draft/Pending)
    final bool isCompleted = purchase.status.toLowerCase() == 'received';

    return Container(
      margin: EdgeInsets.only(bottom: context.rh(14)),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(context.rr(24)),
        // Bo góc 24 cho đồng bộ Invoice
        border: Border.all(color: cs.outlineVariant.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(context.rr(24)),
        child: InkWell(
          borderRadius: BorderRadius.circular(context.rr(24)),
          onTap: () {
            showIosActionSheet(
              context: context,
              name: purchase.purchaseNumber,
              onEdit: () =>
                  context.push(AppRoutes.purchaseEdit, extra: purchase),
              onDetail: () =>
                  context.push(AppRoutes.purchaseDetail, extra: purchase.id),
              onDelete: () async => vm.deletePurchase(purchase.id),
            );
          },
          splashColor: cs.primary.withOpacity(0.05),
          child: Padding(
            padding: EdgeInsets.all(context.rw(16)),
            child: Column(
              children: [
                // ── TOP SECTION: Info & Status ──────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sử dụng AppSquareIcon đã định nghĩa
                    AppSquareIcon(
                      icon: Icons.shopping_bag_rounded,
                      status: purchase.status,
                      // Sẽ tự động nhảy màu theo logic của Icon
                      size: context.rw(56),
                    ),
                    SizedBox(width: context.rw(16)),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  purchase.purchaseNumber,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: context.sp(16),
                                    color: cs.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              _buildStatusBadge(isCompleted, cs),
                            ],
                          ),
                          SizedBox(height: context.rh(6)),

                          // Supplier Info
                          Row(
                            children: [
                              Icon(Icons.local_shipping_rounded,
                                  size: context.sp(16), color: cs.outline),
                              SizedBox(width: context.rw(6)),
                              Expanded(
                                child: Text(
                                  purchase.supplierName,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: cs.onSurfaceVariant,
                                    fontSize: context.sp(14),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // ── DIVIDER ──────────────────────────────
                Padding(
                  padding: EdgeInsets.symmetric(vertical: context.rh(14)),
                  child: Divider(
                    height: 1,
                    thickness: 0.5,
                    color: cs.outlineVariant.withOpacity(0.5),
                  ),
                ),

                // ── BOTTOM SECTION: Amount & Payment Status ───────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Giá trị đơn nhập hàng
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tổng tiền nhập',
                          style: theme.textTheme.labelSmall?.copyWith(
                              color: cs.outline, fontSize: context.sp(11)),
                        ),
                        Text(
                          '${currencyFormat.format(purchase.amount)} đ',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: context.sp(17),
                          ),
                        ),
                      ],
                    ),

                    // Indicator trạng thái nhận hàng/thanh toán
                    _buildPurchaseIndicator(isCompleted, cs, theme),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

// Widget phụ trợ cho Purchase Indicator
  Widget _buildPurchaseIndicator(
      bool isCompleted, ColorScheme cs, ThemeData theme) {
    final color = isCompleted ? Colors.green : Colors.orange;
    final icon =
        isCompleted ? Icons.inventory_rounded : Icons.pending_actions_rounded;
    final label = isCompleted ? 'Đã nhập kho' : 'Chờ xử lý';

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: context.rw(12), vertical: context.rh(6)),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(context.rr(12)),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: context.sp(14), color: color),
          SizedBox(width: context.rw(6)),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: context.sp(11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isCompleted, ColorScheme cs) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.rw(10),
        vertical: context.rh(5),
      ),
      decoration: BoxDecoration(
        color: isCompleted
            ? Colors.green.withOpacity(0.12)
            : Colors.orange.withOpacity(0.12),
        borderRadius: BorderRadius.circular(context.rr(20)),
        border: Border.all(
          color: isCompleted
              ? Colors.green.withOpacity(0.3)
              : Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCompleted ? Icons.check_circle : Icons.pending,
            size: context.sp(14),
            color: isCompleted ? Colors.green : Colors.orange,
          ),
          SizedBox(width: context.rw(4)),
          Text(
            isCompleted ? 'Hoàn tất' : 'Đang xử lý',
            style: TextStyle(
              fontSize: context.sp(11),
              fontWeight: FontWeight.w600,
              color: isCompleted ? Colors.green : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: context.rh(100)),
        child: Column(
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: context.sp(92),
              color: Colors.grey.shade300,
            ),
            SizedBox(height: context.rh(20)),
            Text(
              'Không có đơn mua hàng nào',
              style: TextStyle(
                fontSize: context.sp(17),
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: context.rh(8)),
            Text(
              'Hãy tạo đơn mua hàng mới hoặc thử tìm kiếm lại',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: context.sp(14),
                color: Colors.grey.shade500,
                height: 1.4,
              ),
            ),
            SizedBox(height: context.rh(32)),
            // Nút tạo mới trong empty state
            ElevatedButton.icon(
              onPressed: () => context.push(AppRoutes.purchaseAdd),
              icon: const Icon(Icons.add),
              label: const Text('Tạo đơn mua hàng'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: context.rw(24),
                  vertical: context.rh(12),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(context.rr(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
