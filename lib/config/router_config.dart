import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:atoms_innovation_hub/screens/home_screen.dart';
import 'package:atoms_innovation_hub/screens/auth/login_screen.dart';
import 'package:atoms_innovation_hub/screens/auth/signup_screen.dart';
import 'package:atoms_innovation_hub/screens/auth/forgot_password_screen.dart';
import 'package:atoms_innovation_hub/screens/apps/apps_screen.dart';
import 'package:atoms_innovation_hub/screens/apps/app_details_screen.dart';
import 'package:atoms_innovation_hub/screens/blog/blog_screen.dart';
import 'package:atoms_innovation_hub/screens/blog/blog_post_screen.dart';
import 'package:atoms_innovation_hub/screens/profile/profile_screen.dart';
import 'package:atoms_innovation_hub/screens/admin/admin_dashboard_screen.dart';
import 'package:atoms_innovation_hub/screens/about_screen.dart';
import 'package:atoms_innovation_hub/screens/contact_screen.dart';
import 'package:atoms_innovation_hub/screens/messages/messages_screen.dart';
import 'package:atoms_innovation_hub/services/auth_service.dart';
import 'package:provider/provider.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter getRouter(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/',
      refreshListenable: GoRouterRefreshStream(authService.authStateChanges),
      redirect: (context, state) {
        final isLoggedIn = authService.currentUser != null;
        final isGoingToLogin = state.matchedLocation == '/login';
        final isGoingToSignup = state.matchedLocation == '/signup';
        final isGoingToForgotPassword = state.matchedLocation == '/forgot-password';
        
        // List of public routes that don't require authentication
        final publicRoutes = ['/blog', '/about', '/contact', '/apps'];
        final isGoingToPublicRoute = publicRoutes.any((route) => 
          state.matchedLocation.startsWith(route));
        
        // If not logged in and not going to auth pages or public routes, redirect to login
        if (!isLoggedIn && 
            !isGoingToLogin && 
            !isGoingToSignup && 
            !isGoingToForgotPassword &&
            !isGoingToPublicRoute) {
          return '/login';
        }
        
        // If logged in and going to auth pages, redirect to home
        if (isLoggedIn && 
            (isGoingToLogin || isGoingToSignup || isGoingToForgotPassword)) {
          return '/';
        }
        
        // No redirect needed
        return null;
      },
      routes: [
        // Auth Routes
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/signup',
          builder: (context, state) => const SignupScreen(),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        
        // Main App Shell Route
        ShellRoute(
          navigatorKey: _shellNavigatorKey,
          builder: (context, state, child) => HomeScreen(child: child),
          routes: [
            // Home Tab
            GoRoute(
              path: '/',
              builder: (context, state) => const HomeContent(),
            ),
            
            // Apps Tab
            GoRoute(
              path: '/apps',
              builder: (context, state) => const AppsScreen(),
              routes: [
                GoRoute(
                  path: 'details/:appId',
                  builder: (context, state) => AppDetailsScreen(
                    appId: state.pathParameters['appId'] ?? '',
                  ),
                ),
              ],
            ),
            
            // Blog Tab
            GoRoute(
              path: '/blog',
              builder: (context, state) => const BlogScreen(),
              routes: [
                GoRoute(
                  path: 'post/:postId',
                  builder: (context, state) => BlogPostScreen(
                    postId: state.pathParameters['postId'] ?? '',
                  ),
                ),
              ],
            ),
            
            // Profile Tab
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
            
            // Messages Tab
            GoRoute(
              path: '/messages',
              builder: (context, state) => const MessagesScreen(),
            ),
            
            // Admin Tab
            GoRoute(
              path: '/admin',
              builder: (context, state) => const AdminDashboardScreen(),
            ),
            
            // About Page
            GoRoute(
              path: '/about',
              builder: (context, state) => const AboutScreen(),
            ),
            
            // Contact Page
            GoRoute(
              path: '/contact',
              builder: (context, state) => const ContactScreen(),
            ),
          ],
        ),
      ],
    );
  }
}

// Stream refresher for auth state changes
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
} 