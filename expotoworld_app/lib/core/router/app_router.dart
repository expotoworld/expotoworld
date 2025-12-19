import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
// Consumer portal imports
import '../../portals/consumer/home/presentation/screens/home_screen.dart';
import '../../portals/consumer/map/presentation/screens/map_screen.dart';
import '../../portals/consumer/messages/presentation/screens/messages_screen.dart';
import '../../portals/consumer/messages/presentation/screens/support_chat_screen.dart';
import '../../portals/consumer/messages/presentation/screens/message_conversation_screen.dart';
import '../../portals/consumer/profile/presentation/screens/profile_screen.dart';
import '../../portals/consumer/profile/presentation/screens/account_settings_screen.dart';
import '../../portals/consumer/profile/presentation/screens/get_help_screen.dart';
import '../../portals/consumer/search/presentation/screens/search_screen.dart';
// Auth (cross-portal)
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
// Shared widgets
import '../../shared/widgets/main_shell.dart';
// Mini-app imports - Core (shared)
import '../../portals/consumer/mini_apps/core/core.dart';
// Mini-app type-specific screens
import '../../portals/consumer/mini_apps/to_b/to_b.dart';
import '../../portals/consumer/mini_apps/to_c/to_c.dart';
import '../../portals/consumer/mini_apps/to_u/to_u.dart';
import '../../portals/consumer/mini_apps/to_x/to_x.dart';

/// Custom codec for serializing/deserializing complex extra data in GoRouter
/// This prevents the warning about complex data types being dropped during serialization
class _AppRouterCodec extends Codec<Object?, Object?> {
  const _AppRouterCodec();

  @override
  Converter<Object?, Object?> get decoder => const _AppRouterDecoder();

  @override
  Converter<Object?, Object?> get encoder => const _AppRouterEncoder();
}

class _AppRouterEncoder extends Converter<Object?, Object?> {
  const _AppRouterEncoder();

  @override
  Object? convert(Object? input) {
    if (input == null) return null;
    if (input is Map<String, dynamic>) {
      final result = <String, dynamic>{};
      for (final entry in input.entries) {
        result[entry.key] = _encodeValue(entry.value);
      }
      return result;
    }
    return input;
  }

  dynamic _encodeValue(dynamic value) {
    if (value is Color) {
      // Encode Color as hex string with marker
      return {'__type': 'Color', 'value': value.toARGB32()};
    } else if (value is IconData) {
      // Encode IconData with codePoint and fontFamily
      return {
        '__type': 'IconData',
        'codePoint': value.codePoint,
        'fontFamily': value.fontFamily,
        'fontPackage': value.fontPackage,
      };
    }
    return value;
  }
}

class _AppRouterDecoder extends Converter<Object?, Object?> {
  const _AppRouterDecoder();

  @override
  Object? convert(Object? input) {
    if (input == null) return null;
    if (input is Map<String, dynamic>) {
      final result = <String, dynamic>{};
      for (final entry in input.entries) {
        result[entry.key] = _decodeValue(entry.value);
      }
      return result;
    }
    return input;
  }

  dynamic _decodeValue(dynamic value) {
    if (value is Map<String, dynamic> && value.containsKey('__type')) {
      final type = value['__type'];
      if (type == 'Color') {
        return Color(value['value'] as int);
      } else if (type == 'IconData') {
        return IconData(
          value['codePoint'] as int,
          fontFamily: value['fontFamily'] as String?,
          fontPackage: value['fontPackage'] as String?,
        );
      }
    }
    return value;
  }
}

/// Route paths constants
class RoutePaths {
  RoutePaths._();

  static const String home = '/';
  static const String map = '/map';
  static const String messages = '/messages';
  static const String messageConversation = '/message-conversation';
  static const String supportChat = '/support-chat';
  static const String profile = '/profile';
  static const String accountSettings = '/account-settings';
  static const String getHelp = '/get-help';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String qrScan = '/qr-scan';
  static const String search = '/search';
  
