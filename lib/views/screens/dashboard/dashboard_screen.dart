import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:manager/core/extensions/l10n_extension.dart';
import 'package:manager/core/utils/app_responsive.dart';
import 'package:manager/views/widgets/app_sliver_app_bar.dart';
import 'package:provider/provider.dart';
import 'package:manager/viewmodels/dashboard_viewmodel.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
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
      context.read<DashboardViewModel>().loadDashboard();
    });
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
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await context.read<DashboardViewModel>().loadDashboard();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Consumer<DashboardViewModel>(
        builder: (context, vm, _) {
          final bool showLoading = !_isPageReady || vm.isLoading;

          if (showLoading) {
            return Center(
              child: LoadingAnimationWidget.dotsTriangle(
                color: cs.primary,
                size: 32,
              ),
            );
          }

          return FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  AppSliverAppBar(
                    title: context.l10n.dashboard_text,
                    showBackButton: false,
                    height: 80,
                    actions: [
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [cs.primary, cs.primaryContainer],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.transparent,
                          child: Text(
                            'G',
                            style: TextStyle(
                              color: cs.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  CupertinoSliverRefreshControl(onRefresh: _onRefresh),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildSectionTitle(context.l10n.quick_actions),
                        const SizedBox(height: 16),
                        _buildQuickActionsGrid(),
                        const SizedBox(height: 32),
                        _buildSectionTitle(context.l10n.recent_actions),
                        const SizedBox(height: 12),
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

  Widget _buildSectionTitle(String title) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: cs.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: context.sp(16),
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsGrid() {
    final actions = [
      _ActionItem('Bán hàng', Icons.point_of_sale_rounded,
          const Color(0xFF3A6CF6), '/sales'),
      _ActionItem('Nhập hàng', Icons.inventory_2_rounded,
          const Color(0xFFE07B1A), '/pur'),
      _ActionItem('Quản lý kho', Icons.warehouse_rounded,
          const Color(0xFF0FA37A), '/warehouses'),
      _ActionItem('Chi nhánh', Icons.branding_watermark_rounded,
          const Color(0xFF0FA37A), '/branches'),
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
        crossAxisSpacing: context.rw(12),
        mainAxisSpacing: context.rh(12),
        childAspectRatio: 0.85,
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
    final cs = Theme.of(context).colorScheme;
    return AnimatedScale(
      scale: 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Material(
        color: cs.surface,
        borderRadius: BorderRadius.circular(context.rr(18)),
        elevation: 0,
        shadowColor: cs.shadow.withOpacity(0.06),
        child: InkWell(
          borderRadius: BorderRadius.circular(context.rr(18)),
          onTap: () => context.push(item.route),
          splashColor: item.iconColor.withOpacity(0.12),
          highlightColor: item.iconColor.withOpacity(0.05),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: context.rh(12)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: context.rw(48),
                  height: context.rw(48),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      colors: [
                        item.iconColor.withOpacity(0.2),
                        item.iconColor.withOpacity(0.12),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(context.rr(14)),
                  ),
                  child: Icon(
                    item.icon,
                    color: item.iconColor,
                    size: context.sp(24),
                  ),
                ),
                SizedBox(height: context.rh(10)),
                Text(
                  item.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: context.sp(11.5),
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
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
