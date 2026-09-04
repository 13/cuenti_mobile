import 'dart:async';

import 'package:cuentimobile/core/theme/app_theme.dart';
import 'package:cuentimobile/features/auth/ui/app_lock_observer.dart';
import 'package:cuentimobile/features/auth/ui/auth_controller.dart';
import 'package:cuentimobile/features/transactions/data/transaction_outbox.dart';
import 'package:cuentimobile/features/transactions/ui/outbox_drain.dart';
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
  // Opened here, the way ApiClient's ResponseCache is: it needs an await a
  // provider's constructor cannot do inline, so the real store is handed in
  // as an override rather than built lazily inside the provider tree. Not
  // open(): nothing about the first frame should hang or crash on a
  // platform channel, so a store that cannot be opened degrades instead.
  final outbox = await TransactionOutbox.openOrFallback();
  runApp(
    ProviderScope(
      overrides: [transactionOutboxProvider.overrideWithValue(outbox)],
      child: const CuentiApp(),
    ),
  );
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
    // Whatever the outbox is already holding from a previous run gets a
    // send attempt -- but only once the API client is configured; see
    // [_drainOutboxOnce]. Usually that is a listener away, not now.
    if (ref.read(authControllerProvider).initialized) _drainOutboxOnce();
  }

  bool _startupDrainAsked = false;

  /// Sends what the outbox is holding from a previous run.
  ///
  /// Gated on auth being initialised because `ApiClient.init()` is what
  /// sets `dio.options.baseUrl`, behind two platform-channel awaits, and
  /// `RequestOptions` captures the base URL when the request is composed.
  /// Fired from `initState` this raced that: every entry went out against a
  /// half-configured client and came back as "the server did not answer",
  /// which the drain has no reason to treat as a refusal but every reason
  /// to stop on.
  ///
  /// Not awaited: a drain talks to the network, and nothing about showing
  /// the first frame should wait on that.
  void _drainOutboxOnce() {
    if (_startupDrainAsked) return;
    _startupDrainAsked = true;
    drainOutbox(ref);
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
    // The moment the API client is configured is the moment a queued write
    // can actually be sent.
    //
    // Held until the client knows its server: a drain composed before
    // ApiClient.init() would go out against the default baseUrl in
    // api_client.dart and be refused, and a refused entry is never retried
    // automatically.
    ref.listen(authControllerProvider.select((s) => s.initialized), (
      _,
      initialized,
    ) {
      if (initialized) _drainOutboxOnce();
    });
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
