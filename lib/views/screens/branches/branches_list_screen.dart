import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:manager/core/router/app_routes.dart';
import 'package:manager/core/utils/app_responsive.dart';
import 'package:manager/data/models/branch.dart';
import 'package:manager/viewmodels/branch_viewmodel.dart';
import 'package:manager/views/widgets/app_search_field.dart';
import 'package:manager/views/widgets/app_sliver_app_bar.dart';
import 'package:manager/views/widgets/ios_action_sheet.dart';
import 'package:manager/views/widgets/shared/app_add_button.dart';
import 'package:provider/provider.dart';

class BranchesListScreen extends StatefulWidget {
  const BranchesListScreen({super.key});

  @override
  State<BranchesListScreen> createState() => _BranchesListScreenState();
}

class _BranchesListScreenState extends State<BranchesListScreen> {
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BranchViewModel>().fetchBranches();
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
        body: Consumer<BranchViewModel>(
          builder: (_, vm, __) {
            if (vm.isLoading && vm.branches.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            final query = searchController.text.trim().toLowerCase();
            final filteredBranches = query.isEmpty
                ? vm.branches
                : vm.branches
                    .where((b) =>
                        b.name.toLowerCase().contains(query) ||
                        b.code.toLowerCase().contains(query))
                    .toList();

            return CustomScrollView(
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
                      _buildSectionTitle(theme, filteredBranches.length),
                      const SizedBox(height: 12),
                      if (filteredBranches.isEmpty)
                        _buildEmptyState()
                      else
                        ...filteredBranches.map(
                          (b) => _buildBranchCard(b, cs, theme),
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
    await context.read<BranchViewModel>().fetchBranches();
  }

  Widget _buildSectionTitle(ThemeData theme, int count) {
    return Text(
      'Danh sách chi nhánh ($count)',
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        fontSize: context.sp(15),
      ),
    );
  }

  Widget _buildBranchCard(Branch b, ColorScheme cs, ThemeData theme) {
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
          name: b.name,
          onEdit: () {
            context.push(AppRoutes.branchEdit, extra: b);
          },
          onDetail: () {
            context.push(AppRoutes.branchDetail, extra: b);
          },
          onDelete: () async {
            return context.read<BranchViewModel>().deleteBranch(b.id);
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
            Icons.location_on_rounded,
            color: cs.primary,
            size: context.sp(28),
          ),
        ),

        // ===== TITLE & INFO =====
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    b.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: context.sp(15),
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Mã: ${b.code}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontSize: context.sp(12),
                    ),
                  ),
                ],
              ),
            ),
            _buildStatusBadge(b.status, cs, theme),
          ],
        ),

        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            if (b.email != null && b.email!.isNotEmpty)
              Text(
                'Email: ${b.email}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontSize: context.sp(11),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            if (b.phone != null && b.phone!.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: context.rh(4)),
                child: Text(
                  'SĐT: ${b.phone}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontSize: context.sp(11),
                  ),
                ),
              ),
            if (b.address != null && b.address!.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: context.rh(4)),
                child: Text(
                  'Địa chỉ: ${b.address}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontSize: context.sp(11),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, ColorScheme cs, ThemeData theme) {
    final isActive = status.toLowerCase() == 'active';
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.rw(12),
        vertical: context.rh(6),
      ),
      decoration: BoxDecoration(
        color: isActive
            ? cs.primaryContainer.withOpacity(0.6)
            : cs.errorContainer.withOpacity(0.6),
        borderRadius: BorderRadius.circular(context.rr(8)),
      ),
      child: Text(
        isActive ? 'Hoạt động' : 'Không hoạt động',
        style: theme.textTheme.labelSmall?.copyWith(
          color: isActive ? cs.primary : cs.error,
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
              Icons.location_on_outlined,
              size: context.sp(80),
              color: Colors.grey.shade300,
            ),
            SizedBox(height: context.rh(16)),
            Text(
              'Không tìm thấy chi nhánh',
              style: TextStyle(
                fontSize: context.sp(16),
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: context.rh(8)),
            Text(
              'Thử tìm kiếm với từ khóa khác',
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
