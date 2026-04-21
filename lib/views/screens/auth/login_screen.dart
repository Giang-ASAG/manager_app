import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:manager/core/extensions/l10n_extension.dart';
import 'package:manager/core/router/app_routes.dart';
import 'package:manager/core/utils/app_responsive.dart';
import 'package:manager/l10n/app_localizations.dart';
import 'package:manager/viewmodels/auth_viewmodel.dart';
import 'package:manager/views/widgets/app_actions.dart';
import 'package:manager/views/widgets/app_button.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'admin@qhmanage.com');
  final _passwordController = TextEditingController(text: 'Admin@123');

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ================= LOGIN =================
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthViewModel>();

    final success = await auth.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      context.go(AppRoutes.main);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login success")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? "Login failed")),
      );
    }
  }

  // ================= THEME =================

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: context.rw(24)),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: context.rw(380)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppActions(),
                  SizedBox(height: context.rh(30)),
                  _buildLogo(),
                  SizedBox(height: context.rh(30)),
                  _buildTitle(theme),
                  SizedBox(height: context.rh(30)),
                  _buildForm(theme, auth),
                  SizedBox(height: context.rh(20)),
                  _buildHint(theme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Center(
      child: Icon(Icons.bolt, size: context.sp(48), color: Colors.indigo),
    );
  }

  Widget _buildTitle(ThemeData theme) {
    return Text(
      AppLocalizations.of(context)!.loginTitle,
      textAlign: TextAlign.center,
      style: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.bold,
        fontSize: context.sp(24),
      ),
    );
  }

  Widget _buildForm(ThemeData theme, AuthViewModel auth) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildEmail(),
          SizedBox(height: context.rh(16)),
          _buildPassword(),
          SizedBox(height: context.rh(20)),
          AppButton(
            text: AppLocalizations.of(context)!.loginBtn,
            isLoading: auth.isLoading,
            onPressed: _handleLogin,
          )
        ],
      ),
    );
  }

  Widget _buildEmail() {
    return TextFormField(
      controller: _emailController,
      decoration: const InputDecoration(
        labelText: "Email",
        border: OutlineInputBorder(),
      ),
      validator: (value) => value!.isEmpty ? "Enter email" : null,
    );
  }

  Widget _buildPassword() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: context.l10n.password_text,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
      ),
      validator: (value) => value!.length < 6 ? "Min 6 chars" : null,
    );
  }

  Widget _buildHint(ThemeData theme) {
    return Text(
      "Demo: admin@qhmanage.com / Admin@123",
      textAlign: TextAlign.center,
      style: theme.textTheme.bodySmall,
    );
  }
}
