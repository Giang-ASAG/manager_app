import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:manager/core/extensions/l10n_extension.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Consumer<DashboardViewModel>(
        builder: (context, vm, _) {
          return RefreshIndicator(
            color: Theme.of(context).hintColor,
            onRefresh: vm.loadDashboard,
            child: CustomScrollView(
              slivers: [
                AppSliverAppBar(
                  title: context.l10n.dashboard_text,
                  showBackButton: false,
                  height: 80,
                  actions: [
                    AppActions(),
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
                  bottom: null,
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildSectionTitle(context.l10n.quick_actions),
                      const SizedBox(height: 12),
                      _buildQuickActionsGrid(),
                      const SizedBox(height: 24),
                      _buildSectionTitle(context.l10n.recent_actions),
                      const SizedBox(height: 12),
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── SECTIONS ──────────────────────────────────────────────────────────────

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurface,
        letterSpacing: 0.1,
      ),
    );
  }

  // ─── QUICK ACTIONS ─────────────────────────────────────────────────────────

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
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.82,
      ),
      itemCount: actions.length,
      itemBuilder: (context, i) => _buildActionTile(actions[i]),
    );
  }

  Widget _buildActionTile(_ActionItem item) {
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push(item.route),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: item.iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(item.icon, color: item.iconColor, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                item.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  // ✅ Fix: dùng theme thay vì hardcode Color(0xFF3A3F5C)
                  color: Theme.of(context).colorScheme.onSurface,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── SUBWIDGETS ───────────────────────────────────────────────────────────────

class _ShimmerBox extends StatefulWidget {
  final double height;
  final double radius;

  const _ShimmerBox({required this.height, required this.radius});

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 0.9).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .onSurface
              .withOpacity(0.05 * _anim.value),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

// ─── DATA MODELS ─────────────────────────────────────────────────────────────

class _ActionItem {
  final String label;
  final IconData icon;
  final Color iconColor;

  // ✅ Bỏ bgColor — không dùng ở đâu
  final String route;

  const _ActionItem(this.label, this.icon, this.iconColor, this.route);
}