  // Mini-app routes
  static const String miniApp = '/mini-app';
  static String miniAppHome(String type) => '/mini-app/$type/home';
  static String miniAppCart(String type) => '/mini-app/$type/cart';
  static String miniAppMap(String type) => '/mini-app/$type/map';
  static String miniAppProducts(String type, String subcategoryId) =>
      '/mini-app/$type/products/$subcategoryId';
  static String miniAppServices(String type, String subcategoryId) =>
      '/mini-app/$type/services/$subcategoryId';
}

/// App router configuration
final GoRouter appRouter = GoRouter(
  initialLocation: RoutePaths.home,
  debugLogDiagnostics: false, // Disable debug logging for cleaner console
  extraCodec: const _AppRouterCodec(),
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
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: HomeScreen()),
        ),
        GoRoute(
          path: RoutePaths.map,
          name: 'map',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: MapScreen()),
        ),
        GoRoute(
          path: RoutePaths.messages,
          name: 'messages',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: MessagesScreen()),
        ),
        GoRoute(
          path: RoutePaths.profile,
          name: 'profile',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: ProfileScreen()),
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
          final scaleAnimation = Tween<double>(begin: 0.98, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          );

          return FadeTransition(
            opacity: fadeAnimation,
            child: ScaleTransition(scale: scaleAnimation, child: child),
          );
        },
      ),
    ),
    // Support chat screen (outside shell, no bottom nav)
    GoRoute(
      path: RoutePaths.supportChat,
      name: 'supportChat',
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const SupportChatScreen(),
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Slide in from right transition
          final slideAnimation =
              Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              );

          return SlideTransition(position: slideAnimation, child: child);
        },
      ),
    ),
    // Message conversation screen (outside shell, no bottom nav)
    GoRoute(
      path: RoutePaths.messageConversation,
      name: 'messageConversation',
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return CustomTransitionPage(
          child: MessageConversationScreen(
            messageId: extra?['messageId'] ?? '',
            senderName: extra?['senderName'] ?? 'Unknown',
            senderInitials: extra?['senderInitials'] ?? '?',
            avatarColor: extra?['avatarColor'] ?? Colors.grey,
            typeIcon: extra?['typeIcon'],
            canReply: extra?['canReply'] ?? true,
          ),
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 250),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Slide in from right transition
            final slideAnimation =
                Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                );

            return SlideTransition(position: slideAnimation, child: child);
          },
        );
      },
    ),
    // Account settings screen (outside shell, no bottom nav)
    GoRoute(
      path: RoutePaths.accountSettings,
      name: 'accountSettings',
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const AccountSettingsScreen(),
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Slide in from right transition
          final slideAnimation =
              Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              );

          return SlideTransition(position: slideAnimation, child: child);
        },
      ),
    ),
    // Get help screen (outside shell, no bottom nav)
    GoRoute(
      path: RoutePaths.getHelp,
      name: 'getHelp',
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const GetHelpScreen(),
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Slide in from right transition
          final slideAnimation =
              Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              );

          return SlideTransition(position: slideAnimation, child: child);
        },
      ),
    ),
    // Mini-app route - single entry point with internal tab navigation
    // Uses a single route to preserve navigation stack for proper close animation
    // Tab navigation is handled internally via IndexedStack, not GoRouter
    GoRoute(
      path: '/mini-app/:type',
      name: 'miniApp',
      pageBuilder: (context, state) {
        final miniAppType = _getMiniAppType(state);
        // Default to home tab (index 0)
        final initialTab = state.uri.queryParameters['tab'] ?? 'home';
        final initialTabIndex = switch (initialTab) {
          'cart' => 1,
          'map' => 2,
          _ => 0,
        };
        return CustomTransitionPage(
          child: ProviderScope(
            overrides: [
              currentMiniAppTypeProvider.overrideWith((ref) => miniAppType),
            ],
            child: MiniAppShellWithTabs(
              miniAppType: miniAppType,
              initialTabIndex: initialTabIndex,
            ),
          ),
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 250),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Symmetric vertical transition (slide from/to bottom)
            final slideAnimation =
                Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                );
            return SlideTransition(position: slideAnimation, child: child);
          },
        );
      },
    ),
    // Legacy mini-app routes - redirect to new single route for backwards compatibility
    GoRoute(
      path: '/mini-app/:type/home',
      name: 'miniAppHome',
      redirect: (context, state) {
        final type = state.pathParameters['type'] ?? 'toB';
        return '/mini-app/$type?tab=home';
      },
    ),
    GoRoute(
      path: '/mini-app/:type/cart',
      name: 'miniAppCart',
      redirect: (context, state) {
        final type = state.pathParameters['type'] ?? 'toB';
        return '/mini-app/$type?tab=cart';
      },
    ),
    GoRoute(
      path: '/mini-app/:type/map',
      name: 'miniAppMap',
      redirect: (context, state) {
        final type = state.pathParameters['type'] ?? 'toB';
        return '/mini-app/$type?tab=map';
      },
    ),
    // Mini-app products screen (vertical slide-up for consistency with shell)
    GoRoute(
      path: '/mini-app/:type/products/:subcategoryId',
      name: 'miniAppProducts',
      pageBuilder: (context, state) {
        final typeString = state.pathParameters['type'] ?? 'toB';
        final subcategoryId = state.pathParameters['subcategoryId'] ?? '';
        final miniAppType = MiniAppType.values.firstWhere(
          (e) => e.name == typeString,
          orElse: () => MiniAppType.toB,
        );
        return CustomTransitionPage(
          child: ProviderScope(
            overrides: [
              currentMiniAppTypeProvider.overrideWith((ref) => miniAppType),
            ],
            child: _buildProductsScreen(miniAppType, subcategoryId),
          ),
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 250),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Use vertical animation (same as mini-app shell) for consistency
            final slideAnimation = Tween<Offset>(
              begin: const Offset(0, 1), // Start from bottom
              end: Offset.zero, // End at center
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );
            return SlideTransition(position: slideAnimation, child: child);
          },
        );
      },
    ),
    // Mini-app services screen for toX (vertical slide-up for consistency)
    GoRoute(
      path: '/mini-app/:type/services/:subcategoryId',
      name: 'miniAppServices',
      pageBuilder: (context, state) {
        final subcategoryId = state.pathParameters['subcategoryId'] ?? '';
        return CustomTransitionPage(
          child: ProviderScope(
            overrides: [
              currentMiniAppTypeProvider.overrideWith((ref) => MiniAppType.toX),
            ],
            child: SubcategoryServicesScreen(subcategoryId: subcategoryId),
          ),
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 250),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Use vertical animation (same as mini-app shell) for consistency
            final slideAnimation = Tween<Offset>(
              begin: const Offset(0, 1), // Start from bottom
              end: Offset.zero, // End at center
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );
            return SlideTransition(position: slideAnimation, child: child);
          },
        );
      },
    ),
  ],
  errorBuilder: (context, state) =>
      Scaffold(body: Center(child: Text('Page not found: ${state.uri.path}'))),
);

/// Helper function to extract MiniAppType from GoRouterState
MiniAppType _getMiniAppType(GoRouterState state) {
  final typeString = state.pathParameters['type'] ?? 'toB';
  return MiniAppType.values.firstWhere(
    (e) => e.name == typeString,
    orElse: () => MiniAppType.toB,
  );
}

/// Build the products screen based on mini-app type
Widget _buildProductsScreen(MiniAppType miniAppType, String subcategoryId) {
  switch (miniAppType) {
    case MiniAppType.toB:
      return ToBProductsScreen(subcategoryId: subcategoryId);
    case MiniAppType.toC:
      return ToCProductsScreen(subcategoryId: subcategoryId);
    case MiniAppType.toU:
      return ToUProductsScreen(subcategoryId: subcategoryId);
    case MiniAppType.toX:
      // toX doesn't have products, only services
      return const SizedBox(); // This shouldn't happen
  }
}

/// App router provider for Riverpod
final appRouterProvider = Provider<GoRouter>((ref) => appRouter);
