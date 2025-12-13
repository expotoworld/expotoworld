import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'EXPO to WORLD'**
  String get appTitle;

  /// Bottom navigation label for Home tab
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// Bottom navigation label for Map tab
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get navMap;

  /// Bottom navigation label for Messages tab
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get navMessages;

  /// Bottom navigation label for Profile tab
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// Placeholder text for the search bar
  ///
  /// In en, this message translates to:
  /// **'Search products, stores, manufacturers...'**
  String get searchPlaceholder;

  /// Welcome message on home screen
  ///
  /// In en, this message translates to:
  /// **'Welcome to EXPO to WORLD'**
  String get homeWelcome;

  /// Subtitle on home screen
  ///
  /// In en, this message translates to:
  /// **'Your gateway to premium global retail'**
  String get homeSubtitle;

  /// B2B Exposition sub-app title
  ///
  /// In en, this message translates to:
  /// **'to B'**
  String get subAppToB;

  /// B2B Exposition sub-app description
  ///
  /// In en, this message translates to:
  /// **'B2B Exposition'**
  String get subAppToBDescription;

  /// B2C Exposition sub-app title
  ///
  /// In en, this message translates to:
  /// **'to C'**
  String get subAppToC;

  /// B2C Exposition sub-app description
  ///
  /// In en, this message translates to:
  /// **'B2C Marketplace'**
  String get subAppToCDescription;

  /// Automated Stores sub-app title
  ///
  /// In en, this message translates to:
  /// **'to U'**
  String get subAppToU;

  /// Automated Stores sub-app description
  ///
  /// In en, this message translates to:
  /// **'Automated Stores'**
  String get subAppToUDescription;

  /// Group Buying sub-app title
  ///
  /// In en, this message translates to:
  /// **'to X'**
  String get subAppToX;

  /// Group Buying sub-app description
  ///
  /// In en, this message translates to:
  /// **'Group Buying'**
  String get subAppToXDescription;

  /// B2B store name
  ///
  /// In en, this message translates to:
  /// **'EXPO MEGA'**
  String get storeMega;

  /// B2C store name
  ///
  /// In en, this message translates to:
  /// **'EXPO MARKET'**
  String get storeMarket;

  /// Automated convenience store name (bulk items)
  ///
  /// In en, this message translates to:
  /// **'EXPO GO'**
  String get storeGo;

  /// Automated convenience store name (premium items)
  ///
  /// In en, this message translates to:
  /// **'EXPO XPRESS'**
  String get storeXpress;

  /// Profile screen title
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// Settings section in profile
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get profileSettings;

  /// Language setting label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get profileLanguage;

  /// Theme setting label
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get profileTheme;

  /// Dark mode toggle label
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get profileDarkMode;

  /// Light mode toggle label
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get profileLightMode;

  /// System theme mode label
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get profileSystemMode;

  /// Notifications setting label
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get profileNotifications;

  /// ID Verification section label
  ///
  /// In en, this message translates to:
  /// **'ID Verification'**
  String get profileIdVerification;

  /// Verified status label
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get profileVerified;

  /// Not verified status label
  ///
  /// In en, this message translates to:
  /// **'Not Verified'**
  String get profileNotVerified;

  /// Payment methods section label
  ///
  /// In en, this message translates to:
  /// **'Payment Methods'**
  String get profilePaymentMethods;

  /// Help and support section label
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get profileHelpSupport;

  /// FAQ link label
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get profileFaq;

  /// Contact us link label
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get profileContact;

  /// Privacy policy link label
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get profilePrivacy;

  /// Terms of service link label
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get profileTerms;

  /// Log out button label
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get profileLogout;

  /// Log in button label
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get profileLogin;

  /// Sign up button label
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get profileSignup;

  /// My orders section label
  ///
  /// In en, this message translates to:
  /// **'My Orders'**
  String get profileMyOrders;

  /// My favorites section label
  ///
  /// In en, this message translates to:
  /// **'My Favorites'**
  String get profileMyFavorites;

  /// Edit profile button label
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get profileEditProfile;

  /// Map screen title
  ///
  /// In en, this message translates to:
  /// **'Store Locations'**
  String get mapTitle;

  /// Nearby stores section label
  ///
  /// In en, this message translates to:
  /// **'Nearby Stores'**
  String get mapNearbyStores;

  /// Message when no stores are found
  ///
  /// In en, this message translates to:
  /// **'No stores found nearby'**
  String get mapNoStoresFound;

  /// Messages screen title
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messagesTitle;

  /// Empty messages state
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get messagesEmpty;

  /// Notifications tab label
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get messagesNotifications;

  /// Chat tab label
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get messagesChat;

  /// Login screen title
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get authLogin;

  /// Signup screen title
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get authSignup;

  /// Email field label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmail;

  /// Password field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// Phone number field label
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get authPhone;

  /// Verification code field label
  ///
  /// In en, this message translates to:
  /// **'Verification Code'**
  String get authVerificationCode;

  /// Send verification code button
  ///
  /// In en, this message translates to:
  /// **'Send Code'**
  String get authSendCode;

  /// Forgot password link
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get authForgotPassword;

  /// No account prompt
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get authNoAccount;

  /// Have account prompt
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get authHaveAccount;

  /// Continue button label
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get commonContinue;

  /// Cancel button label
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// Save button label
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// Delete button label
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// Edit button label
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// Loading state text
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get commonLoading;

  /// Generic error message
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get commonError;

  /// Retry button label
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// See all link label
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get commonSeeAll;

  /// Coming soon placeholder text
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get commonComingSoon;

  /// Price label
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get productPrice;

  /// Add to cart button
  ///
  /// In en, this message translates to:
  /// **'Add to Cart'**
  String get productAddToCart;

  /// Buy now button
  ///
  /// In en, this message translates to:
  /// **'Buy Now'**
  String get productBuyNow;

  /// Manufacturer label
  ///
  /// In en, this message translates to:
  /// **'Manufacturer'**
  String get productManufacturer;

  /// Contact manufacturer button
  ///
  /// In en, this message translates to:
  /// **'Contact Manufacturer'**
  String get productContactManufacturer;

  /// QR scan screen title
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get qrScanTitle;

  /// QR scan instructions
  ///
  /// In en, this message translates to:
  /// **'Point your camera at the QR code'**
  String get qrScanInstructions;

  /// Welcome back title on login screen
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get authWelcomeBack;

  /// Sign in subtitle on login screen
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue to Made in World'**
  String get authSignInToContinue;

  /// Email field hint text
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get authEmailHint;

  /// Password field hint text
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get authPasswordHint;

  /// Sign in button text
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get authSignIn;

  /// Create account title/button
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get authCreateAccount;

  /// Create account subtitle
  ///
  /// In en, this message translates to:
  /// **'Join Made in World and discover authentic products'**
  String get authJoinMadeInWorld;

  /// Full name field label
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get authFullName;

  /// Full name field hint
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get authFullNameHint;

  /// Phone number field hint
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get authPhoneHint;

  /// Create password hint
  ///
  /// In en, this message translates to:
  /// **'Create a password'**
  String get authPasswordCreateHint;

  /// Confirm password field label
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get authConfirmPassword;

  /// Confirm password field hint
  ///
  /// In en, this message translates to:
  /// **'Confirm your password'**
  String get authConfirmPasswordHint;

  /// Terms agreement prefix
  ///
  /// In en, this message translates to:
  /// **'I agree to the '**
  String get authAgreeToTerms;

  /// Terms of service link text
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get authTermsOfService;

  /// And conjunction
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get authAnd;

  /// Privacy policy link text
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get authPrivacyPolicy;

  /// Already have account prompt
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get authAlreadyHaveAccount;

  /// Preferences section title
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get profilePreferences;

  /// Account section title
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get profileAccount;

  /// Orders and support section title
  ///
  /// In en, this message translates to:
  /// **'Orders & Support'**
  String get profileOrdersAndSupport;

  /// About section title
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get profileAbout;

  /// Notifications setting subtitle
  ///
  /// In en, this message translates to:
  /// **'Manage notification preferences'**
  String get profileManageNotifications;

  /// Personal information title
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get profilePersonalInfo;

  /// Personal information subtitle
  ///
  /// In en, this message translates to:
  /// **'Name, email, phone'**
  String get profilePersonalInfoSubtitle;

  /// Shipping addresses title
  ///
  /// In en, this message translates to:
  /// **'Shipping Addresses'**
  String get profileShippingAddresses;

  /// Number of addresses saved
  ///
  /// In en, this message translates to:
  /// **'{count} addresses saved'**
  String profileAddressesSaved(int count);

  /// Payment methods subtitle
  ///
  /// In en, this message translates to:
  /// **'Cards, Alipay, WeChat Pay'**
  String get profilePaymentSubtitle;

  /// Order history title
  ///
  /// In en, this message translates to:
  /// **'Order History'**
  String get profileOrderHistory;

  /// Order history subtitle
  ///
  /// In en, this message translates to:
  /// **'View all past orders'**
  String get profileViewAllOrders;

  /// Wishlist title
  ///
  /// In en, this message translates to:
  /// **'Wishlist'**
  String get profileWishlist;

  /// Number of items saved
  ///
  /// In en, this message translates to:
  /// **'{count} items saved'**
  String profileItemsSaved(int count);

  /// Customer support title
  ///
  /// In en, this message translates to:
  /// **'Customer Support'**
  String get profileCustomerSupport;

  /// Customer support subtitle
  ///
  /// In en, this message translates to:
  /// **'Get help with your orders'**
  String get profileGetHelp;

  /// About app title
  ///
  /// In en, this message translates to:
  /// **'About Made in World'**
  String get profileAboutApp;

  /// App version
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String profileVersion(String version);

  /// Terms and privacy title
  ///
  /// In en, this message translates to:
  /// **'Terms & Privacy'**
  String get profileTermsPrivacy;

  /// Terms and privacy subtitle
  ///
  /// In en, this message translates to:
  /// **'Legal information'**
  String get profileLegalInfo;

  /// Gold member badge text
  ///
  /// In en, this message translates to:
  /// **'Gold Member'**
  String get profileGoldMember;

  /// Toggle on state
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get profileOn;

  /// Toggle off state
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get profileOff;

  /// Orders stat label
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get profileOrders;

  /// Points stat label
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get profilePoints;

  /// Coupons stat label
  ///
  /// In en, this message translates to:
  /// **'Coupons'**
  String get profileCoupons;

  /// All messages filter
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get messagesFilterAll;

  /// Unread messages filter
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get messagesFilterUnread;

  /// System messages filter
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get messagesFilterSystem;

  /// Support messages filter
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get messagesFilterSupport;

  /// Orders messages filter
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get messagesFilterOrders;

  /// Empty messages state title
  ///
  /// In en, this message translates to:
  /// **'No messages found'**
  String get messagesNoMessages;

  /// Search empty state hint
  ///
  /// In en, this message translates to:
  /// **'Try a different search term'**
  String get messagesTryDifferentSearch;

  /// Empty messages state hint
  ///
  /// In en, this message translates to:
  /// **'Messages will appear here'**
  String get messagesWillAppear;

  /// Messages search hint
  ///
  /// In en, this message translates to:
  /// **'Search messages...'**
  String get messagesSearchHint;

  /// Map search hint
  ///
  /// In en, this message translates to:
  /// **'Search stores...'**
  String get mapSearchHint;

  /// Error opening maps
  ///
  /// In en, this message translates to:
  /// **'Could not open maps'**
  String get mapCouldNotOpen;

  /// Directions button
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get mapDirections;

  /// Visit store button
  ///
  /// In en, this message translates to:
  /// **'Visit Store'**
  String get mapVisitStore;

  /// Distance away text
  ///
  /// In en, this message translates to:
  /// **'{distance} away'**
  String mapAway(String distance);

  /// Location services disabled error
  ///
  /// In en, this message translates to:
  /// **'Location services disabled'**
  String get mapLocationServicesDisabled;

  /// Location permission denied error
  ///
  /// In en, this message translates to:
  /// **'Location permission denied'**
  String get mapLocationPermissionDenied;

  /// Location permanently denied error
  ///
  /// In en, this message translates to:
  /// **'Location permanently denied'**
  String get mapLocationPermanentlyDenied;

  /// Could not get location error
  ///
  /// In en, this message translates to:
  /// **'Could not get location'**
  String get mapCouldNotGetLocation;

  /// Visiting store snackbar
  ///
  /// In en, this message translates to:
  /// **'Visiting {storeName}...'**
  String mapVisiting(String storeName);

  /// Search screen hint
  ///
  /// In en, this message translates to:
  /// **'Search products, stores...'**
  String get searchHint;

  /// Cancel search button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get searchCancel;

  /// Recent searches section title
  ///
  /// In en, this message translates to:
  /// **'Recent Searches'**
  String get searchRecentSearches;

  /// Popular searches section title
  ///
  /// In en, this message translates to:
  /// **'Popular Right Now'**
  String get searchPopular;

  /// Browse by category section title
  ///
  /// In en, this message translates to:
  /// **'Browse by Category'**
  String get searchBrowseByCategory;

  /// Searching for text
  ///
  /// In en, this message translates to:
  /// **'Searching for \"{query}\"'**
  String searchSearchingFor(String query);

  /// Search results placeholder
  ///
  /// In en, this message translates to:
  /// **'Results will appear here'**
  String get searchResultsWillAppear;

  /// Fashion category name
  ///
  /// In en, this message translates to:
  /// **'Fashion & Apparel'**
  String get categoryFashion;

  /// Electronics category name
  ///
  /// In en, this message translates to:
  /// **'Electronics'**
  String get categoryElectronics;

  /// Food category name
  ///
  /// In en, this message translates to:
  /// **'Food & Beverage'**
  String get categoryFood;

  /// Home category name
  ///
  /// In en, this message translates to:
  /// **'Home & Living'**
  String get categoryHome;

  /// Health category name
  ///
  /// In en, this message translates to:
  /// **'Health & Beauty'**
  String get categoryHealth;

  /// Support screen title
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get supportTitle;

  /// Support online status
  ///
  /// In en, this message translates to:
  /// **'Online • Usually replies instantly'**
  String get supportOnline;

  /// Support chat input hint
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get supportTypeMessage;

  /// Support welcome message
  ///
  /// In en, this message translates to:
  /// **'Hello! 👋 I\'m your EXPO to WORLD support assistant. How can I help you today?'**
  String get supportWelcomeMessage;

  /// Support auto reply message
  ///
  /// In en, this message translates to:
  /// **'Thank you for your message! Our team is looking into this. Is there anything else I can help you with?'**
  String get supportAutoReply;

  /// Featured products section title
  ///
  /// In en, this message translates to:
  /// **'Featured Products'**
  String get homeFeaturedProducts;

  /// Search bar text
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get homeSearch;

  /// Welcome promo title
  ///
  /// In en, this message translates to:
  /// **'Welcome to EXPO to WORLD'**
  String get promoWelcomeTitle;

  /// Welcome promo subtitle
  ///
  /// In en, this message translates to:
  /// **'Your gateway to premium global retail'**
  String get promoWelcomeSubtitle;

  /// New arrivals promo title
  ///
  /// In en, this message translates to:
  /// **'New Arrivals'**
  String get promoNewArrivalsTitle;

  /// New arrivals promo subtitle
  ///
  /// In en, this message translates to:
  /// **'Discover the latest products from top manufacturers'**
  String get promoNewArrivalsSubtitle;

  /// Group deals promo title
  ///
  /// In en, this message translates to:
  /// **'Group Deals'**
  String get promoGroupDealsTitle;

  /// Group deals promo subtitle
  ///
  /// In en, this message translates to:
  /// **'Join now and save up to 40%'**
  String get promoGroupDealsSubtitle;
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
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
