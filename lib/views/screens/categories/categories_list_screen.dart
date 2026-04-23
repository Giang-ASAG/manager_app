import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:manager/core/extensions/l10n_extension.dart';
import 'package:manager/core/router/app_routes.dart';
import 'package:manager/data/models/category.dart';
import 'package:manager/views/widgets/app_search_field.dart';
import 'package:manager/views/widgets/ios_action_sheet.dart';
import 'package:manager/views/widgets/shared/app_square_icon.dart';
import 'package:manager/views/widgets/shared/app_summary_card.dart';
import 'package:provider/provider.dart';
import 'package:manager/viewmodels/categories_viewmodel.dart';
import 'package:manager/views/widgets/app_sliver_app_bar.dart';
import 'package:manager/views/widgets/shared/app_add_button.dart';

class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({super.key});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen>
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
      context.read<CategoriesViewModel>().fetchCategories();
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
    await context.read<CategoriesViewModel>().fetchCategories();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Consumer<CategoriesViewModel>(
          builder: (_, vm, __) {
            final bool showLoading =
                !_isPageReady || (vm.isLoading && vm.categories.isEmpty);

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
                ? vm.categories
                : vm.categories
                .where((c) => c.name.toLowerCase().contains(query))
                .toList();

            return FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
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
                    CupertinoSliverRefreshControl(onRefresh: _onRefresh),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 80),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildSectionTitle(theme, filtered.length),
                          const SizedBox(height: 12),
                          if (filtered.isEmpty)
                            _buildEmptyState()
                          else
                            ...filtered
                                .map((c) => _buildCategoryCard(c, cs, theme)),
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
      label: context.l10n.category_list,
      value: "$count",
      icon: Icons.category_outlined,
      color: Colors.orange,
    );
  }

  Widget _buildCategoryCard(
      Category category, ColorScheme cs, ThemeData theme) {
    final isActive = category.status?.toLowerCase() == 'active';
    final statusColor = isActive ? Colors.green : cs.error;

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
      child: ListTile(
        onTap: () => showIosActionSheet(
          context: context,
          name: category.name,
          onDelete: () async {
            return context
                .read<CategoriesViewModel>()
                .deleteCategory(category.id);
          },
          onEdit: () {},
          onDetail: () {},
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

        leading: Container(
          child: AppSquareIcon(icon: Icons.category_rounded),
        ),

        title: Row(
          children: [
            Expanded(
              child: Text(
                category.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildStatusBadge(theme, statusColor, isActive),
          ],
        ),

        subtitle: Text(
          category.description ?? 'Không có mô tả',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ThemeData theme, Color color, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isActive ? "Active" : "Inactive",
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
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
            Text("Không tìm thấy danh mục nào"),
          ],
        ),
      ),
    );
  }
}