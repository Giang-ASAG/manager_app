// lib/views/widgets/detail/
// Gồm 5 file:
//   detail_hero_card.dart
//   detail_info_section.dart
//   detail_info_row.dart
//   detail_status_badge.dart
//   detail_scaffold.dart

// ─────────────────────────────────────────────────────────────────
// FILE: lib/views/widgets/detail/detail_status_badge.dart
// ─────────────────────────────────────────────────────────────────

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:manager/core/utils/app_responsive.dart';
import 'package:manager/views/widgets/app_sliver_app_bar.dart';

/// Model mô tả một trạng thái.
/// Dùng để truyền vào [DetailStatusBadge] và [DetailHeroCard].
class StatusConfig {
  final String label;
  final Color color;

  const StatusConfig({required this.label, required this.color});

  /// Factory helper: active / inactive
  static StatusConfig activeInactive(bool isActive) => StatusConfig(
        label: isActive ? 'ĐANG HOẠT ĐỘNG' : 'TẠM NGƯNG',
        color: isActive ? Colors.green : Colors.orange,
      );

  /// Factory helper: paid / unpaid
  static StatusConfig paidUnpaid(bool isPaid) => StatusConfig(
        label: isPaid ? 'ĐÃ THANH TOÁN' : 'CHƯA THANH TOÁN',
        color: isPaid ? Colors.green : Colors.red,
      );
}

class DetailStatusBadge extends StatelessWidget {
  final StatusConfig status;

  const DetailStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = status.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// FILE: lib/views/widgets/detail/detail_info_row.dart
// ─────────────────────────────────────────────────────────────────

class DetailInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;

  /// [value]: text thường
  final String? value;

  /// [valueWidget]: override bằng widget tuỳ chỉnh (vd: chip, link, ...)
  final Widget? valueWidget;

  const DetailInfoRow({
    super.key,
    required this.icon,
    required this.label,
    this.value,
    this.valueWidget,
  }) : assert(
          value != null || valueWidget != null,
          'Cần truyền value hoặc valueWidget',
        );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: cs.onSurfaceVariant),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
          ),
          const Spacer(),
          if (valueWidget != null)
            valueWidget!
          else
            Expanded(
              flex: 2,
              child: Text(
                (value?.isEmpty ?? true) ? '—' : value!,
                textAlign: TextAlign.end,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// FILE: lib/views/widgets/detail/detail_info_section.dart
// ─────────────────────────────────────────────────────────────────

class DetailInfoSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  /// Thêm padding bottom phía dưới section (default 12)
  final double bottomSpacing;

  const DetailInfoSection({
    super.key,
    required this.title,
    required this.children,
    this.bottomSpacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: EdgeInsets.fromLTRB(
        context.rw(16),
        0,
        context.rw(16),
        context.rh(bottomSpacing),
      ),
      padding: EdgeInsets.all(context.rw(16)),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: cs.primary,
              letterSpacing: 0.5,
            ),
          ),
          const Divider(height: 24),
          ...children,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// FILE: lib/views/widgets/detail/detail_hero_card.dart
// ─────────────────────────────────────────────────────────────────

class DetailHeroCard extends StatelessWidget {
  final IconData icon;
  final String title;

  /// Hiển thị dưới title (có thể là StatusBadge hoặc text phụ)
  final Widget? subtitle;

  /// Màu nền icon (default: primaryContainer)
  final Color? iconBgColor;

  /// Màu icon (default: primary)
  final Color? iconColor;

  const DetailHeroCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconBgColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: context.rw(16),
        vertical: context.rh(8),
      ),
      padding: EdgeInsets.all(context.rw(20)),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(context.rr(24)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(context.rw(12)),
            decoration: BoxDecoration(
              color: (iconBgColor ?? cs.primaryContainer).withOpacity(0.4),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor ?? cs.primary,
              size: 28,
            ),
          ),
          SizedBox(width: context.rw(16)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: context.rh(4)),
                  subtitle!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// FILE: lib/views/widgets/detail/detail_scaffold.dart
// ─────────────────────────────────────────────────────────────────
//
// Đây là widget "khung" cho mọi màn hình detail.
// Nó xử lý toàn bộ: loading state, animation, pull-to-refresh,
// AppSliverAppBar, và bottomNavigationBar.
//
// CÁCH SỬ DỤNG:
//
//   DetailScaffold(
//     appBarTitle: 'Chi tiết kho hàng',
//     onRefresh: _fetchData,
//     bottomBar: _buildBottomActions(context, warehouse),
//     slivers: [
//       SliverToBoxAdapter(child: _HeroCard(...)),
//       SliverToBoxAdapter(child: DetailInfoSection(...)),
//     ],
//   )
// ─────────────────────────────────────────────────────────────────

class DetailScaffold extends StatefulWidget {
  /// Tiêu đề AppBar
  final String appBarTitle;

  /// Hàm fetch data — dùng cho cả lần đầu load và pull-to-refresh
  final Future<void> Function() onRefresh;

  /// Nội dung chính dạng sliver (không cần thêm SliverAppBar)
  final List<Widget> slivers;

  /// Widget ở đáy màn hình (ActionBottomButtons, ...)
  final Widget? bottomBar;

  /// Khoảng cách cuối tránh bị bottomBar che (default 120)
  final double bottomPadding;

  /// Thời gian chờ trước khi bắt đầu animation vào (default 400ms)
  final Duration initialDelay;

  const DetailScaffold({
    super.key,
    required this.appBarTitle,
    required this.onRefresh,
    required this.slivers,
    this.bottomBar,
    this.bottomPadding = 120,
    this.initialDelay = const Duration(milliseconds: 400),
  });

  @override
  State<DetailScaffold> createState() => _DetailScaffoldState();
}

class _DetailScaffoldState extends State<DetailScaffold>
    with SingleTickerProviderStateMixin {
  bool _isReady = false;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.03),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.fastOutSlowIn,
    ));

    _initialLoad();
  }

  Future<void> _initialLoad() async {
    await Future.wait([
      Future.delayed(widget.initialDelay),
      widget.onRefresh(),
    ]);
    if (mounted) {
      setState(() => _isReady = true);
      _animController.forward();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (!_isReady) {
      return Scaffold(
        body: Center(
          child: LoadingAnimationWidget.dotsTriangle(
            color: cs.primary,
            size: 32,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      bottomNavigationBar: widget.bottomBar,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              AppSliverAppBar(
                title: widget.appBarTitle,
                showBackButton: true,
                height: 80,
              ),
              if (widget.onRefresh != null)
                CupertinoSliverRefreshControl(
                  onRefresh: widget.onRefresh!,
                  builder: (context, refreshState, pulledExtent,
                      refreshTriggerPullDistance, refreshIndicatorExtent) {
                    return const Center(
                      child: CupertinoActivityIndicator(),
                    );
                  },
                ),
              SliverToBoxAdapter(
                child: SizedBox(height: context.rh(8)),
              ),
              ...widget.slivers,
              SliverToBoxAdapter(
                child: SizedBox(height: widget.bottomPadding),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
