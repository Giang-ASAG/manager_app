import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:manager/core/router/app_routes.dart';

import 'package:manager/data/models/branch.dart';
import 'package:manager/viewmodels/branch_viewmodel.dart';
import 'package:manager/views/widgets/action_bottom_buttons.dart';
import 'package:manager/views/widgets/app_snackbar.dart';
import 'package:manager/views/widgets/custom_popup.dart';
import 'package:manager/views/widgets/detail/detail_status_badge.dart';
import 'package:provider/provider.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

class BranchDetailScreen extends StatefulWidget {
  final Branch branch;

  const BranchDetailScreen({super.key, required this.branch});

  @override
  State<BranchDetailScreen> createState() => _BranchDetailScreenState();
}

class _BranchDetailScreenState extends State<BranchDetailScreen> {
  bool _isDeleting = false;

  Future<void> _handleNull() async {}

  Future<void> _handleDelete(Branch b) async {
    setState(() => _isDeleting = true);
    try {
      final success = await context.read<BranchViewModel>().deleteBranch(b.id);
      if (mounted && success) {
        AppSnackbar.showSuccess(context, 'Đã xóa chi nhánh ${b.name}');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, 'Không thể xóa chi nhánh');
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  // --- PHẦN SỬA LẠI TRONG BUILD METHOD ---
  @override
  Widget build(BuildContext context) {
    return Selector<BranchViewModel, Branch?>(
      selector: (_, vm) {
        try {
          return vm.branches.firstWhere((b) => b.id == widget.branch.id);
        } catch (e) {
          // Nếu không tìm thấy, trả về null thay vì dùng orElse gây lỗi type
          return null;
        }
      },
      builder: (context, branch, _) {
        // Nếu branch bị null (đã xóa), ta xử lý quay lại trang trước
        if (branch == null && !_isDeleting) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.pop();
          });
        }

        return DetailScaffold(
          appBarTitle: 'Chi tiết chi nhánh',
          onRefresh: () async {
            // Thực hiện logic refresh thực tế tại đây nếu cần
          },
          bottomBar:
              branch == null ? null : _buildBottomActions(context, branch),
          slivers: branch == null
              ? [_buildNotFound()]
              : _buildContent(context, branch),
        );
      },
    );
  }

  List<Widget> _buildContent(BuildContext context, Branch b) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isActive = b.status.toLowerCase() == 'active';

    return [
      // ── Hero Card ─────────────────────────────────────────────
      SliverToBoxAdapter(
        child: DetailHeroCard(
          icon: Icons.storefront_rounded,
          title: b.name,
          subtitle: DetailStatusBadge(
            status: StatusConfig.activeInactive(isActive),
          ),
        ),
      ),

      // ── Thông tin vận hành ────────────────────────────────────
      SliverToBoxAdapter(
        child: DetailInfoSection(
          title: 'Thông tin vận hành',
          children: [
            DetailInfoRow(
              icon: Icons.qr_code_rounded,
              label: 'Mã chi nhánh',
              value: b.code,
            ),
            DetailInfoRow(
              icon: Icons.location_city_rounded,
              label: 'Thành phố',
              value: b.city,
            ),
          ],
        ),
      ),

      // ── Liên hệ & Địa chỉ ─────────────────────────────────────
      SliverToBoxAdapter(
        child: DetailInfoSection(
          title: 'Liên hệ & Địa chỉ',
          children: [
            DetailInfoRow(
              icon: Icons.phone_rounded,
              label: 'Số điện thoại',
              value: b.phone,
            ),
            DetailInfoRow(
              icon: Icons.email_rounded,
              label: 'Email',
              value: b.email,
            ),
            DetailInfoRow(
              icon: Icons.location_on_rounded,
              label: 'Địa chỉ',
              value: b.address,
            ),
          ],
        ),
      ),

      // ── Ngày tạo ─────────────────────────────────────────────
      // if (b.createdAt != null)
      //   SliverToBoxAdapter(
      //     child: Padding(
      //       padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      //       child: Text(
      //         'Ngày tạo: ${b.}',
      //         style: textTheme.bodySmall?.copyWith(color: cs.outline),
      //         textAlign: TextAlign.center,
      //       ),
      //     ),
      //   ),
    ];
  }

  Widget _buildNotFound() {
    return const SliverFillRemaining(
      child: Center(child: Text('Không tìm thấy chi nhánh')),
    );
  }

  Widget _buildBottomActions(BuildContext context, Branch b) {
    return ActionBottomButtons(
      isDeleting: _isDeleting,
      editText: 'Chỉnh sửa',
      deleteText: 'Xóa chi nhánh',
      onDelete: () => showPopup(
        context: context,
        title: 'Xác nhận xóa',
        content:
            'Bạn có chắc chắn muốn xóa chi nhánh "${b.name}"? Hành động này không thể hoàn tác.',
        type: AlertType.warning,
        onOkPressed: () => _handleDelete(b),
      ),

      /// ⚠️ FIX QUAN TRỌNG (tránh lỗi :id)
      onEdit: () => context.pushNamed(
        'branchEdit',
        pathParameters: {'id': b.id.toString()},
        extra: b,
      ),
    );
  }
}
