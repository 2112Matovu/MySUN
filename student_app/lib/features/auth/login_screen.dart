import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mysun_app/core/constants/app_constants.dart';
import 'package:mysun_app/core/theme/app_colors.dart';
import 'package:mysun_app/providers/auth_provider.dart';

/// §4.2 Login Screen. Role detection happens after a successful login —
/// the router's redirect sends students/publishers to `/` and admin-level
/// accounts to `/admin-portal`.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _rememberMe = true;
  bool _obscure = true;
  bool _showDemoAccounts = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _code.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(authProvider.notifier).login(_email.text, _password.text);
  }

  void _fillDemo(String email, String password) {
    _email.text = email;
    _password.text = password;
    _submit();
  }

  final _code = TextEditingController();

  Widget _codePrompt(AuthState auth, ThemeData theme) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Two-factor sign-in'),
        leading: IconButton(
          tooltip: 'Back to sign in',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => ref.read(authProvider.notifier).cancelMfa(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.lock_outline, size: 44),
                const SizedBox(height: 12),
                Text(
                  'Open your authenticator app and enter the 6-digit code for MySun.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _code,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: '6-digit code'),
                  onSubmitted: (_) => _submitCode(),
                ),
                if (auth.errorMessage != null)
                  Text(auth.errorMessage!, style: TextStyle(color: theme.colorScheme.error)),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: auth.isSubmitting ? null : _submitCode,
                  child: auth.isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Verify'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submitCode() => ref.read(authProvider.notifier).submitMfaCode(_code.text);

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final theme = Theme.of(context);
    if (auth.mfaFactorId != null) return _codePrompt(auth, theme);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.wb_sunny_rounded,
                        size: 48, color: AppColors.brandSun),
                    const SizedBox(height: 12),
                    Text(AppConstants.appName,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    Text('${AppConstants.university} Campus Companion',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: theme.colorScheme.outline)),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email address',
                        hintText: 'you@sun.ac.ug',
                      ),
                      validator: (v) => (v == null || !v.contains('@'))
                          ? 'Enter a valid email'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        suffixIcon: IconButton(
                          tooltip: 'Show or hide password',
                          icon: Icon(_obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Enter your password'
                          : null,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              onChanged: (v) =>
                                  setState(() => _rememberMe = v ?? true),
                            ),
                            const Text('Remember me'),
                          ],
                        ),
                        TextButton(
                          onPressed: () => context.push('/forgot-password'),
                          child: const Text('Forgot password?'),
                        ),
                      ],
                    ),
                    if (auth.errorMessage != null) ...[
                      const SizedBox(height: 4),
                      Text(auth.errorMessage!,
                          style:
                              TextStyle(color: theme.colorScheme.error)),
                      const SizedBox(height: 8),
                    ],
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: auth.isSubmitting ? null : _submit,
                      child: auth.isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Sign In'),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text("Don't have an account?"),
                        TextButton(
                          onPressed: () => context.push('/signup'),
                          child: const Text('Create Account'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text('OR'),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: auth.isSubmitting
                          ? null
                          : () => ref
                              .read(authProvider.notifier)
                              .loginWithGoogle(),
                      icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                      label: const Text('Sign in with Google'),
                    ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () => setState(
                          () => _showDemoAccounts = !_showDemoAccounts),
                      child: Text(_showDemoAccounts
                          ? 'Hide demo accounts'
                          : 'Show demo accounts'),
                    ),
                    if (_showDemoAccounts)
                      Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _DemoAccountTile(
                                role: 'Student',
                                email: 'student@sun.ac.ug',
                                password: 'student123',
                                onTap: () => _fillDemo(
                                    'student@sun.ac.ug', 'student123'),
                              ),
                              _DemoAccountTile(
                                role: 'Publisher',
                                email: 'publisher@sun.ac.ug',
                                password: 'publisher123',
                                onTap: () => _fillDemo(
                                    'publisher@sun.ac.ug', 'publisher123'),
                              ),
                              _DemoAccountTile(
                                role: 'Admin',
                                email: 'admin@sun.ac.ug',
                                password: 'admin123',
                                onTap: () =>
                                    _fillDemo('admin@sun.ac.ug', 'admin123'),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DemoAccountTile extends StatelessWidget {
  const _DemoAccountTile({
    required this.role,
    required this.email,
    required this.password,
    required this.onTap,
  });

  final String role;
  final String email;
  final String password;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(role, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text('$email  /  $password'),
      trailing: TextButton(onPressed: onTap, child: const Text('Use')),
    );
  }
}
