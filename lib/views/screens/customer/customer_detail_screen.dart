import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:manager/core/extensions/l10n_extension.dart';
import 'package:manager/core/router/app_routes.dart';
import 'package:manager/core/utils/app_responsive.dart';
import 'package:manager/data/models/customer.dart';
import 'package:manager/viewmodels/customer_viewmodel.dart';
import 'package:manager/views/widgets/action_bottom_buttons.dart';
import 'package:manager/views/widgets/alerts/top_alert.dart';
import 'package:manager/views/widgets/app_snackbar.dart';
import 'package:manager/views/widgets/custom_popup.dart';

import 'package:manager/views/widgets/detail/detail_status_badge.dart';
import 'package:provider/provider.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

class CustomerDetailScreen extends StatefulWidget {
  final Customer customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  final _currencyFormat = NumberFormat('#,##0', 'vi_VN');
  bool _isDeleting = false;

  Future<void> _fetchData() async {
    // Tải lại danh sách khách hàng để cập nhật dữ liệu mới nhất
    await context.read<CustomerViewmodel>().fetchCustomers();
  }

  Future<void> _handleDelete(Customer c) async {
    setState(() => _isDeleting = true);
    try {
      final success =
          await context.read<CustomerViewmodel>().deleteCustomer(c.id);
      if (mounted && success) {
        TopAlert.success(
            context,
            context.l10n.action_success(context.l10n.common_delete,
                context.l10n.customer.toLowerCase()));
        context.pop();
      }
    } catch (e) {
      if (mounted) TopAlert.error(context, "Không thể xóa khách hàng này");
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Selector<CustomerViewmodel, Customer?>(
      selector: (_, vm) => vm.customers.cast<Customer?>().firstWhere(
            (c) => c?.id == widget.customer.id,
            orElse: () => null,
          ),
      builder: (context, customer, _) {
        return DetailScaffold(
          appBarTitle: context.l10n.customer_detail,
          onRefresh: _fetchData,
          bottomBar: customer == null ? null : _buildBottomActions(customer),
          slivers: customer == null
              ? [_buildNotFound()]
              : _buildContent(context, customer),
        );
      },
    );
  }

  List<Widget> _buildContent(BuildContext context, Customer c) {
    final cs = Theme.of(context).colorScheme;
    final isActive = c.status.toLowerCase() == 'active';

    return [
      // Hero Card - dùng DetailHeroCard + DetailStatusBadge
      SliverToBoxAdapter(
        child: DetailHeroCard(
          icon: Icons.person_rounded,
          title: c.name,
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
              icon: Icons.phone_rounded,
              label: 'Số điện thoại',
              value: c.phone,
            ),
            DetailInfoRow(
              icon: Icons.email_rounded,
              label: 'Email',
              value: c.email,
            ),
          ],
        ),
      ),

      // Công nợ & Thống kê (dùng DetailInfoSection, có thể custom valueWidget)
      SliverToBoxAdapter(
        child: DetailInfoSection(
          title: 'Địa chỉ',
          children: [
            // Giả sử customer có trường debt, totalOrders, revenue
            DetailInfoRow(
              icon: Icons.location_on_rounded,
              label: 'Địa chỉ cụ thế',
              value: c.address,
            ),
            DetailInfoRow(
              icon: Icons.location_on_rounded,
              label: 'Tỉnh & Thành phố',
              value: c.city,
            ),
          ],
        ),
      ),

      // Ngày tạo
      if (c.createdAt != null)
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: context.rw(24), vertical: context.rh(4)),
            child: Text(
              'Khách hàng thân thiết từ: ${c.createdAt}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: cs.outline),
              textAlign: TextAlign.center,
            ),
          ),
        ),
    ];
  }

  Widget _buildNotFound() {
    return const SliverFillRemaining(
      child: Center(child: Text('Không tìm thấy khách hàng')),
    );
  }

  Widget _buildBottomActions(Customer c) {
    return ActionBottomButtons(
      isDeleting: _isDeleting,
      editText: context.l10n.customer_edit,
      deleteText: context.l10n.customer_delete,
      onDelete: () => showPopup(
        context: context,
        title: "Xóa khách hàng",
        content:
            "Mọi dữ liệu về khách hàng ${c.name} sẽ biến mất. Bạn chắc chứ?",
        type: AlertType.warning,
        onOkPressed: () => _handleDelete(c),
      ),
      onEdit: () => context.push(AppRoutes.customerEdit, extra: c),
    );
  }
}
