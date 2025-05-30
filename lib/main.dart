import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:atoms_innovation_hub/config/firebase_config.dart';
import 'package:atoms_innovation_hub/config/router_config.dart';
import 'package:atoms_innovation_hub/providers/theme_provider.dart';
import 'package:atoms_innovation_hub/services/auth_service.dart';
import 'package:atoms_innovation_hub/services/app_service.dart';
import 'package:atoms_innovation_hub/services/blog_service.dart';
import 'package:atoms_innovation_hub/services/analytics_service.dart';
import 'package:atoms_innovation_hub/services/contact_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseConfig.initializeFirebase();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
        ),
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        Provider<AppService>(
          create: (_) => AppService(),
        ),
        Provider<BlogService>(
          create: (_) => BlogService(),
        ),
        Provider<AnalyticsService>(
          create: (_) => AnalyticsService(),
        ),
        Provider<ContactService>(
          create: (_) => ContactService(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          final router = AppRouter.getRouter(context);
          
          // Check for auto-login on app start
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _checkAutoLogin(context);
          });
          
          return MaterialApp.router(
            title: 'Atom\'s Innovation Hub',
            theme: ThemeProvider.lightTheme,
            darkTheme: ThemeProvider.darkTheme,
            themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            debugShowCheckedModeBanner: false,
            routerConfig: router,
          );
        },
      ),
    );
  }

  void _checkAutoLogin(BuildContext context) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final shouldAutoLogin = await authService.shouldAutoLogin();
      
      if (shouldAutoLogin && authService.currentUser == null) {
        await authService.autoLogin();
      }
    } catch (e) {
      print('Auto-login check failed: $e');
    }
  }
}
