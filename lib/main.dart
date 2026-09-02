import 'package:cuentimobile/core/theme/app_theme.dart';
import 'package:cuentimobile/features/auth/ui/app_lock_observer.dart';
import 'package:cuentimobile/features/auth/ui/auth_controller.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:cuentimobile/l10n/locale_resolution.dart';
import 'package:cuentimobile/router.dart';
import 'package:cuentimobile/utils/number_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initLocales();
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
    // Before the first frame, so the first number anything formats is
    // already in the user's locale. Kept in step below by a listener rather
    // than by a call in build(): mutating intl's global state as a side
    // effect of building is the kind of thing that works until a rebuild
    // happens at an awkward moment.
    applyLocale(_localeTagOf(ref.read(authControllerProvider)));
  }

  static String _localeTagOf(AuthState auth) =>
      auth.user?.locale ?? defaultLocaleTag;

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Any auth state change (login/logout/session restore) must re-trigger
    // GoRouter's redirect logic.
    ref.listen(authControllerProvider, (_, _) => _refreshNotifier.refresh());
    // Drives intl's ambient locale, which formatNumber and every DateFormat
    // in the app read. Fires only when the chosen locale actually changes.
    ref.listen(
      authControllerProvider.select(_localeTagOf),
      (_, tag) => applyLocale(tag),
    );
    final auth = ref.watch(authControllerProvider);
    final localeTag = _localeTagOf(auth);

    return MaterialApp.router(
      title: 'Cuenti',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: auth.user != null
          ? (auth.user!.darkMode ? ThemeMode.dark : ThemeMode.light)
          : ThemeMode.system,
      locale: localeOf(localeTag),
      supportedLocales: L.supportedLocales,
      localizationsDelegates: L.localizationsDelegates,
      localeResolutionCallback: resolveAppLocale,
      routerConfig: _router,
      builder: (context, child) =>
          AppLockObserver(child: child ?? const SizedBox.shrink()),
    );
  }
}
