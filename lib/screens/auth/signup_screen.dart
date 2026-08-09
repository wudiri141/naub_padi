import 'package:flutter/material.dart';

import 'auth_form.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AuthForm(
      mode: AuthMode.signUp,
      title: 'Create an account',
      subtitle: 'Join NAUB Padi to search, save, upload, and access question papers.',
      primaryLabel: 'Create account',
      secondaryPrompt: 'Already have an account?',
      secondaryLabel: 'Sign in',
    );
  }
}

