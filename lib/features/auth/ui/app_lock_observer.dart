import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'auth_controller.dart';

/// Wraps [child] with the biometric app-lock behaviour that used to live in
/// `_CuentiAppState` (main.dart): when the app is paused/hidden while a
/// biometric-enabled user is logged in, the next resume shows a lock screen
/// gated by [LocalAuthentication].
class AppLockObserver extends ConsumerStatefulWidget {
  const AppLockObserver({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppLockObserver> createState() => _AppLockObserverState();
}

class _AppLockObserverState extends ConsumerState<AppLockObserver>
    with WidgetsBindingObserver {
  final _localAuth = LocalAuthentication();
  bool _locked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final auth = ref.read(authControllerProvider);
    if (!auth.isLoggedIn || !auth.biometricEnabled) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      setState(() => _locked = true);
    } else if (state == AppLifecycleState.resumed && _locked) {
      _authenticate();
    }
  }

  Future<void> _authenticate() async {
    try {
      final didAuth = await _localAuth.authenticate(
        localizedReason: 'Authenticate to unlock Cuenti',
      );
      if (didAuth) {
        setState(() => _locked = false);
      }
    } catch (_) {
      // If biometric auth is unavailable, just unlock
      setState(() => _locked = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_locked) {
      return _LockScreen(onUnlock: _authenticate);
    }
    return widget.child;
  }
}

class _LockScreen extends StatelessWidget {
  final VoidCallback onUnlock;
  const _LockScreen({required this.onUnlock});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/Cuenti.png', width: 100, height: 100),
            const SizedBox(height: 24),
            Text('Cuenti is Locked',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onUnlock,
              icon: const Icon(Icons.fingerprint),
              label: const Text('Unlock'),
            ),
          ],
        ),
      ),
    );
  }
}
