import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:manager/core/extensions/l10n_extension.dart';
import 'package:manager/core/utils/app_responsive.dart';
import 'package:manager/views/widgets/app_actions.dart';
import 'package:manager/views/widgets/app_sliver_app_bar.dart';
import 'package:provider/provider.dart';
import 'package:manager/viewmodels/dashboard_viewmodel.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardViewModel>().loadDashboard();
    });
  }

  Future<void> _onRefresh() async {
    await context.read<DashboardViewModel>().loadDashboard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // App Bar - Không rebuild theo VM
          AppSliverAppBar(
            title: context.l10n.dashboard_text,
            showBackButton: false,
            height: 80,
            actions: [
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 16,
                backgroundColor: Theme.of(context).cardColor,
                child: Text(
                  'G',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          // Refresh Control
          CupertinoSliverRefreshControl(onRefresh: _onRefresh),

          // Nội dung chính - Chỉ rebuild khi VM thay đổi
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            sliver: Consumer<DashboardViewModel>(
              builder: (context, vm, _) {
                return SliverList(
                  delegate: SliverChildListDelegate([
                    _buildSectionTitle(context.l10n.quick_actions),
                    const SizedBox(height: 12),
                    _buildQuickActionsGrid(),
                    const SizedBox(height: 24),
                    _buildSectionTitle(context.l10n.recent_actions),
                    const SizedBox(height: 12),

                    // TODO: Thêm Recent Actions sau
                    // vm.recentActivities.isEmpty
                    //     ? _buildEmptyRecent()
                    //     : _buildRecentList(vm.recentActivities),
                  ]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: context.sp(15),
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurface,
        letterSpacing: 0.1,
      ),
    );
  }

  // ─── QUICK ACTIONS GRID ───────────────────────────────────────────────────
  Widget _buildQuickActionsGrid() {
    final actions = [
      _ActionItem('Bán hàng', Icons.point_of_sale_rounded,
          const Color(0xFF3A6CF6), '/sales'),
      _ActionItem('Nhập hàng', Icons.inventory_2_rounded,
          const Color(0xFFE07B1A), '/purchases'),
      _ActionItem('Quản lý kho', Icons.warehouse_rounded,
          const Color(0xFF0FA37A), '/inventory'),
      _ActionItem('Công nợ', Icons.account_balance_wallet_rounded,
          const Color(0xFF7C3AED), '/debt'),
      _ActionItem(context.l10n.product, Icons.category_rounded,
          const Color(0xFF1A9457), '/products'),
      _ActionItem(context.l10n.category, Icons.list_alt_rounded,
          const Color(0xFF3D52B9), '/categories'),
      _ActionItem(context.l10n.customer, Icons.people_alt_rounded,
          const Color(0xFFD63877), '/customers'),
      _ActionItem(context.l10n.supplier, Icons.business_rounded,
          const Color(0xFF9A5234), '/suppliers'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: AppResponsive.of(context).adaptiveCrossAxisCount(
          phone: 4,
          tablet: 6,
        ),
        crossAxisSpacing: context.rw(10),
        mainAxisSpacing: context.rh(10),
        childAspectRatio: 0.82,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) => _buildActionTile(actions[index]),
    );
  }

  Widget _buildActionTile(_ActionItem item) {
    return _QuickActionTile(item: item);
  }
}

// ─── SUB WIDGET ─────────────────────────────────────────────────────────────

class _QuickActionTile extends StatelessWidget {
  final _ActionItem item;

  const _QuickActionTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Material(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(context.rr(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(context.rr(16)),
          onTap: () => context.push(item.route),
          splashColor: item.iconColor.withOpacity(0.15),
          highlightColor: item.iconColor.withOpacity(0.08),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: context.rh(12)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: context.rw(44),
                  height: context.rw(44),
                  decoration: BoxDecoration(
                    color: item.iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(context.rr(13)),
                  ),
                  child: Icon(
                    item.icon,
                    color: item.iconColor,
                    size: context.sp(22),
                  ),
                ),
                SizedBox(height: context.rh(8)),
                Text(
                  item.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: context.sp(11),
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── MODELS ─────────────────────────────────────────────────────────────────

class _ActionItem {
  final String label;
  final IconData icon;
  final Color iconColor;
  final String route;

  const _ActionItem(this.label, this.icon, this.iconColor, this.route);
}
