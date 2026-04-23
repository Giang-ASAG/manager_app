import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:manager/core/router/app_routes.dart';
import 'package:manager/core/utils/app_responsive.dart';
import 'package:manager/data/models/branch.dart';
import 'package:manager/viewmodels/branch_viewmodel.dart';
import 'package:manager/views/widgets/app_search_field.dart';
import 'package:manager/views/widgets/app_sliver_app_bar.dart';
import 'package:manager/views/widgets/ios_action_sheet.dart';
import 'package:manager/views/widgets/shared/app_add_button.dart';
import 'package:manager/views/widgets/shared/app_square_icon.dart';
import 'package:manager/views/widgets/shared/app_summary_card.dart';
import 'package:provider/provider.dart';

class BranchesListScreen extends StatefulWidget {
  const BranchesListScreen({super.key});

  @override
  State<BranchesListScreen> createState() => _BranchesListScreenState();
}

class _BranchesListScreenState extends State<BranchesListScreen>
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
      context.read<BranchViewModel>().fetchBranches();
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
    await context.read<BranchViewModel>().fetchBranches();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Consumer<BranchViewModel>(
          builder: (_, vm, __) {
            final bool showLoading =
                !_isPageReady || (vm.isLoading && vm.branches.isEmpty);

            if (showLoading) {
              return Center(
                child: LoadingAnimationWidget.dotsTriangle(
                  color: cs.primary,
                  size: 32,
                ),
              );
            }

            final query = searchController.text.trim().toLowerCase();
            final filteredBranches = query.isEmpty
                ? vm.branches
                : vm.branches
                .where((b) =>
            b.name.toLowerCase().contains(query) ||
                b.code.toLowerCase().contains(query))
                .toList();

            return FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    AppSliverAppBar(
                      title: 'Chi nhánh',
                      showBackButton: true,
                      height: 150,
                      actions: [
                        AppAddButton(
                          onPressed: () => context.push(AppRoutes.branchAdd),
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
                          _buildSectionTitle(theme, cs, filteredBranches.length),
                          SizedBox(height: context.rh(16)),
                          if (filteredBranches.isEmpty)
                            _buildEmptyState(cs, theme)
                          else
                            ...filteredBranches.map(
                                  (b) => _buildBranchCard(b, cs, theme),
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

  // ─── Section Title ────────────────────────────────────────────────────────
  Widget _buildSectionTitle(ThemeData theme, ColorScheme cs, int count) {
    return Row(
      children: [
        SizedBox(width: context.rw(8)),
        Expanded(
          child: AppSummaryCard(
            label: 'Danh sách chi nhánh',
            value: "$count",
            icon: Icons.store_rounded,
            color: Colors.orange,
          ),
        ),
        SizedBox(width: context.rw(8)),
      ],
    );
  }

  // ─── Branch Card ──────────────────────────────────────────────────────────
  Widget _buildBranchCard(Branch b, ColorScheme cs, ThemeData theme) {
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
            spreadRadius: 0,
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
            name: b.name,
            onEdit: () => context.push(AppRoutes.branchEdit, extra: b),
            onDetail: () => context.push(AppRoutes.branchDetail, extra: b),
            onDelete: () async =>
                context.read<BranchViewModel>().deleteBranch(b.id),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.rw(16),
              vertical: context.rh(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSquareIcon(
                  icon: Icons.store_rounded,
                  status: b.status,
                ),
                SizedBox(width: context.rw(14)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              b.name,
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
                          _buildStatusBadge(b.status, cs, theme),
                        ],
                      ),
                      SizedBox(height: context.rh(4)),
                      _buildInfoChip(
                        icon: Icons.tag_rounded,
                        text: b.code,
                        cs: cs,
                        theme: theme,
                      ),
                      if (_hasSubInfo(b)) ...[
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: context.rh(8)),
                          child: Divider(
                            height: 1,
                            color: cs.outlineVariant.withOpacity(0.4),
                          ),
                        ),
                        _buildSubInfo(b, cs, theme),
                      ],
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

  bool _hasSubInfo(Branch b) =>
      (b.email != null && b.email!.isNotEmpty) ||
          (b.phone != null && b.phone!.isNotEmpty) ||
          (b.address != null && b.address!.isNotEmpty);

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

  Widget _buildSubInfo(Branch b, ColorScheme cs, ThemeData theme) {
    final rows = <Widget>[];

    if (b.phone != null && b.phone!.isNotEmpty) {
      rows.add(_buildSubRow(Icons.phone_outlined, b.phone!, cs, theme));
    }
    if (b.email != null && b.email!.isNotEmpty) {
      rows.add(_buildSubRow(Icons.email_outlined, b.email!, cs, theme));
    }
    if (b.address != null && b.address!.isNotEmpty) {
      rows.add(_buildSubRow(Icons.location_on_outlined, b.address!, cs, theme,
          maxLines: 1));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
      rows.expand((w) => [w, SizedBox(height: context.rh(4))]).toList()
        ..removeLast(),
    );
  }

  Widget _buildSubRow(
      IconData icon,
      String text,
      ColorScheme cs,
      ThemeData theme, {
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
        SizedBox(width: context.rw(5)),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontSize: context.sp(11),
              height: 1.4,
            ),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ─── Status Badge ─────────────────────────────────────────────────────────
  Widget _buildStatusBadge(String status, ColorScheme cs, ThemeData theme) {
    final isActive = status.toLowerCase() == 'active';
    final color = isActive ? Colors.green : cs.error;
    final bgColor = isActive
        ? Colors.green.withOpacity(0.2)
        : cs.errorContainer.withOpacity(0.7);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.rw(8),
        vertical: context.rh(3),
      ),
      decoration: BoxDecoration(
        color: bgColor,
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
            isActive ? 'Hoạt động' : 'Dừng',
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

  // ─── Empty State ──────────────────────────────────────────────────────────
  Widget _buildEmptyState(ColorScheme cs, ThemeData theme) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: context.rh(80)),
        child: Column(
          children: [
            Container(
              width: context.rw(88),
              height: context.rw(88),
              decoration: BoxDecoration(
                color: cs.surfaceVariant.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.store_outlined,
                size: context.sp(40),
                color: cs.onSurfaceVariant.withOpacity(0.4),
              ),
            ),
            SizedBox(height: context.rh(20)),
            Text(
              'Không tìm thấy chi nhánh',
              style: theme.textTheme.titleSmall?.copyWith(
                fontSize: context.sp(15),
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: context.rh(6)),
            Text(
              'Thử tìm kiếm với từ khóa khác',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: context.sp(13),
                color: cs.onSurfaceVariant.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}