import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'api/api_client.dart';
import 'providers/auth_provider.dart';
import 'providers/data_provider.dart';
import 'router.dart';

void main() {
  runApp(const CuentiApp());
}

class CuentiApp extends StatelessWidget {
  const CuentiApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiClient = ApiClient();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => DataProvider(apiClient)),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return MaterialApp.router(
            title: 'Cuenti',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorSchemeSeed: const Color(0xFF6750A4),
              useMaterial3: true,
              brightness: Brightness.light,
            ),
            darkTheme: ThemeData(
              colorSchemeSeed: const Color(0xFF6750A4),
              useMaterial3: true,
              brightness: Brightness.dark,
            ),
            themeMode: auth.user?.darkMode == true ? ThemeMode.dark : ThemeMode.light,
            routerConfig: AppRouter.router(auth),
          );
        },
      ),
    );
  }
}
