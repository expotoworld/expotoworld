import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'EXPO to WORLD'**
  String get appTitle;

  /// Generic loading message
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// Retry button text
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Confirm button text
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// Close button label
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Generic loading failed message
  ///
  /// In en, this message translates to:
  /// **'Loading failed'**
  String get loadingFailed;

  /// Message when there is no data
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noData;

  /// No products message
  ///
  /// In en, this message translates to:
  /// **'No products'**
  String get noProducts;

  /// Message when there are no stores
  ///
  /// In en, this message translates to:
  /// **'No stores available'**
  String get noStores;

  /// Processing message
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing;

  /// Email label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Phone label
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// Email input label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// Email input hint
  ///
  /// In en, this message translates to:
  /// **'Enter your email address'**
  String get emailHint;

  /// Phone input label
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneLabel;

  /// Phone input hint
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get phoneHint;

  /// Verification code input hint
  ///
  /// In en, this message translates to:
  /// **'000000'**
  String get verificationCodeHint;

  /// Cart navigation label
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get cart;

  /// Checkout button label
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkout;

  /// Go shopping button label
  ///
  /// In en, this message translates to:
  /// **'Go Shopping'**
  String get goShopping;

  /// Clear cart dialog title
  ///
  /// In en, this message translates to:
  /// **'Clear Cart'**
  String get clearCart;

  /// Clear cart confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear all items from the cart?'**
  String get clearCartConfirm;

  /// Clear store cart confirmation
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear all items from {storeName} cart?'**
  String clearStoreCartConfirm(String storeName);

  /// Total amount message
  ///
  /// In en, this message translates to:
  /// **'Total: €{amount}'**
  String totalAmount(String amount);

  /// Order created success message
  ///
  /// In en, this message translates to:
  /// **'Order created successfully!'**
  String get orderCreatedSuccess;

  /// Cart loading error message
  ///
  /// In en, this message translates to:
  /// **'Failed to load cart: {error}'**
  String cartLoadingFailed(String error);

  /// No store label
  ///
  /// In en, this message translates to:
  /// **'No Store'**
  String get noStore;

  /// Hot recommendations section title
  ///
  /// In en, this message translates to:
  /// **'Hot Recommendations'**
  String get hotRecommendations;

  /// Location label
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// Default city name
  ///
  /// In en, this message translates to:
  /// **'Lugano'**
  String get lugano;

  /// Product search hint
  ///
  /// In en, this message translates to:
  /// **'Search products...'**
  String get searchProducts;

  /// Store search hint
  ///
  /// In en, this message translates to:
  /// **'Search stores...'**
  String get searchStores;

  /// Search hint for ETW to C stores
  ///
  /// In en, this message translates to:
  /// **'Search ETW to C stores...'**
  String get searchEtwToCStores;

  /// Search hint for ETW to U stores
  ///
  /// In en, this message translates to:
  /// **'Search ETW to U stores...'**
  String get searchEtwToUStores;

  /// No ETW to C data message
  ///
  /// In en, this message translates to:
  /// **'No ETW to C data available'**
  String get noEtwToCData;

  /// No ETW to U data message
  ///
  /// In en, this message translates to:
  /// **'No ETW to U data available'**
  String get noEtwToUData;

  /// No store data message
  ///
  /// In en, this message translates to:
  /// **'No store data available'**
  String get noStoreData;

  /// Nearby ETW stores section title
  ///
  /// In en, this message translates to:
  /// **'Nearby ETW Stores ({count})'**
  String nearbyEtwStores(int count);

  /// Map fallback text for showing nearby stores
  ///
  /// In en, this message translates to:
  /// **'Show nearby ETW store locations'**
  String get showNearbyEtwLocations;

  /// Message shown on web for map functionality
  ///
  /// In en, this message translates to:
  /// **'Please view full map functionality on mobile device'**
  String get viewFullMapOnMobile;

  /// Location permission dialog message
  ///
  /// In en, this message translates to:
  /// **'Location permission is required to show your location'**
  String get locationPermissionRequired;

  /// Unable to get location message
  ///
  /// In en, this message translates to:
  /// **'Unable to get current location'**
  String get unableToGetLocation;

  /// Generic location error message
  ///
  /// In en, this message translates to:
  /// **'Location error'**
  String get locationError;

  /// Detailed location error message
  ///
  /// In en, this message translates to:
  /// **'Failed to get location: {error}'**
  String locationErrorDetails(String error);

  /// Navigate button text
  ///
  /// In en, this message translates to:
  /// **'Navigate'**
  String get navigate;

  /// Unable to open maps error
  ///
  /// In en, this message translates to:
  /// **'Unable to open maps app'**
  String get unableToOpenMaps;

  /// Navigation failed message
  ///
  /// In en, this message translates to:
  /// **'Navigation failed: {error}'**
  String navigationFailed(String error);

  /// Enable location permission message
  ///
  /// In en, this message translates to:
  /// **'Please enable location permission in settings, then reopen the app'**
  String get enableLocationInSettings;

  /// Map location failed message
  ///
  /// In en, this message translates to:
  /// **'Map location failed'**
  String get mapLocationFailed;

  /// Placeholder for messaging feature
  ///
  /// In en, this message translates to:
  /// **'Messaging feature in development...'**
  String get messagingInDevelopment;

  /// Placeholder for profile feature
  ///
  /// In en, this message translates to:
  /// **'Profile feature in development...'**
  String get profileInDevelopment;

  /// Order management section title
  ///
  /// In en, this message translates to:
  /// **'Order Management'**
  String get orderManagement;

  /// My orders menu item
  ///
  /// In en, this message translates to:
  /// **'My Orders'**
  String get myOrders;

  /// My favorites menu item
  ///
  /// In en, this message translates to:
  /// **'My Favorites'**
  String get myFavorites;

  /// Browsing history menu item
  ///
  /// In en, this message translates to:
  /// **'Browsing History'**
  String get browsingHistory;

  /// Add to cart error message
  ///
  /// In en, this message translates to:
  /// **'Failed to add to cart, please retry'**
  String get addToCartFailed;

  /// Detailed add to cart error message
  ///
  /// In en, this message translates to:
  /// **'Failed to add to cart: {error}'**
  String addToCartError(String error);

  /// Message when subcategory has no products
  ///
  /// In en, this message translates to:
  /// **'No products available in this subcategory'**
  String get noProductsInSubcategory;

  /// Home navigation label
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// Locations navigation label
  ///
  /// In en, this message translates to:
  /// **'Locations'**
  String get navLocations;

  /// Messages navigation label
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get navMessages;

  /// Profile navigation label
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// App initialization error title
  ///
  /// In en, this message translates to:
  /// **'App Initialization Error'**
  String get appInitError;

  /// Failed to init app error message
  ///
  /// In en, this message translates to:
  /// **'Failed to initialize the app: {error}'**
  String failedToInitApp(String error);

  /// Network error suggestion
  ///
  /// In en, this message translates to:
  /// **'Please check your network connection and retry'**
  String get checkNetworkAndRetry;

  /// No products in category message
  ///
  /// In en, this message translates to:
  /// **'No products in this category'**
  String get noCategoryProducts;

  /// Location permission needed message
  ///
  /// In en, this message translates to:
  /// **'Location permission is required to show your location'**
  String get locationPermissionNeeded;

  /// Get location failed message
  ///
  /// In en, this message translates to:
  /// **'Failed to get location'**
  String get getLocationFailed;

  /// Allow location in settings message
  ///
  /// In en, this message translates to:
  /// **'Please allow location permission in settings, then reopen the app'**
  String get allowLocationInSettings;

  /// Featured products section header
  ///
  /// In en, this message translates to:
  /// **'Featured Products'**
  String get featuredProducts;

  /// Verification code sent to email message
  ///
  /// In en, this message translates to:
  /// **'Verification code sent to email'**
  String get verificationCodeSentEmail;

  /// Verification code sent via SMS message
  ///
  /// In en, this message translates to:
  /// **'Verification code sent via SMS'**
  String get verificationCodeSentPhone;

  /// Clear cart dialog title
  ///
  /// In en, this message translates to:
  /// **'Clear Cart'**
  String get clearCartTitle;

  /// Checkout dialog title
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkoutTitle;

  /// Enter SMS code prompt
  ///
  /// In en, this message translates to:
  /// **'Enter SMS verification code'**
  String get enterSmsCode;

  /// Enter email code prompt
  ///
  /// In en, this message translates to:
  /// **'Enter email verification code'**
  String get enterEmailCode;

  /// Select login method prompt
  ///
  /// In en, this message translates to:
  /// **'Please select login method'**
  String get selectLoginMethod;

  /// Cart empty message
  ///
  /// In en, this message translates to:
  /// **'Your cart is empty'**
  String get cartEmpty;

  /// Add products prompt
  ///
  /// In en, this message translates to:
  /// **'Add some products!'**
  String get addSomeProducts;

  /// Current store label
  ///
  /// In en, this message translates to:
  /// **'Current Store'**
  String get currentStore;

  /// Total amount with value
  ///
  /// In en, this message translates to:
  /// **'Total: €{amount}'**
  String totalAmountValue(String amount);

  /// Confirm payment button
  ///
  /// In en, this message translates to:
  /// **'Confirm Payment'**
  String get confirmPayment;

  /// Cart state error message
  ///
  /// In en, this message translates to:
  /// **'Cart state error, please try again'**
  String get cartStateError;

  /// Order creation failed message
  ///
  /// In en, this message translates to:
  /// **'Order creation failed: {error}'**
  String orderCreationFailed(String error);

  /// Distance unknown label
  ///
  /// In en, this message translates to:
  /// **'Distance unknown'**
  String get distanceUnknown;

  /// Settings label
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// View all link text
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// Stock remaining count
  ///
  /// In en, this message translates to:
  /// **'{count} left'**
  String stockRemaining(int count);

  /// Stock count label
  ///
  /// In en, this message translates to:
  /// **'Stock: {count}'**
  String stock(int count);

  /// Profile screen title
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Default user name placeholder
  ///
  /// In en, this message translates to:
  /// **'Valued User'**
  String get valuedUser;

  /// Order management section title
  ///
  /// In en, this message translates to:
  /// **'Order Management'**
  String get orderManagementSection;

  /// Account settings section title
  ///
  /// In en, this message translates to:
  /// **'Account Settings'**
  String get accountSettings;

  /// Shipping address menu item
  ///
  /// In en, this message translates to:
  /// **'Shipping Address'**
  String get shippingAddress;

  /// Payment methods menu item
  ///
  /// In en, this message translates to:
  /// **'Payment Methods'**
  String get paymentMethods;

  /// Account security menu item
  ///
  /// In en, this message translates to:
  /// **'Account Security'**
  String get accountSecurity;

  /// Help and support section title
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpAndSupport;

  /// Help center menu item
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get helpCenter;

  /// Feedback menu item
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// About us menu item
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get aboutUs;

  /// Logout button text
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logout;

  /// Confirm logout dialog title
  ///
  /// In en, this message translates to:
  /// **'Confirm Logout'**
  String get confirmLogout;

  /// Logout confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get logoutConfirmMessage;

  /// Exit button text
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exit;

  /// Messages screen title
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// Order update notification title
  ///
  /// In en, this message translates to:
  /// **'Order Update'**
  String get orderUpdate;

  /// Order shipped notification message
  ///
  /// In en, this message translates to:
  /// **'Your order #{orderId} has been shipped'**
  String orderShippedMessage(String orderId);

  /// Time ago in minutes
  ///
  /// In en, this message translates to:
  /// **'{count} minutes ago'**
  String minutesAgo(int count);

  /// Time ago in hours
  ///
  /// In en, this message translates to:
  /// **'{count} hours ago'**
  String hoursAgo(int count);

  /// Yesterday time label
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// Promotion notification title
  ///
  /// In en, this message translates to:
  /// **'Promotion'**
  String get promotion;

  /// New arrivals promotion message
  ///
  /// In en, this message translates to:
  /// **'New arrivals, limited time offer!'**
  String get newArrivalsPromo;

  /// System notification title
  ///
  /// In en, this message translates to:
  /// **'System Notification'**
  String get systemNotification;

  /// Welcome message
  ///
  /// In en, this message translates to:
  /// **'Welcome to EXPO to WORLD app'**
  String get welcomeMessage;

  /// No subcategories message
  ///
  /// In en, this message translates to:
  /// **'No subcategories'**
  String get noSubcategories;

  /// Product count label
  ///
  /// In en, this message translates to:
  /// **'{count} products'**
  String productCount(int count);

  /// Select store placeholder text
  ///
  /// In en, this message translates to:
  /// **'Select Store'**
  String get selectStore;

  /// Minimum order quantity label
  ///
  /// In en, this message translates to:
  /// **'Min Order Qty: '**
  String get minimumOrderQuantity;

  /// Add to cart button text
  ///
  /// In en, this message translates to:
  /// **'Add to Cart'**
  String get addToCart;

  /// Login required message for cart
  ///
  /// In en, this message translates to:
  /// **'Please login first to add items to cart'**
  String get pleaseLoginFirst;

  /// Cart initialization error message
  ///
  /// In en, this message translates to:
  /// **'Cart initialization failed, please try again'**
  String get cartInitFailed;

  /// Store selection required message
  ///
  /// In en, this message translates to:
  /// **'Please select a store location first'**
  String get pleaseSelectStoreFirst;

  /// Default city name
  ///
  /// In en, this message translates to:
  /// **'Lugano'**
  String get defaultCity;

  /// Default store name
  ///
  /// In en, this message translates to:
  /// **'Via Nassa Store'**
  String get defaultStoreName;

  /// Featured category name
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get featured;

  /// No products in subcategory message
  ///
  /// In en, this message translates to:
  /// **'No products in this subcategory'**
  String get noSubcategoryProducts;

  /// Enter 6-digit code prompt
  ///
  /// In en, this message translates to:
  /// **'Please enter 6-digit verification code'**
  String get enterSixDigitCode;

  /// Send verification code button
  ///
  /// In en, this message translates to:
  /// **'Send Verification Code'**
  String get sendVerificationCode;

  /// Verify and login button
  ///
  /// In en, this message translates to:
  /// **'Verify and Login'**
  String get verifyAndLogin;

  /// Resend countdown text
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds}s'**
  String resendInSeconds(int seconds);

  /// Resend verification code button
  ///
  /// In en, this message translates to:
  /// **'Resend Verification Code'**
  String get resendVerificationCode;

  /// Email input hint
  ///
  /// In en, this message translates to:
  /// **'Please enter your email address'**
  String get enterEmailAddress;

  /// Email required validation
  ///
  /// In en, this message translates to:
  /// **'Please enter email address'**
  String get pleaseEnterEmail;

  /// Email format validation
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get pleaseEnterValidEmail;

  /// Phone input hint
  ///
  /// In en, this message translates to:
  /// **'Please enter your phone number'**
  String get enterPhoneNumber;

  /// Phone format validation
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number'**
  String get pleaseEnterValidPhone;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
