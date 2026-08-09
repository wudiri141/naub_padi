import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/app_settings_controller.dart';
import '../../core/utils/user_facing_message.dart';
import '../../services/auth_service.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_snackbar.dart';
import '../../widgets/common/app_text_field.dart';

enum AuthMode { signIn, signUp }

class AuthForm extends StatefulWidget {
  const AuthForm({
    super.key,
    required this.mode,
    required this.title,
    required this.subtitle,
    required this.primaryLabel,
    required this.secondaryPrompt,
    required this.secondaryLabel,
  });

  final AuthMode mode;
  final String title;
  final String subtitle;
  final String primaryLabel;
  final String secondaryPrompt;
  final String secondaryLabel;

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final auth = AuthService.instance;
    final settings = context.read<AppSettingsController>();

    setState(() => _loading = true);
    try {
      if (widget.mode == AuthMode.signIn) {
        final result = await auth.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        await settings.saveUser(result.user, token: result.token.isEmpty ? null : result.token);
        if (!mounted) {
          return;
        }

        showAppSnackBar(context, 'Signed in as ${result.user.fullName}.');
        context.go(AppRoutes.home);
      } else {
        await auth.signUp(
          fullName: _fullNameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        await settings.clearSession();
        if (!mounted) {
          return;
        }

        showAppSnackBar(context, 'Registration successful. Please log in to continue.');
        context.go(AppRoutes.login);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      showAppSnackBar(
        context,
        widget.mode == AuthMode.signIn ? loginErrorMessage(error) : friendlyErrorMessage(error, fallback: 'Unable to create your account. Please try again later.'),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: AppCard(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppConstants.appName,
                                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                              ),
                              Text(
                                AppConstants.appSubtitle,
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.subtitle,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 24),
                      if (widget.mode == AuthMode.signUp) ...[
                        AppTextField(
                          controller: _fullNameController,
                          label: 'Full name',
                          hintText: 'Enter your full name',
                          prefixIcon: Icons.person_outline_rounded,
                          textInputAction: TextInputAction.next,
                          validator: (value) => value == null || value.trim().isEmpty ? 'Full name is required' : null,
                        ),
                        const SizedBox(height: 14),
                      ],
                      AppTextField(
                        controller: _emailController,
                        label: 'Email',
                        hintText: 'you@naub.edu.ng',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          final trimmed = value?.trim() ?? '';
                          if (trimmed.isEmpty) {
                            return 'Please enter your email.';
                          }
                          if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(trimmed)) {
                            return 'Invalid email format.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        controller: _passwordController,
                        label: 'Password',
                        hintText: 'Enter your password',
                        prefixIcon: Icons.lock_outline_rounded,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        suffixIcon: _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        onSuffixPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password.';
                          }
                          if (value.length < 6) {
                            return 'Use at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 22),
                      AppButton(
                        label: widget.primaryLabel,
                        onPressed: _submit,
                        isLoading: _loading,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.secondaryPrompt,
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                          TextButton(
                            onPressed: () {
                              context.go(widget.mode == AuthMode.signIn ? AppRoutes.signup : AppRoutes.login);
                            },
                            child: Text(widget.secondaryLabel),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
