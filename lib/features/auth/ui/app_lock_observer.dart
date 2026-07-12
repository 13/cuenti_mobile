import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'auth_controller.dart';

/// Wraps [child] with the biometric app-lock behaviour that used to live in
/// `_CuentiAppState` (main.dart): when the app is paused/hidden while a
/// biometric-enabled user is logged in, the next resume shows a lock screen
/// gated by [LocalAuthentication]. It also locks on cold start: a restored
/// session (app launched fresh with a persisted, biometric-enabled login)
/// never went through a pause/resume cycle, so without this it would start
/// unlocked.
class AppLockObserver extends ConsumerStatefulWidget {
  const AppLockObserver({super.key, required this.child, this.authenticator});

  final Widget child;

  /// Injectable seam for tests (the default constructs a real
  /// [LocalAuthentication], which talks to a platform channel unavailable in
  /// widget tests).
  final LocalAuthentication? authenticator;

  @override
  ConsumerState<AppLockObserver> createState() => _AppLockObserverState();
}

class _AppLockObserverState extends ConsumerState<AppLockObserver>
    with WidgetsBindingObserver {
  late final LocalAuthentication _localAuth =
      widget.authenticator ?? LocalAuthentication();
  bool _locked = false;

  // Cold start is handled at most once per app session: the first time auth
  // state is observed to be initialized, we decide then and never again —
  // otherwise a login happening later in the same session (after this
  // widget's already up) would look like a fresh cold start and lock
  // unnecessarily.
  bool _coldStartHandled = false;

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

  /// Decides the cold-start lock exactly once, the first time [state] shows
  /// `initialized`. [duringBuild] must be true when called synchronously
  /// from [build] (calling `setState` there would throw) and false when
  /// called from the `ref.listen` callback (called outside build, where
  /// `setState` is required to schedule the rebuild that shows the lock
  /// screen).
  void _handleColdStart(AuthState state, {required bool duringBuild}) {
    if (_coldStartHandled) return;
    if (!state.initialized) return;
    _coldStartHandled = true;

    // Logged-out or biometric-off cold starts never lock.
    if (!state.isLoggedIn || !state.biometricEnabled) return;

    if (duringBuild) {
      _locked = true;
    } else {
      setState(() => _locked = true);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _authenticate();
    });
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
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      _handleColdStart(next, duringBuild: false);
    });
    if (!_coldStartHandled) {
      _handleColdStart(ref.read(authControllerProvider), duringBuild: true);
    }

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
