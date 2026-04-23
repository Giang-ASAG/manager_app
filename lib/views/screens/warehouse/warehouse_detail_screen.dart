import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:manager/core/router/app_routes.dart';
import 'package:manager/data/models/warehouse.dart';
import 'package:manager/viewmodels/warehouse_viewmodel.dart';
import 'package:manager/views/widgets/action_bottom_buttons.dart';
import 'package:manager/views/widgets/app_snackbar.dart';
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
        AppSnackbar.showSuccess(context, 'Đã xóa kho ${w.name}');
        context.pop();
      }
    } catch (e) {
      if (mounted) AppSnackbar.showError(context, 'Lỗi: $e');
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
        // DetailScaffold tự xử lý loading state trong lần đầu.
        // Nếu sau khi load xong mà vẫn null → hiển thị not-found.
        return DetailScaffold(
          appBarTitle: 'Chi tiết kho hàng',
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
      editText: 'Chỉnh sửa',
      deleteText: 'Xóa kho',
      onDelete: () => showPopup(
        context: context,
        onOkPressed: () => _onConfirmDelete(w),
        content:
            'Bạn có chắc chắn muốn xóa kho "${w.name}"? Hành động này không thể hoàn tác.',
        title: 'Xác nhận xóa',
        type: AlertType.warning,
      ),
      onEdit: () => context.push(
        AppRoutes.warehouseEdit.replaceFirst(':id', w.id.toString()),
        extra: w,
      ),
    );
  }
}
