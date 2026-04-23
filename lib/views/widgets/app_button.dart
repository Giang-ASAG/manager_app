import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:manager/core/utils/app_responsive.dart';

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Kiểm tra xem nút có đang bị disable không
    final bool isEnabled = onPressed != null && !isLoading;

    return SizedBox(
      width: double.infinity,
      height: context.rh(52), // Tăng nhẹ chiều cao cho cảm giác vững chãi
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isEnabled
                ? [colorScheme.tertiary, colorScheme.tertiaryContainer]
                : [
                    colorScheme.surfaceContainerHighest,
                    colorScheme.surfaceContainerHighest
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(context.rr(14)),
          // Bo góc mềm mại hơn
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: colorScheme.tertiary.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: ElevatedButton(
          onPressed: isEnabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(context.rr(14)),
            ),
          ),
          child: isLoading
              ? LoadingAnimationWidget.staggeredDotsWave(
                  color: Colors.white,
                  size: context.sp(28),
                )
              : Text(
                  text,
                  style: TextStyle(
                    fontSize: context.sp(16),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ),
    );
  }
}
