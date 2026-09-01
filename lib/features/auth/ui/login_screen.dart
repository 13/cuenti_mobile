import 'dart:async';
import 'package:cuentimobile/features/auth/ui/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.authenticator});

  /// Injectable seam for tests (the default constructs a real
  /// [LocalAuthentication], which talks to a platform channel unavailable in
  /// widget tests). Same pattern as `AppLockObserver`.
  final LocalAuthentication? authenticator;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  late final LocalAuthentication _localAuth =
      widget.authenticator ?? LocalAuthentication();
  bool _biometricAttempted = false;
  bool _obscurePassword = true;
  bool _submitting = false;
  String? _error;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      unawaited(_restoreSession());
    }
  }

  /// Best-effort session restore. It reads secure storage and asks the
  /// server for the profile and the registration flag, any of which can
  /// fail when the server is unreachable -- and a launch with no network
  /// must still leave a login form the user can type into, not an
  /// unhandled async error.
  Future<void> _restoreSession() async {
    try {
      await ref.read(authControllerProvider.notifier).init();
    } on Exception catch (_) {
      return;
    }
    if (!mounted) return;
    final auth = ref.read(authControllerProvider);
    if (auth.isLoggedIn) {
      context.go('/dashboard');
      return;
    }
    _applySavedCredentials(auth);
  }

  void _applySavedCredentials(AuthState auth) {
    final saved = auth.savedUsername;
    if (saved == null || saved.isEmpty) return;
    _usernameController.text = saved;
    _passwordFocus.requestFocus();
    if (auth.biometricEnabled &&
        auth.hasSavedPassword &&
        !_biometricAttempted) {
      _biometricAttempted = true;
      unawaited(_biometricLogin());
    }
  }

  Future<void> _forgetSavedCredentials() async {
    await ref.read(authControllerProvider.notifier).forgetSavedCredentials();
    if (!mounted) return;
    setState(() {
      _usernameController.clear();
      _passwordController.clear();
      _error = null;
    });
    _usernameFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/Cuenti.png', width: 80, height: 80),
                  const SizedBox(height: 16),
                  Text(
                    'Sign in',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _usernameController,
                    focusNode: _usernameFocus,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                    textInputAction: TextInputAction.next,
                  ),
                  if (auth.savedUsername != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _submitting ? null : _forgetSavedCredentials,
                        child: const Text('Not you?'),
                      ),
                    ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        tooltip: _obscurePassword
                            ? 'Show password'
                            : 'Hide password',
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                    onFieldSubmitted: (_) => _login(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _submitting ? null : _login,
                      child: _submitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Sign In'),
                    ),
                  ),
                  if (auth.biometricEnabled && auth.hasSavedPassword) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _submitting ? null : _biometricLogin,
                        icon: const Icon(Icons.fingerprint),
                        label: const Text('Sign in with biometrics'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (auth.registrationEnabled)
                    TextButton(
                      onPressed: () => context.go('/register'),
                      child: const Text("Don't have an account? Register"),
                    ),
                  TextButton(
                    onPressed: () => context.go('/server-setup'),
                    child: Text(
                      'Server: ${ref.read(authControllerProvider.notifier).serverUrl}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final error = await ref
        .read(authControllerProvider.notifier)
        .login(
          _usernameController.text.trim(),
          _passwordController.text,
        );
    if (!mounted) return;
    if (error == null) {
      context.go('/dashboard');
    } else {
      setState(() {
        _submitting = false;
        _error = error;
      });
    }
  }

  Future<void> _biometricLogin() async {
    setState(() {
      _submitting = true;
    });
    bool didAuth;
    try {
      didAuth = await _localAuth.authenticate(
        localizedReason: 'Sign in to Cuenti',
      );
    } on Exception catch (_) {
      // Biometrics unavailable/cancelled: fall back to password entry.
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
      return;
    }
    if (!didAuth) {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
      return;
    }
    if (!mounted) return;

    setState(() {
      _error = null;
    });
    final error = await ref
        .read(authControllerProvider.notifier)
        .loginWithSavedCredentials();
    if (!mounted) return;
    if (error == null) {
      context.go('/dashboard');
    } else {
      setState(() {
        _submitting = false;
        _error = error;
      });
      _passwordFocus.requestFocus();
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }
}
