import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:manager/viewmodels/theme_viewmodel.dart';
import 'package:manager/viewmodels/language_viewmodel.dart';

class AppActions extends StatelessWidget {
  final MainAxisAlignment alignment;

  const AppActions({
    super.key,
    this.alignment = MainAxisAlignment.end,
  });

  @override
  Widget build(BuildContext context) {
    final themeVM = context.watch<ThemeViewModel>();

    final iconColor = Theme.of(context).colorScheme.onSurface;

    return Row(
      mainAxisAlignment: alignment,
      children: [
        IconButton(
          icon: Icon(
            themeVM.isDark ? Icons.light_mode : Icons.dark_mode,
            color: iconColor,
          ),
          tooltip: 'Toggle theme',
          onPressed: () {
            context.read<ThemeViewModel>().toggleTheme();
          },
        ),
        IconButton(
          icon: Icon(Icons.language, color: iconColor),
          tooltip: 'Change language',
          onPressed: () {
            context.read<LanguageViewModel>().toggleLanguage();
          },
        ),
      ],
    );
  }
}