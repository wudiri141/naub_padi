import 'package:flutter/material.dart';

import 'auth_form.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AuthForm(
      mode: AuthMode.signIn,
      title: 'Welcome back',
      subtitle: 'Sign in to sync bookmarks, upload resources, and keep your study shelf current.',
      primaryLabel: 'Sign in',
      secondaryPrompt: "Don't have an account?",
      secondaryLabel: 'Create one',
    );
  }
}

