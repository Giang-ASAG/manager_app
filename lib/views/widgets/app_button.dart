import 'package:flutter/material.dart';
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
    return SizedBox(
      width: double.infinity,
      height: context.rh(50),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.tertiary,
              colorScheme.tertiaryContainer,
            ],
          ),
          borderRadius: BorderRadius.circular(context.rr(12)),
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
          ),
          child: isLoading
              ? SizedBox(
                  width: context.rw(20),
                  height: context.rh(20),
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  text,
                  style: TextStyle(
                    fontSize: context.sp(16),
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}
