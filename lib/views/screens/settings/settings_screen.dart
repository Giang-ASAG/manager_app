import 'package:flutter/material.dart';
import 'package:manager/core/extensions/l10n_extension.dart';
import 'package:manager/core/utils/app_responsive.dart';
import 'package:manager/viewmodels/auth_viewmodel.dart';
import 'package:manager/viewmodels/language_viewmodel.dart';
import 'package:manager/viewmodels/theme_viewmodel.dart';
import 'package:manager/views/widgets/app_sliver_app_bar.dart';
import 'package:manager/views/widgets/app_snackbar.dart';
import 'package:manager/views/widgets/custom_popup.dart';
import 'package:provider/provider.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoggingOut = false;

  Future<void> _onLogout() async {
    showPopup(
      context: context,
      type: AlertType.info,
      title: context.l10n.logout_text,
      content: context.l10n.confirm_logout,
      onCancelPressed: () {},
      onOkPressed: () async {
        setState(() => _isLoggingOut = true);
        try {
          await context.read<AuthViewModel>().logout();
          if (mounted) {
            AppSnackbar.showSuccess(context, context.l10n.logout_success);
          }
        } finally {
          if (mounted) setState(() => _isLoggingOut = false);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = AppResponsive.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final themeVM = context.watch<ThemeViewModel>();
    final isDark = themeVM.isDark;
    final langVM = context.watch<LanguageViewModel>();
    final currentLang = langVM.locale.languageCode;
    return Stack(
      children: [
        Scaffold(
          backgroundColor: cs.surfaceContainerLowest,
          body: CustomScrollView(
            slivers: [
              AppSliverAppBar(
                title: context.l10n.settings,
                height: 80,
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  r.w(16),
                  r.h(20),
                  r.w(16),
                  r.h(32),
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Giao diện ──────────────────────────────────────────
                    _SectionLabel(label: context.l10n.theme_text, r: r),
                    SizedBox(height: r.h(8)),
                    _SettingsCard(
                      r: r,
                      children: [
                        _SwitchTile(
                          r: r,
                          icon: isDark
                              ? Icons.dark_mode_rounded
                              : Icons.light_mode_rounded,
                          title: context.l10n.theme_text,
                          value: isDark,
                          onChanged: (value) {
                            context.read<ThemeViewModel>().toggleTheme();
                          },
                        ),
                      ],
                    ),

                    SizedBox(height: r.h(24)),

                    // ── Ngôn ngữ ───────────────────────────────────────────
                    _SectionLabel(label: context.l10n.language_text, r: r),
                    SizedBox(height: r.h(8)),
                    _SettingsCard(
                      r: r,
                      children: [
                        _RadioTile(
                          r: r,
                          icon: Icons.language_rounded,
                          title: context.l10n.vi,
                          value: 'vi',
                          groupValue: currentLang,
                          onChanged: (value) {
                            context
                                .read<LanguageViewModel>()
                                .setLanguage(value!);
                          },
                        ),
                        Divider(
                          height: 1,
                          indent: r.w(56),
                          color: theme.colorScheme.outlineVariant,
                        ),
                        _RadioTile(
                          r: r,
                          icon: Icons.language_rounded,
                          title: context.l10n.en,
                          value: 'en',
                          groupValue: currentLang,
                          onChanged: (value) {
                            context
                                .read<LanguageViewModel>()
                                .setLanguage(value!);
                          },
                        ),
                      ],
                    ),

                    SizedBox(height: r.h(24)),

                    // ── Tài khoản ──────────────────────────────────────────
                    _SectionLabel(label: 'Tài khoản', r: r),
                    SizedBox(height: r.h(8)),
                    _SettingsCard(
                      r: r,
                      children: [
                        _ActionTile(
                          r: r,
                          icon: Icons.logout_rounded,
                          title: context.l10n.logout_text,
                          color: theme.colorScheme.error,
                          onTap: _onLogout,
                        ),
                      ],
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
        if (_isLoggingOut)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: Center(
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: cs.primary),
                      const SizedBox(height: 16),
                      Text(
                        context.l10n.logout_text + '...',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.r});

  final String label;
  final AppResponsive r;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(left: r.w(4)),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: r.sp(11),
          fontWeight: FontWeight.w700,
          color: cs.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children, required this.r});

  final List<Widget> children;
  final AppResponsive r;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(r.r(16)),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.r,
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final AppResponsive r;
  final IconData icon;
  final String title;

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SwitchListTile(
      contentPadding: EdgeInsets.symmetric(
        horizontal: r.w(16),
        vertical: r.h(4),
      ),
      secondary: _LeadingIcon(icon: icon, r: r),
      title: Text(
        title,
        style: TextStyle(
          fontSize: r.sp(15),
          fontWeight: FontWeight.w600,
          color: cs.onSurface,
        ),
      ),
      value: value,
      onChanged: onChanged,
    );
  }
}

class _RadioTile extends StatelessWidget {
  const _RadioTile({
    required this.r,
    required this.icon,
    required this.title,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  final AppResponsive r;
  final IconData icon;
  final String title;
  final String value;
  final String groupValue;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return RadioListTile<String>(
      contentPadding: EdgeInsets.symmetric(
        horizontal: r.w(16),
        vertical: r.h(2),
      ),
      secondary: _LeadingIcon(icon: icon, r: r),
      title: Text(
        title,
        style: TextStyle(
          fontSize: r.sp(15),
          fontWeight: FontWeight.w600,
          color: cs.onSurface,
        ),
      ),
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.r,
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  final AppResponsive r;
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(
        horizontal: r.w(16),
        vertical: r.h(4),
      ),
      leading: _LeadingIcon(icon: icon, r: r, color: color),
      title: Text(
        title,
        style: TextStyle(
          fontSize: r.sp(15),
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: color.withOpacity(0.6),
        size: r.sp(20),
      ),
      onTap: onTap,
    );
  }
}

class _LeadingIcon extends StatelessWidget {
  const _LeadingIcon({required this.icon, required this.r, this.color});

  final IconData icon;
  final AppResponsive r;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final c = color ?? cs.primary;
    return Container(
      width: r.w(38),
      height: r.w(38),
      decoration: BoxDecoration(
        color: c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(r.r(10)),
      ),
      child: Icon(icon, color: c, size: r.sp(20)),
    );
  }
}
