import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'api/api_client.dart';
import 'providers/auth_provider.dart';
import 'providers/data_provider.dart';
import 'router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CuentiApp());
}

class CuentiApp extends StatefulWidget {
  const CuentiApp({super.key});

  @override
  State<CuentiApp> createState() => _CuentiAppState();
}

class _CuentiAppState extends State<CuentiApp> with WidgetsBindingObserver {
  final _localAuth = LocalAuthentication();
  bool _locked = false;
  late final ApiClient _apiClient;
  late final AuthProvider _authProvider;
  late final DataProvider _dataProvider;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _apiClient = ApiClient();
    _authProvider = AuthProvider(_apiClient);
    _dataProvider = DataProvider(_apiClient);
    // Create the router ONCE. It uses refreshListenable: auth internally
    // so redirects re-evaluate on auth changes without rebuilding the router.
    _router = AppRouter.router(_authProvider);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _router.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_authProvider.isLoggedIn || !_authProvider.biometricEnabled) return;

    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider.value(value: _dataProvider),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return MaterialApp.router(
            title: 'Cuenti',
            debugShowCheckedModeBanner: false,
            theme: _buildTheme(auth, Brightness.light),
            darkTheme: _buildTheme(auth, Brightness.dark),
            themeMode: auth.user?.darkMode == true ? ThemeMode.dark : ThemeMode.light,
            routerConfig: _router,
            builder: (context, child) {
              if (_locked) {
                return _LockScreen(onUnlock: _authenticate);
              }
              return child ?? const SizedBox.shrink();
            },
          );
        },
      ),
    );
  }
}

ThemeData _buildTheme(AuthProvider auth, Brightness brightness) {
  return ThemeData(
    colorSchemeSeed: auth.colorSchemeSeed,
    useMaterial3: true,
    brightness: brightness,
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
      isDense: true,
    ),
    cardTheme: CardThemeData(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),
  );
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
            Image.asset('assets/CuentiLogo.png', width: 100, height: 100),
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
