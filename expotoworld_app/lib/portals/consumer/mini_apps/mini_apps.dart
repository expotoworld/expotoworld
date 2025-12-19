/// Mini-apps feature for expotoworld
/// 
/// This module provides the 4 mini-app ecosystems:
/// - **toB**: Business-to-Business with MOQ, bulk pricing
/// - **toC**: Business-to-Consumer with reviews, wishlists
/// - **toU**: Business-to-User (volume-based) with tier pricing
/// - **toX**: Services marketplace with quote requests
/// 
/// ## Architecture
/// 
/// The module follows a composition-based architecture:
/// - `core/` - Shared 70% of functionality (base classes, widgets, providers)
/// - `to_b/`, `to_c/`, `to_u/`, `to_x/` - Type-specific 30% customizations
/// 
/// ## Usage
/// 
/// Import the specific type you need:
/// ```dart
/// import 'package:expotoworld_app/features/mini_apps/to_b/to_b.dart';
/// ```
/// 
/// Or import the core for shared functionality:
/// ```dart
/// import 'package:expotoworld_app/features/mini_apps/core/core.dart';
/// ```
library;

// Re-export core
export 'core/core.dart';

// Re-export type-specific modules
export 'to_b/to_b.dart';
export 'to_c/to_c.dart';
export 'to_u/to_u.dart';
export 'to_x/to_x.dart';
