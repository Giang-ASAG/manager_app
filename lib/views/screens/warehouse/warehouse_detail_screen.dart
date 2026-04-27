import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:manager/core/extensions/l10n_extension.dart';
import 'package:manager/core/router/app_routes.dart';
import 'package:manager/data/models/warehouse.dart';
import 'package:manager/viewmodels/warehouse_viewmodel.dart';
import 'package:manager/views/widgets/action_bottom_buttons.dart';
import 'package:manager/views/widgets/alerts/top_alert.dart';
import 'package:manager/views/widgets/custom_popup.dart';
import 'package:manager/views/widgets/detail/detail_status_badge.dart';
import 'package:provider/provider.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

class WarehouseDetailScreen extends StatefulWidget {
  final Warehouse warehouse;

  const WarehouseDetailScreen({super.key, required this.warehouse});

  @override
  State<WarehouseDetailScreen> createState() => _WarehouseDetailScreenState();
}

class _WarehouseDetailScreenState extends State<WarehouseDetailScreen> {
  bool _isDeleting = false;

  // Hàm fetch — truyền vào DetailScaffold.onRefresh
  Future<void> _fetchData() async {
    //await context.read<WarehouseViewModel>().w;
  }

  Future<void> _onConfirmDelete(Warehouse w) async {
    setState(() => _isDeleting = true);
    try {
      final success =
          await context.read<WarehouseViewModel>().deleteWarehouse(w.id);
      if (mounted && success) {
        TopAlert.success(
            context,
            context.l10n.action_success(context.l10n.common_delete,
                "${context.l10n.warehouse} ${w.name}"));
        context.pop();
      }
    } catch (e) {
      if (mounted) TopAlert.error(context, 'Lỗi: $e');
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Selector<WarehouseViewModel, Warehouse?>(
      selector: (_, vm) => vm.warehouses.cast<Warehouse?>().firstWhere(
            (w) => w?.id == widget.warehouse.id,
            orElse: () => null,
          ),
      builder: (context, warehouse, _) {
        return DetailScaffold(
          appBarTitle: context.l10n.warehouse_detail,
          onRefresh: _fetchData,
          bottomBar: warehouse == null
              ? null
              : _buildBottomActions(context, warehouse),
          slivers: warehouse == null
              ? [_buildNotFound()]
              : _buildContent(context, warehouse),
        );
      },
    );
  }

  List<Widget> _buildContent(BuildContext context, Warehouse w) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isActive = w.status.toLowerCase() == 'active';

    return [
      // ── Hero Card ─────────────────────────────────────────────
      SliverToBoxAdapter(
        child: DetailHeroCard(
          icon: Icons.warehouse_rounded,
          title: w.name,
          subtitle: DetailStatusBadge(
            status: StatusConfig.activeInactive(isActive),
          ),
        ),
      ),

      // ── Thông tin liên hệ ─────────────────────────────────────
      SliverToBoxAdapter(
        child: DetailInfoSection(
          title: 'Thông tin liên hệ',
          children: [
            DetailInfoRow(
              icon: Icons.phone_rounded,
              label: 'Điện thoại',
              value: w.phone,
            ),
          ],
        ),
      ),

      // ── Vị trí địa lý ─────────────────────────────────────────
      SliverToBoxAdapter(
        child: DetailInfoSection(
          title: 'Vị trí địa lý',
          children: [
            DetailInfoRow(
              icon: Icons.location_on_rounded,
              label: 'Địa chỉ',
              value: w.address,
            ),
            DetailInfoRow(
              icon: Icons.location_city_rounded,
              label: 'Thành phố',
              value: w.city,
            ),
          ],
        ),
      ),

      // ── Quản trị hệ thống ──────────────────────────────────────
      SliverToBoxAdapter(
        child: DetailInfoSection(
          title: 'Quản trị hệ thống',
          children: [
            DetailInfoRow(
              icon: Icons.qr_code_rounded,
              label: 'Mã định danh',
              value: w.code,
            ),
            DetailInfoRow(
              icon: Icons.business_rounded,
              label: 'Chi nhánh',
              value: w.branchName,
            ),
          ],
        ),
      ),

      // ── Ngày khởi tạo ─────────────────────────────────────────
      if (w.createdAt != null)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            child: Text(
              'Ngày khởi tạo: ${w.createdAt}',
              style: textTheme.bodySmall?.copyWith(color: cs.outline),
            ),
          ),
        ),
    ];
  }

  Widget _buildNotFound() {
    return const SliverFillRemaining(
      child: Center(child: Text('Dữ liệu không tồn tại hoặc đã bị xóa')),
    );
  }

  Widget _buildBottomActions(BuildContext context, Warehouse w) {
    return ActionBottomButtons(
      isDeleting: _isDeleting,
      editText: context.l10n.warehouse_edit,
      deleteText: context.l10n.warehouse_delete,
      onDelete: () => showPopup(
        context: context,
        onCancelPressed: () {},
        onOkPressed: () => _onConfirmDelete(w),
        content: context.l10n.confirmDeleteItem(w.name.toLowerCase()),
        title: context.l10n.common_confirm,
        type: AlertType.warning,
      ),
      onEdit: () => context.push(
        AppRoutes.warehouseEdit.replaceFirst(':id', w.id.toString()),
        extra: w,
      ),
    );
  }
}
