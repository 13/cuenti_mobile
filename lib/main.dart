import 'package:cuentimobile/core/theme/app_theme.dart';
import 'package:cuentimobile/features/auth/ui/app_lock_observer.dart';
import 'package:cuentimobile/features/auth/ui/auth_controller.dart';
import 'package:cuentimobile/router.dart';
import 'package:cuentimobile/utils/number_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The locales the settings screen offers. Numbers, dates and the built-in
/// Material widgets follow the user's choice; the app's own strings are
/// still English everywhere.
const supportedLocales = [
  Locale('de', 'DE'),
  Locale('en', 'US'),
  Locale('es', 'ES'),
  Locale('fr', 'FR'),
  Locale('it', 'IT'),
];

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
    ref.listen(authControllerProvider, (_, _) => _refreshNotifier.refresh());
    final auth = ref.watch(authControllerProvider);
    final localeTag = auth.user?.locale ?? defaultLocaleTag;
    // Drives intl's ambient locale, which formatNumber and every DateFormat
    // in the app read.
    applyLocale(localeTag);

    return MaterialApp.router(
      title: 'Cuenti',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: auth.user != null
          ? (auth.user!.darkMode ? ThemeMode.dark : ThemeMode.light)
          : ThemeMode.system,
      locale: localeOf(localeTag),
      supportedLocales: supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: _router,
      builder: (context, child) =>
          AppLockObserver(child: child ?? const SizedBox.shrink()),
    );
  }
}
