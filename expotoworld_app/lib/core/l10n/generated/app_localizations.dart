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
