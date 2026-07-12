import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/ui/app_lock_observer.dart';
import 'features/auth/ui/auth_controller.dart';
import 'router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: CuentiApp()));
}

class CuentiApp extends ConsumerStatefulWidget {
  const CuentiApp({super.key});

  @override
  ConsumerState<CuentiApp> createState() => _CuentiAppState();
}

class _CuentiAppState extends ConsumerState<CuentiApp> {
  late final GoRouterRefreshNotifier _refreshNotifier;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _refreshNotifier = GoRouterRefreshNotifier();
    // Create the router ONCE. The refresh notifier + readAuth callback bridge
    // Riverpod's auth state into GoRouter's redirect so redirects re-evaluate
    // on auth changes without rebuilding the router (which would freeze the
    // UI).
    _router = AppRouter.router(
      _refreshNotifier,
      () => ref.read(authControllerProvider),
    );
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Any auth state change (login/logout/session restore) must re-trigger
    // GoRouter's redirect logic.
    ref.listen(authControllerProvider, (_, __) => _refreshNotifier.refresh());
    final auth = ref.watch(authControllerProvider);

    return MaterialApp.router(
      title: 'Cuenti',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(auth.colorSchemeSeed, Brightness.light),
      darkTheme: AppTheme.build(auth.colorSchemeSeed, Brightness.dark),
      themeMode:
          auth.user?.darkMode == true ? ThemeMode.dark : ThemeMode.light,
      routerConfig: _router,
      builder: (context, child) =>
          AppLockObserver(child: child ?? const SizedBox.shrink()),
    );
  }
}
