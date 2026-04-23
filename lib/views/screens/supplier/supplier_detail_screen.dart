import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:manager/core/router/app_routes.dart';
import 'package:manager/data/models/supplier.dart';
import 'package:manager/viewmodels/supplier_viewmodel.dart';
import 'package:manager/views/widgets/action_bottom_buttons.dart';
import 'package:manager/views/widgets/app_snackbar.dart';
import 'package:manager/views/widgets/custom_popup.dart';

import 'package:manager/views/widgets/detail/detail_status_badge.dart';
import 'package:provider/provider.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

class SupplierDetailScreen extends StatefulWidget {
  final Supplier supplier;

  const SupplierDetailScreen({super.key, required this.supplier});

  @override
  State<SupplierDetailScreen> createState() => _SupplierDetailScreenState();
}

class _SupplierDetailScreenState extends State<SupplierDetailScreen> {
  bool _isDeleting = false;

  /// Hàm fetch dữ liệu mới – dùng cho pull-to-refresh và lần đầu load
  Future<void> _fetchData() async {
    // Gọi ViewModel để tải lại danh sách nhà cung cấp
    await context.read<SupplierViewmodel>().fetchSuppliers();
  }

  Future<void> _onConfirmDelete(Supplier s) async {
    setState(() => _isDeleting = true);
    try {
      final success =
          await context.read<SupplierViewmodel>().deleteSupplier(s.id!);
      if (mounted && success) {
        AppSnackbar.showSuccess(context, 'Đã xóa nhà cung cấp ${s.name}');
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
    return Selector<SupplierViewmodel, Supplier?>(
      selector: (_, vm) => vm.suppliers.cast<Supplier?>().firstWhere(
            (s) => s?.id == widget.supplier.id,
            orElse: () => null,
          ),
      builder: (context, supplier, _) {
        // DetailScaffold tự xử lý loading state, animation, pull-to-refresh
        return DetailScaffold(
          appBarTitle: 'Chi tiết nhà cung cấp',
          onRefresh: _fetchData,
          bottomBar:
              supplier == null ? null : _buildBottomActions(context, supplier),
          slivers: supplier == null
              ? [_buildNotFound()]
              : _buildContent(context, supplier),
        );
      },
    );
  }

  List<Widget> _buildContent(BuildContext context, Supplier s) {
    final textTheme = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final isActive = s.status.toLowerCase() == 'active';

    return [
      // Hero Card
      SliverToBoxAdapter(
        child: DetailHeroCard(
          icon: Icons.business_rounded,
          title: s.name,
          subtitle: DetailStatusBadge(
            status: StatusConfig.activeInactive(isActive),
          ),
        ),
      ),

      // Thông tin liên hệ
      SliverToBoxAdapter(
        child: DetailInfoSection(
          title: 'Thông tin liên hệ',
          children: [
            DetailInfoRow(
              icon: Icons.person_outline_rounded,
              label: 'Người đại diện',
              value: s.contactPerson,
            ),
            DetailInfoRow(
              icon: Icons.phone_rounded,
              label: 'Số điện thoại',
              value: s.phone,
            ),
            DetailInfoRow(
              icon: Icons.email_rounded,
              label: 'Email',
              value: s.email,
            ),
          ],
        ),
      ),

      // Địa chỉ & vị trí
      SliverToBoxAdapter(
        child: DetailInfoSection(
          title: 'Địa chỉ',
          children: [
            DetailInfoRow(
              icon: Icons.location_on_rounded,
              label: 'Địa chỉ',
              value: s.address,
            ),
            // Có thể thêm mã số thuế, website nếu cần
            if (s.contactPerson != null && s.contactPerson!.isNotEmpty)
              DetailInfoRow(
                icon: Icons.receipt_rounded,
                label: 'Tỉnh & Thành phố',
                value: s.city,
              ),
          ],
        ),
      ),

      // Ngày hợp tác
      if (s.createdAt != null)
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            child: Text(
              'Ngày hợp tác: ${s.createdAt}',
              style: textTheme.bodySmall?.copyWith(color: cs.outline),
              textAlign: TextAlign.center,
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

  Widget _buildBottomActions(BuildContext context, Supplier s) {
    return ActionBottomButtons(
      isDeleting: _isDeleting,
      editText: 'Chỉnh sửa',
      deleteText: 'Xóa nhà cung cấp',
      onDelete: () => showPopup(
        context: context,
        onOkPressed: () => _onConfirmDelete(s),
        content:
            'Bạn có chắc chắn muốn xóa nhà cung cấp "${s.name}"? Hành động này không thể hoàn tác.',
        title: 'Xác nhận xóa',
        type: AlertType.warning,
      ),
      onEdit: () => context.push(AppRoutes.supplierEdit, extra: s),
    );
  }
}
