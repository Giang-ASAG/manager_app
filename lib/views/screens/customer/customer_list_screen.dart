import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:manager/core/extensions/l10n_extension.dart';
import 'package:manager/core/router/app_routes.dart';
import 'package:manager/views/widgets/app_search_field.dart';
import 'package:manager/views/widgets/ios_action_sheet.dart';
import 'package:provider/provider.dart';
import 'package:manager/data/models/customer.dart';
import 'package:manager/viewmodels/customer_viewmodel.dart';
import 'package:manager/views/widgets/app_sliver_app_bar.dart';
import 'package:manager/views/widgets/shared/app_summary_card.dart';
import 'package:manager/views/widgets/shared/app_add_button.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen>
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
      context.read<CustomerViewmodel>().fetchCustomers();
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
    await context.read<CustomerViewmodel>().fetchCustomers();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Consumer<CustomerViewmodel>(
          builder: (_, vm, __) {
            final bool showLoading =
                !_isPageReady || (vm.isLoading && vm.customers.isEmpty);

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
                ? vm.customers
                : vm.customers.where((c) {
              return c.name.toLowerCase().contains(query) ||
                  (c.phone?.contains(query) ?? false) ||
                  (c.email?.toLowerCase().contains(query) ?? false);
            }).toList();

            return FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    AppSliverAppBar(
                      title: context.l10n.customer,
                      showBackButton: true,
                      height: 150,
                      actions: [
                        AppAddButton(
                          onPressed: () => context.push(AppRoutes.customerAdd),
                        ),
                      ],
                      bottom: AppSearchField(controller: searchController),
                    ),
                    CupertinoSliverRefreshControl(onRefresh: _onRefresh),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 80),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          AppSummaryCard(
                            label: context.l10n.customer_list,
                            value: "${filtered.length}",
                            icon: Icons.people_alt_outlined,
                            color: cs.primary,
                          ),
                          const SizedBox(height: 10),
                          if (filtered.isEmpty)
                            _buildEmptyState()
                          else
                            ...filtered
                                .map((c) => _buildCustomerCard(c, cs, theme)),
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

  Widget _buildCustomerCard(
      Customer customer, ColorScheme cs, ThemeData theme) {
    final bool isActive = customer.status.toLowerCase() == 'active';
    final Color statusColor = isActive ? Colors.teal : cs.error;

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
          name: customer.name,
          onDelete: () async {
            return context.read<CustomerViewmodel>().deleteCustomer(customer.id);
          },
          onEdit: () {
            context.push(AppRoutes.customerEdit, extra: customer);
          },
          onDetail: () {
            context.push(AppRoutes.customerDetail, extra: customer);
          },
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [cs.primary, cs.primary.withOpacity(0.7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          customer.name.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: cs.surface,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.circle,
                            color: statusColor,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                customer.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: cs.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                customer.status.toUpperCase(),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.phone_iphone_rounded,
                                size: 16, color: cs.primary),
                            const SizedBox(width: 6),
                            Text(
                              customer.phone ?? "Chưa có SĐT",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Divider(
                    height: 1, color: cs.outlineVariant.withOpacity(0.5)),
              ),
              Row(
                children: [
                  Icon(Icons.location_on_rounded, size: 16, color: cs.outline),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      customer.address ?? "Chưa cập nhật địa chỉ",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.outline,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (customer.phone != null)
                    _buildQuickAction(
                      icon: Icons.call_rounded,
                      color: Colors.green,
                      onTap: () {},
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(Icons.person_search_outlined,
                size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text(
              "Không tìm thấy khách hàng nào",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}