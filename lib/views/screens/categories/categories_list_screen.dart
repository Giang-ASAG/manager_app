import 'package:flutter/cupertino.dart'; // ← Thêm import này
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:manager/core/extensions/l10n_extension.dart';
import 'package:manager/core/router/app_routes.dart';
import 'package:manager/views/widgets/app_search_field.dart';
import 'package:manager/views/widgets/app_snackbar.dart';
import 'package:manager/views/widgets/custom_popup.dart';
import 'package:provider/provider.dart';
import 'package:manager/viewmodels/categories_viewmodel.dart';
import 'package:manager/views/widgets/app_sliver_app_bar.dart';
import 'package:manager/views/widgets/shared/app_summary_card.dart';
import 'package:manager/views/widgets/shared/app_add_button.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({super.key});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoriesViewModel>().fetchCategories();
    });

    // Search listener
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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Consumer<CategoriesViewModel>(
        builder: (_, vm, __) {
          if (vm.isLoading && vm.categories.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final query = searchController.text.trim().toLowerCase();
          final filtered = query.isEmpty
              ? vm.categories
              : vm.categories
                  .where((c) => c.name.toLowerCase().contains(query))
                  .toList();

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            // Quan trọng cho Cupertino refresh
            slivers: [
              // ==================== APP BAR ====================
              AppSliverAppBar(
                title: context.l10n.category,
                showBackButton: true,
                height: 150,
                actions: [
                  AppAddButton(
                    onPressed: () => context.push(AppRoutes.categoryAdd),
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
                    const SizedBox(height: 10),
                    _buildSectionTitle(theme, filtered.length),
                    const SizedBox(height: 12),
                    if (filtered.isEmpty)
                      _buildEmptyState()
                    else
                      ...filtered.map((c) => _buildCategoryCard(c, cs, theme)),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Hàm refresh riêng - sạch sẽ và dễ quản lý
  Future<void> _onRefresh() async {
    await context.read<CategoriesViewModel>().fetchCategories();
  }

  // ─── WIDGETS ───────────────────────────────────────────────────────────────

  Widget _buildSectionTitle(ThemeData theme, int count) {
    return Text(
      '${context.l10n.category_list} ($count)',
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildCategoryCard(dynamic category, ColorScheme cs, ThemeData theme) {
    final bool isActive = category.status?.toLowerCase() == 'active';
    final Color statusColor = isActive ? Colors.green : cs.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Theme(
          data: theme.copyWith(
            splashColor: cs.primaryContainer.withOpacity(0.3),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:
                    isActive ? cs.primaryContainer : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isActive ? Icons.folder_rounded : Icons.folder_off_rounded,
                color: isActive ? cs.onPrimaryContainer : cs.outline,
                size: 26,
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    category.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                // Status Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withOpacity(0.2)),
                  ),
                  child: Text(
                    isActive ? "Active" : "Inactive",
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                category.description ?? 'Không có mô tả',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
            trailing: PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded, color: cs.onSurfaceVariant),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              onSelected: (val) async {
                if (val == 'delete') {
                  final confirmed = await showPopup(
                    context: context,
                    type: AlertType.warning,
                    title: "Cảnh báo",
                    content: "Bạn có muốn xóa danh mục này không?",
                    onCancelPressed: () {},
                    onOkPressed: () async {
                      final success = await context
                          .read<CategoriesViewModel>()
                          .deleteCategory(category.id!);
                      if (success) {
                        AppSnackbar.showSuccess(context, "Xóa thành công");
                      } else {
                        AppSnackbar.showError(
                            context, "Xóa thất bại"); // Nên có hàm showError
                      }
                    }, // sẽ xử lý sau khi confirm
                  );
                } else if (val == 'edit') {
                  // TODO: Điều hướng đến trang chỉnh sửa
                  // context.push(AppRoutes.categoryEdit, extra: category);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 20, color: cs.primary),
                      const SizedBox(width: 12),
                      const Text('Chỉnh sửa'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded,
                          size: 20, color: cs.error),
                      const SizedBox(width: 12),
                      Text('Xóa', style: TextStyle(color: cs.error)),
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

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 80),
        child: Column(
          children: [
            Icon(Icons.category_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "Không tìm thấy danh mục nào",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
