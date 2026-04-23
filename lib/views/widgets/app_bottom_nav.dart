import 'package:flutter/material.dart';
import 'package:manager/core/extensions/l10n_extension.dart';
import 'package:manager/l10n/app_localizations.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final VoidCallback onFabPressed;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onFabPressed,
  });

  List<_NavItem> _items(BuildContext context) {
    return [
      _NavItem(icon: Icons.dashboard, label: context.l10n.dashboard_text),
      _NavItem(icon: Icons.payments_sharp, label: context.l10n.invoice),
      _NavItem(icon: Icons.inventory, label: 'Hình ảnh'),
      _NavItem(icon: Icons.settings, label: context.l10n.settings),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.tertiary;
    return SizedBox(
      height: 80,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // ── Bar ───────────────────────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 72,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // 2 icon bên trái
                  ...[0, 1].map((i) => Expanded(child: _buildItem(context, i))),
                  // Khoảng trống giữa cho FAB
                  const SizedBox(width: 72),
                  // 2 icon bên phải
                  ...[2, 3].map((i) => Expanded(child: _buildItem(context, i))),
                ],
              ),
            ),
          ),

          // ── FAB tròn ─────────────────────────────────────────────────────
          Positioned(
            top: 0,
            child: GestureDetector(
              onTap: onFabPressed,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: primary, // ✅ dùng theme
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primary.withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    final item = _items(context)[index];
    final isSelected = currentIndex == index;

    final primary = Theme.of(context).colorScheme.tertiary;
    final unselected = Theme.of(context).colorScheme.onSurface.withOpacity(0.4);

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color:
                    isSelected ? primary.withOpacity(0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                item.icon,
                size: 22,
                color: isSelected ? primary : unselected,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? primary : unselected,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem({required this.icon, required this.label});
}
