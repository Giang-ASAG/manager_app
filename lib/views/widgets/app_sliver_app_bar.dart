import 'package:flutter/material.dart';
import 'package:manager/core/utils/app_responsive.dart';

class AppSliverAppBar extends StatelessWidget {
  final String title;
  final bool showBackButton;
  final List<Widget>? actions;
  final Widget? bottom;
  final double height;

  const AppSliverAppBar({
    super.key,
    required this.title,
    this.showBackButton = false,
    this.actions,
    this.bottom,
    this.height = 150,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SliverAppBar(
      automaticallyImplyLeading: false,
      pinned: true,
      expandedHeight: context.rh(height),
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.tertiary,
                colorScheme.tertiaryContainer,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(context.rr(28)),
              bottomRight: Radius.circular(context.rr(28)),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                context.rw(16),
                context.rh(12),
                context.rw(20),
                context.rh(10), // ← từ rh(16)
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (showBackButton) ...[
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(
                            Icons.arrow_back_rounded,
                            color: colorScheme.onPrimary,
                            size: context.sp(28),
                          ),
                        ),
                        SizedBox(width: context.rw(8)),
                      ],
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: Text(
                            title,
                            style: TextStyle(
                              color: colorScheme.onPrimary,
                              fontSize: context.sp(22),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      if (actions != null)
                        IconTheme(
                          data: IconThemeData(
                            color: colorScheme.onPrimary,
                          ),
                          child: Row(children: actions!),
                        ),
                    ],
                  ),
                  if (bottom != null) ...[
                    SizedBox(height: context.rh(12)),
                    Theme(
                      data: theme.copyWith(
                        inputDecorationTheme: InputDecorationTheme(
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.18),
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: context.sp(14),
                            fontWeight: FontWeight.w400,
                          ),
                          prefixIconColor: Colors.white.withOpacity(0.85),
                          suffixIconColor: Colors.white.withOpacity(0.7),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: context.rw(16),
                            vertical: context.rh(12),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(context.rr(20)),
                            borderSide: BorderSide(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(context.rr(20)),
                            borderSide: BorderSide(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(context.rr(20)),
                            borderSide: BorderSide(
                              color: Colors.white.withOpacity(0.7),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      child: bottom!,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
