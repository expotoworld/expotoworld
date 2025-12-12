import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/map/presentation/screens/map_screen.dart';
import '../../features/messages/presentation/screens/messages_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import '../../shared/widgets/main_shell.dart';

/// Route paths constants
class RoutePaths {
  RoutePaths._();

  static const String home = '/';
  static const String map = '/map';
  static const String messages = '/messages';
  static const String profile = '/profile';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String qrScan = '/qr-scan';
  static const String search = '/search';
}

/// App router configuration
final GoRouter appRouter = GoRouter(
  initialLocation: RoutePaths.home,
  debugLogDiagnostics: true,
  routes: [
    // Main shell with bottom navigation
    ShellRoute(
      builder: (context, state, child) {
        return MainShell(child: child);
      },
      routes: [
        GoRoute(
          path: RoutePaths.home,
          name: 'home',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: HomeScreen(),
          ),
        ),
        GoRoute(
          path: RoutePaths.map,
          name: 'map',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: MapScreen(),
          ),
        ),
        GoRoute(
          path: RoutePaths.messages,
          name: 'messages',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: MessagesScreen(),
          ),
        ),
        GoRoute(
          path: RoutePaths.profile,
          name: 'profile',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ProfileScreen(),
          ),
        ),
      ],
    ),
    // Auth routes (outside shell)
    GoRoute(
      path: RoutePaths.login,
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: RoutePaths.signup,
      name: 'signup',
      builder: (context, state) => const SignupScreen(),
    ),
    // Search screen (outside shell, premium fade transition)
    GoRoute(
      path: RoutePaths.search,
      name: 'search',
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const SearchScreen(),
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Premium cross-fade with subtle scale
          final fadeAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          final scaleAnimation = Tween<double>(
            begin: 0.98,
            end: 1.0,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ));
          
          return FadeTransition(
            opacity: fadeAnimation,
            child: ScaleTransition(
              scale: scaleAnimation,
              child: child,
            ),
          );
        },
      ),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text('Page not found: ${state.uri.path}'),
    ),
  ),
);

/// App router provider for Riverpod
final appRouterProvider = Provider<GoRouter>((ref) => appRouter);
