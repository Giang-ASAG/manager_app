import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:manager/core/extensions/l10n_extension.dart';
import 'package:manager/core/router/app_routes.dart';
import 'package:manager/data/models/warehouse.dart';
import 'package:manager/viewmodels/warehouse_viewmodel.dart';
import 'package:manager/views/widgets/app_search_field.dart';
import 'package:manager/views/widgets/app_sliver_app_bar.dart';
import 'package:manager/views/widgets/ios_action_sheet.dart';
import 'package:manager/views/widgets/shared/app_add_button.dart';
import 'package:manager/views/widgets/shared/app_square_icon.dart';
import 'package:manager/views/widgets/shared/app_summary_card.dart';
import 'package:provider/provider.dart';

class WarehouseListScreen extends StatefulWidget {
  const WarehouseListScreen({super.key});

  @override
  State<WarehouseListScreen> createState() => _WarehouseListScreenState();
}

class _WarehouseListScreenState extends State<WarehouseListScreen>
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
      context.read<WarehouseViewModel>().fetchWarehouses();
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
    await context.read<WarehouseViewModel>().fetchWarehouses();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Consumer<WarehouseViewModel>(
        builder: (_, vm, __) {
          // Chỉ hiển thị loading khi chưa ready HOẶC đang load lần đầu
          final bool showLoading =
              !_isPageReady || (vm.isLoading && vm.warehouses.isEmpty);

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
              ? vm.warehouses
              : vm.warehouses.where((w) {
                  return w.name.toLowerCase().contains(query) ||
                      w.code.toLowerCase().contains(query) ||
                      w.phone.contains(query);
                }).toList();

          return FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // ==================== HEADER ====================
                  AppSliverAppBar(
                    title: context.l10n.warehouse,
                    showBackButton: true,
                    height: 150,
                    actions: [
                      AppAddButton(
                        onPressed: () => context.push(AppRoutes.warehouseAdd),
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
                        AppSummaryCard(
                          label: context.l10n.warehouse_list,
                          value: "${filtered.length}",
                          icon: Icons.warehouse_outlined,
                          color: Colors.blue,
                        ),
                        const SizedBox(height: 14),
                        if (filtered.isEmpty)
                          _buildEmptyState()
                        else
                          ...filtered
                              .map((w) => _buildWarehouseCard(w, cs, theme)),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ==================== WAREHOUSE CARD ====================
  Widget _buildWarehouseCard(
      Warehouse warehouse, ColorScheme cs, ThemeData theme) {
    final bool isActive = warehouse.status.toLowerCase() == 'active';
    final Color statusColor = isActive ? Colors.green : cs.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => showIosActionSheet(
          context: context,
          name: warehouse.name,
          onDelete: () async {
            return await context
                .read<WarehouseViewModel>()
                .deleteWarehouse(warehouse.id);
          },
          onEdit: () {
            context.push(
              AppRoutes.warehouseEdit,
              extra: warehouse,
            );
          },
          onDetail: () {
            context.push(AppRoutes.warehouseDetail, extra: warehouse);
          },
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar / Icon
                  Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: cs.primaryContainer.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      alignment: Alignment.center,
                      child: AppSquareIcon(
                        icon: Icons.warehouse_outlined,
                        status: warehouse.status,
                      )),
                  const SizedBox(width: 16),

                  // Thông tin chính
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                warehouse.name,
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            _buildStatusBadge(
                                warehouse.status, statusColor, theme),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.qr_code_rounded,
                                size: 14, color: cs.outline),
                            const SizedBox(width: 4),
                            Text(
                              "Mã: ${warehouse.code}",
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          warehouse.phone,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Divider
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Divider(
                  height: 1,
                  color: cs.outlineVariant.withOpacity(0.5),
                ),
              ),

              // Địa chỉ + Chi nhánh
              Row(
                children: [
                  Icon(Icons.location_on_rounded, size: 16, color: cs.outline),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "${warehouse.address}, ${warehouse.city}",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.outline,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.business_rounded, size: 16, color: cs.outline),
                  const SizedBox(width: 4),
                  Text(
                    warehouse.branchName,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.outline,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, Color color, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 9,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 80),
        child: Column(
          children: [
            Icon(Icons.warehouse_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "Không tìm thấy kho hàng nào",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
