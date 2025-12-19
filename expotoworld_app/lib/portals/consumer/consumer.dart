// Consumer Portal
//
// The main end-user shopping experience with:
// - Home screen with 4 mini-app tiles (toB, toC, toU, toX)
// - Mini-app ecosystems for shopping
// - Profile, messages, search, and map features

// Home
export 'home/presentation/screens/home_screen.dart';

// Mini Apps
export 'mini_apps/mini_apps.dart';

// Profile
export 'profile/presentation/screens/profile_screen.dart';
export 'profile/presentation/screens/account_settings_screen.dart';
export 'profile/presentation/screens/get_help_screen.dart';

// Messages
export 'messages/presentation/screens/messages_screen.dart';
export 'messages/presentation/screens/support_chat_screen.dart';
export 'messages/presentation/screens/message_conversation_screen.dart';

// Search
export 'search/presentation/screens/search_screen.dart';

// Map - hide StoreType to avoid conflict with mini_apps version
export 'map/presentation/screens/map_screen.dart' hide StoreType, StoreTypeExtension;
