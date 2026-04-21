import 'package:flutter/cupertino.dart'; // ← Thêm import này
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:manager/core/extensions/l10n_extension.dart';
import 'package:manager/core/router/app_routes.dart';
import 'package:manager/data/models/supplier.dart';
import 'package:manager/viewmodels/supplier_viewmodel.dart';
import 'package:manager/views/widgets/app_search_field.dart';
import 'package:manager/views/widgets/app_sliver_app_bar.dart';
import 'package:manager/views/widgets/ios_action_sheet.dart';
import 'package:manager/views/widgets/shared/app_add_button.dart';
import 'package:manager/views/widgets/shared/app_summary_card.dart';
import 'package:provider/provider.dart';

class SupplierListScreen extends StatefulWidget {
  const SupplierListScreen({super.key});

  @override
  State<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends State<SupplierListScreen> {
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupplierViewmodel>().fetchSuppliers();
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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Consumer<SupplierViewmodel>(
        builder: (_, vm, __) {
          if (vm.isLoading && vm.suppliers.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final query = searchController.text.trim().toLowerCase();
          final filtered = query.isEmpty
              ? vm.suppliers
              : vm.suppliers.where((s) {
                  return s.name.toLowerCase().contains(query) ||
                      (s.contactPerson?.toLowerCase().contains(query) ??
                          false) ||
                      (s.phone?.contains(query) ?? false);
                }).toList();

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            // Quan trọng cho refresh mượt
            slivers: [
              // ==================== HEADER ====================
              AppSliverAppBar(
                title: context.l10n.supplier,
                showBackButton: true,
                height: 150,
                actions: [
                  AppAddButton(
                    onPressed: () => context.push(AppRoutes.supplierAdd),
                  ),
                ],
                bottom: AppSearchField(
                    controller: searchController), // Dùng widget chuẩn
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
                      label: context.l10n.supplier_list,
                      value: "${filtered.length}",
                      icon: Icons.local_shipping_outlined,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 14),
                    if (filtered.isEmpty)
                      _buildEmptyState()
                    else
                      ...filtered.map((s) => _buildSupplierCard(s, cs, theme)),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Hàm refresh riêng
  Future<void> _onRefresh() async {
    await context.read<SupplierViewmodel>().fetchSuppliers();
  }

  // ==================== SUPPLIER CARD ====================
  Widget _buildSupplierCard(
      Supplier supplier, ColorScheme cs, ThemeData theme) {
    final bool isActive = supplier.status.toLowerCase() == 'active';
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
          name: supplier.name,
          onDelete: () async {
            return await context
                .read<SupplierViewmodel>()
                .deleteSupplier(supplier.id!);
          },
          onEdit: () {
            context.push(AppRoutes.supplierEdit, extra: supplier);
          },
          onDetail: () {
            context.push(AppRoutes.supplierDetail, extra: supplier);
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
                    child: Icon(
                      Icons.business_rounded,
                      color: cs.primary,
                      size: 28,
                    ),
                  ),
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
                                supplier.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: cs.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            _buildStatusBadge(
                                supplier.status, statusColor, theme),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.person_pin_rounded,
                                size: 14, color: cs.outline),
                            const SizedBox(width: 4),
                            Text(
                              "Người liên hệ: ${supplier.contactPerson ?? 'N/A'}",
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          supplier.phone ?? "Không có SĐT",
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

              // Địa chỉ + Nút gọi
              Row(
                children: [
                  Icon(Icons.location_on_rounded, size: 16, color: cs.outline),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "${supplier.address ?? ''}, ${supplier.city ?? ''}"
                          .trim(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.outline,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (supplier.phone != null)
                    Material(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          // TODO: Thêm url_launcher để gọi điện
                          // launchUrl(Uri.parse('tel:${supplier.phone}'));
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.call_rounded,
                            size: 18,
                            color: Colors.green,
                          ),
                        ),
                      ),
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
            Icon(Icons.local_shipping_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "Không tìm thấy nhà cung cấp nào",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
