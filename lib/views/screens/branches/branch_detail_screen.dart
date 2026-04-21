import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:manager/core/router/app_routes.dart';
import 'package:manager/core/utils/app_responsive.dart';
import 'package:manager/data/models/branch.dart';
import 'package:manager/viewmodels/branch_viewmodel.dart';
import 'package:manager/views/widgets/action_bottom_buttons.dart';
import 'package:manager/views/widgets/app_sliver_app_bar.dart';
import 'package:manager/views/widgets/app_snackbar.dart';
import 'package:manager/views/widgets/custom_popup.dart';
import 'package:provider/provider.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

class BranchDetailScreen extends StatefulWidget {
  final Branch branch;

  const BranchDetailScreen({
    super.key,
    required this.branch,
  });

  @override
  State<BranchDetailScreen> createState() => _BranchDetailScreenState();
}

class _BranchDetailScreenState extends State<BranchDetailScreen> {
  bool _isDeleting = false;

  Future<void> _handleDelete() async {
    setState(() => _isDeleting = true);
    try {
      final success =
          await context.read<BranchViewModel>().deleteBranch(widget.branch.id);
      if (mounted && success) {
        AppSnackbar.showSuccess(
          context,
          'Xóa chi nhánh thành công!',
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(
          context,
          'Xóa chi nhánh thất bại!',
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final branch = widget.branch;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          AppSliverAppBar(
            title: 'Chi tiết chi nhánh',
            showBackButton: true,
            height: 120,
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              context.rw(16),
              context.rh(24),
              context.rw(16),
              context.rh(100),
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ===== HEADER =====
                _buildHeader(context, theme, cs, branch),

                SizedBox(height: context.rh(24)),

                // ===== THÔNG TIN CHI NHÁNH =====
                _buildInfoSection(context, theme, cs, branch),

                SizedBox(height: context.rh(24)),

                // ===== LIÊN HỆ =====
                _buildContactSection(context, theme, cs, branch),

                SizedBox(height: context.rh(24)),

                // ===== ĐỊA CHỈ =====
                _buildAddressSection(context, theme, cs, branch),

                SizedBox(height: context.rh(80)),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: ActionBottomButtons(
        isDeleting: _isDeleting,
        editText: 'Chỉnh sửa',
        deleteText: 'Xóa chi nhánh',
        onDelete: () {
          showPopup(
            context: context,
            onOkPressed: _handleDelete,
            onCancelPressed: () {},
            content: 'Bạn có muốn xóa chi nhánh "${branch.name}" không?',
            title: 'Xóa chi nhánh',
            type: AlertType.warning,
          );
        },
        onEdit: () {
          context.push(AppRoutes.branchEdit, extra: branch);
        },
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, ThemeData theme, ColorScheme cs, Branch branch) {
    final isActive = branch.status.toLowerCase() == 'active';

    return Container(
      padding: EdgeInsets.all(context.rw(16)),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: context.rw(80),
                height: context.rw(80),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(context.rr(20)),
                ),
                child: Icon(
                  Icons.location_on_rounded,
                  color: cs.primary,
                  size: context.sp(40),
                ),
              ),
              SizedBox(width: context.rw(16)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      branch.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: context.sp(18),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: context.rh(8)),
                    Container(
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
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(
      BuildContext context, ThemeData theme, ColorScheme cs, Branch branch) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thông tin chi nhánh',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: context.sp(15),
          ),
        ),
        SizedBox(height: context.rh(12)),
        _buildInfoRow(
          context: context,
          theme: theme,
          cs: cs,
          label: 'Mã chi nhánh',
          value: branch.code,
          icon: Icons.tag_rounded,
        ),
        SizedBox(height: context.rh(12)),
        _buildInfoRow(
          context: context,
          theme: theme,
          cs: cs,
          label: 'Trạng thái',
          value: branch.status.toLowerCase() == 'active'
              ? 'Hoạt động'
              : 'Không hoạt động',
          icon: Icons.toggle_on_rounded,
        ),
        if (branch.city != null && branch.city!.isNotEmpty) ...[
          SizedBox(height: context.rh(12)),
          _buildInfoRow(
            context: context,
            theme: theme,
            cs: cs,
            label: 'Thành phố',
            value: branch.city!,
            icon: Icons.domain_rounded,
          ),
        ],
      ],
    );
  }

  Widget _buildContactSection(
      BuildContext context, ThemeData theme, ColorScheme cs, Branch branch) {
    final hasEmail = branch.email != null && branch.email!.isNotEmpty;
    final hasPhone = branch.phone != null && branch.phone!.isNotEmpty;

    if (!hasEmail && !hasPhone) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Liên hệ',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: context.sp(15),
          ),
        ),
        SizedBox(height: context.rh(12)),
        if (hasPhone)
          _buildInfoRow(
            context: context,
            theme: theme,
            cs: cs,
            label: 'Điện thoại',
            value: branch.phone!,
            icon: Icons.phone_rounded,
          ),
        if (hasEmail) ...[
          SizedBox(height: context.rh(12)),
          _buildInfoRow(
            context: context,
            theme: theme,
            cs: cs,
            label: 'Email',
            value: branch.email!,
            icon: Icons.email_rounded,
          ),
        ],
      ],
    );
  }

  Widget _buildAddressSection(
      BuildContext context, ThemeData theme, ColorScheme cs, Branch branch) {
    if (branch.address == null || branch.address!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Địa chỉ',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: context.sp(15),
          ),
        ),
        SizedBox(height: context.rh(12)),
        Container(
          padding: EdgeInsets.all(context.rw(12)),
          decoration: BoxDecoration(
            color: cs.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(context.rr(12)),
            border: Border.all(color: cs.outlineVariant.withOpacity(0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.home_rounded,
                color: cs.primary,
                size: context.sp(20),
              ),
              SizedBox(width: context.rw(12)),
              Expanded(
                child: Text(
                  branch.address!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required BuildContext context,
    required ThemeData theme,
    required ColorScheme cs,
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.all(context.rw(12)),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(context.rr(12)),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: cs.primary,
            size: context.sp(20),
          ),
          SizedBox(width: context.rw(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontSize: context.sp(12),
                  ),
                ),
                SizedBox(height: context.rh(4)),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: context.sp(14),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
