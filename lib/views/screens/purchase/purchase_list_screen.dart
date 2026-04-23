import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:manager/core/router/app_routes.dart';
import 'package:manager/core/utils/app_responsive.dart';
import 'package:manager/data/models/purchase.dart';
import 'package:manager/viewmodels/purchase_viewmodel.dart';
import 'package:manager/views/widgets/app_search_field.dart';
import 'package:manager/views/widgets/app_sliver_app_bar.dart';
import 'package:manager/views/widgets/ios_action_sheet.dart';
import 'package:manager/views/widgets/shared/app_add_button.dart';
import 'package:manager/views/widgets/shared/app_summary_card.dart';
import 'package:provider/provider.dart';

class PurchaseListScreen extends StatefulWidget {
  const PurchaseListScreen({super.key});

  @override
  State<PurchaseListScreen> createState() => _PurchaseListScreenState();
}

class _PurchaseListScreenState extends State<PurchaseListScreen> {
  final TextEditingController searchController = TextEditingController();
  final NumberFormat currencyFormat = NumberFormat.decimalPattern('vi_VN');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PurchaseViewmodel>().fetchPurchases();
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
        body: Consumer<PurchaseViewmodel>(
          builder: (_, vm, __) {
            if (vm.isLoading && vm.purchases.isEmpty) {
              return const Center(child: CircularProgressIndicator());
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

            return CustomScrollView(
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                AppSliverAppBar(
                  title: 'Đơn mua hàng',
                  showBackButton: true,
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
                              value: "đ${currencyFormat.format(totalAmount)}",
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
                        ...filtered
                            .map((p) => _buildPurchaseCard(p, cs, theme, vm)),
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
    await context.read<PurchaseViewmodel>().fetchPurchases();
  }

  Widget _buildPurchaseCard(Purchase purchase, ColorScheme cs, ThemeData theme,
      PurchaseViewmodel vm) {
    final isCompleted = purchase.status.toLowerCase() == 'completed';
    return GestureDetector(
      onTap: () {
        showIosActionSheet(
          context: context,
          name: purchase.purchaseNumber,
          onEdit: () => context.push(AppRoutes.purchaseEdit, extra: purchase),
          onDetail: () =>
              context.push(AppRoutes.purchaseDetail, extra: purchase.id),
          onDelete: () async => vm.deletePurchase(purchase.id),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: context.rh(14)),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(context.rr(16)),
          border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(context.rr(16)),
          child: InkWell(
            borderRadius: BorderRadius.circular(context.rr(16)),
            onTap: () {
              // Tương lai có thể mở chi tiết trực tiếp nếu muốn
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
            splashColor: cs.primary.withOpacity(0.08),
            highlightColor: cs.primary.withOpacity(0.05),
            child: Padding(
              padding: EdgeInsets.all(context.rw(16)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Leading Icon
                  Container(
                    width: context.rw(56),
                    height: context.rw(56),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        colors: isCompleted
                            ? [
                                Colors.green.withOpacity(0.2),
                                Colors.green.withOpacity(0.2)
                              ]
                            : [
                                Colors.orange.withOpacity(0.2),
                                Colors.orange.withOpacity(0.2)
                              ],
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(context.rr(14)),
                    ),
                    child: Icon(
                      Icons.shopping_cart_rounded,
                      color: isCompleted ? Colors.green : Colors.orange,
                      size: context.sp(28),
                    ),
                  ),
                  SizedBox(width: context.rw(16)),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                purchase.purchaseNumber,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: context.sp(15),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            _buildStatusBadge(isCompleted, cs),
                          ],
                        ),
                        SizedBox(height: context.rh(8)),
                        Text(
                          purchase.supplierName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontSize: context.sp(13),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: context.rh(10)),
                        Text(
                          'đ${currencyFormat.format(purchase.total)}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: cs.primary,
                            fontSize: context.sp(16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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
