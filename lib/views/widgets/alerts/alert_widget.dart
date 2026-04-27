import 'package:flutter/material.dart';
import 'package:manager/core/utils/app_responsive.dart';

class TopAlertWidget extends StatefulWidget {
  final String message;
  final Color color;
  final IconData icon;
  final VoidCallback onClose;

  const TopAlertWidget({
    required this.message,
    required this.color,
    required this.icon,
    required this.onClose,
  });

  @override
  State<TopAlertWidget> createState() => _TopAlertWidgetState();
}

class _TopAlertWidgetState extends State<TopAlertWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> slideAnim;
  late Animation<double> fadeAnim;
  late Animation<double> scaleAnim;

  static const _autoDismissDuration = Duration(seconds: 3);
  static const _animDuration = Duration(milliseconds: 400);

  @override
  void initState() {
    super.initState();

    controller = AnimationController(vsync: this, duration: _animDuration);

    slideAnim = Tween(begin: -120.0, end: 48.0).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOutBack),
    );

    fadeAnim = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    scaleAnim = Tween(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOutBack),
    );

    controller.forward();
    Future.delayed(_autoDismissDuration, close);
  }

  void close() async {
    if (!mounted) return;
    await controller.reverse();
    widget.onClose();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Positioned(
          top: slideAnim.value,
          left: context.rw(16),
          right: context.rw(16),
          child: Opacity(
            opacity: fadeAnim.value.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: scaleAnim.value,
              child: _buildContent(context),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardColor = isDark
        ? Color.alphaBlend(widget.color.withOpacity(0.08), theme.cardColor)
        : Color.alphaBlend(widget.color.withOpacity(0.04), theme.cardColor);

    final shadowColor = isDark
        ? Colors.black.withOpacity(0.4)
        : widget.color.withOpacity(0.15);

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(context.rr(16)),
          border: Border.all(
            color: widget.color.withOpacity(isDark ? 0.4 : 0.25),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: widget.color.withOpacity(0.08),
              blurRadius: 40,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(context.rr(16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildBody(context, theme),
              _buildProgressBar(context, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ThemeData theme) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.rw(4),
        context.rh(4),
        context.rw(4),
        0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon badge
          Container(
            width: context.rw(44),
            height: context.rh(44),
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(context.rr(12)),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(widget.icon, color: Colors.white, size: context.sp(20)),
          ),
          SizedBox(width: context.rw(12)),

          // Message
          Expanded(
            child: Text(
              widget.message,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: context.sp(14),
                color: theme.colorScheme.onSurface,
                height: 1.4,
              ),
            ),
          ),

          // Close button
          SizedBox(
            width: context.rw(36),
            height: context.rh(36),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(
                Icons.close_rounded,
                size: context.sp(18),
                color: theme.colorScheme.onSurface.withOpacity(0.45),
              ),
              onPressed: close,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context, ThemeData theme) {
    return Padding(
      padding: EdgeInsets.only(top: context.rh(10)),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 1.0, end: 0.0),
        duration: _autoDismissDuration,
        builder: (context, value, _) {
          return LinearProgressIndicator(
            value: value,
            minHeight: context.rh(3),
            backgroundColor: theme.colorScheme.onSurface.withOpacity(0.06),
            valueColor: AlwaysStoppedAnimation<Color>(
              widget.color.withOpacity(0.8),
            ),
          );
        },
      ),
    );
  }
}