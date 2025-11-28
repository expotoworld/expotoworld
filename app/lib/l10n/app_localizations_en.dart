// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'EXPO to WORLD';

  @override
  String get loading => 'Loading...';

  @override
  String get retry => 'Retry';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get close => 'Close';

  @override
  String get loadingFailed => 'Loading failed';

  @override
  String get noData => 'No data available';

  @override
  String get noProducts => 'No products';

  @override
  String get noStores => 'No stores available';

  @override
  String get processing => 'Processing...';

  @override
  String get email => 'Email';

  @override
  String get phone => 'Phone';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailHint => 'Enter your email address';

  @override
  String get phoneLabel => 'Phone Number';

  @override
  String get phoneHint => 'Enter your phone number';

  @override
  String get verificationCodeHint => '000000';

  @override
  String get cart => 'Cart';

  @override
  String get checkout => 'Checkout';

  @override
  String get goShopping => 'Go Shopping';

  @override
  String get clearCart => 'Clear Cart';

  @override
  String get clearCartConfirm =>
      'Are you sure you want to clear all items from the cart?';

  @override
  String clearStoreCartConfirm(String storeName) {
    return 'Are you sure you want to clear all items from $storeName cart?';
  }

  @override
  String totalAmount(String amount) {
    return 'Total: €$amount';
  }

  @override
  String get orderCreatedSuccess => 'Order created successfully!';

  @override
  String cartLoadingFailed(String error) {
    return 'Failed to load cart: $error';
  }

  @override
  String get noStore => 'No Store';

  @override
  String get hotRecommendations => 'Hot Recommendations';

  @override
  String get location => 'Location';

  @override
  String get lugano => 'Lugano';

  @override
  String get searchProducts => 'Search products...';

  @override
  String get searchStores => 'Search stores...';

  @override
  String get searchEtwToCStores => 'Search ETW to C stores...';

  @override
  String get searchEtwToUStores => 'Search ETW to U stores...';

  @override
  String get noEtwToCData => 'No ETW to C data available';

  @override
  String get noEtwToUData => 'No ETW to U data available';

  @override
  String get noStoreData => 'No store data available';

  @override
  String nearbyEtwStores(int count) {
    return 'Nearby ETW Stores ($count)';
  }

  @override
  String get showNearbyEtwLocations => 'Show nearby ETW store locations';

  @override
  String get viewFullMapOnMobile =>
      'Please view full map functionality on mobile device';

  @override
  String get locationPermissionRequired =>
      'Location permission is required to show your location';

  @override
  String get unableToGetLocation => 'Unable to get current location';

  @override
  String get locationError => 'Location error';

  @override
  String locationErrorDetails(String error) {
    return 'Failed to get location: $error';
  }

  @override
  String get navigate => 'Navigate';

  @override
  String get unableToOpenMaps => 'Unable to open maps app';

  @override
  String navigationFailed(String error) {
    return 'Navigation failed: $error';
  }

  @override
  String get enableLocationInSettings =>
      'Please enable location permission in settings, then reopen the app';

  @override
  String get mapLocationFailed => 'Map location failed';

  @override
  String get messagingInDevelopment => 'Messaging feature in development...';

  @override
  String get profileInDevelopment => 'Profile feature in development...';

  @override
  String get orderManagement => 'Order Management';

  @override
  String get myOrders => 'My Orders';

  @override
  String get myFavorites => 'My Favorites';

  @override
  String get browsingHistory => 'Browsing History';

  @override
  String get addToCartFailed => 'Failed to add to cart, please retry';

  @override
  String addToCartError(String error) {
    return 'Failed to add to cart: $error';
  }

  @override
  String get noProductsInSubcategory =>
      'No products available in this subcategory';

  @override
  String get navHome => 'Home';

  @override
  String get navLocations => 'Locations';

  @override
  String get navMessages => 'Messages';

  @override
  String get navProfile => 'Profile';

  @override
  String get appInitError => 'App Initialization Error';

  @override
  String failedToInitApp(String error) {
    return 'Failed to initialize the app: $error';
  }

  @override
  String get checkNetworkAndRetry =>
      'Please check your network connection and retry';

  @override
  String get noCategoryProducts => 'No products in this category';

  @override
  String get locationPermissionNeeded =>
      'Location permission is required to show your location';

  @override
  String get getLocationFailed => 'Failed to get location';

  @override
  String get allowLocationInSettings =>
      'Please allow location permission in settings, then reopen the app';

  @override
  String get featuredProducts => 'Featured Products';

  @override
  String get verificationCodeSentEmail => 'Verification code sent to email';

  @override
  String get verificationCodeSentPhone => 'Verification code sent via SMS';

  @override
  String get clearCartTitle => 'Clear Cart';

  @override
  String get checkoutTitle => 'Checkout';

  @override
  String get enterSmsCode => 'Enter SMS verification code';

  @override
  String get enterEmailCode => 'Enter email verification code';

  @override
  String get selectLoginMethod => 'Please select login method';

  @override
  String get cartEmpty => 'Your cart is empty';

  @override
  String get addSomeProducts => 'Add some products!';

  @override
  String get currentStore => 'Current Store';

  @override
  String totalAmountValue(String amount) {
    return 'Total: €$amount';
  }

  @override
  String get confirmPayment => 'Confirm Payment';

  @override
  String get cartStateError => 'Cart state error, please try again';

  @override
  String orderCreationFailed(String error) {
    return 'Order creation failed: $error';
  }

  @override
  String get distanceUnknown => 'Distance unknown';

  @override
  String get settings => 'Settings';

  @override
  String get viewAll => 'View All';

  @override
  String stockRemaining(int count) {
    return '$count left';
  }

  @override
  String stock(int count) {
    return 'Stock: $count';
  }

  @override
  String get profile => 'Profile';

  @override
  String get valuedUser => 'Valued User';

  @override
  String get orderManagementSection => 'Order Management';

  @override
  String get accountSettings => 'Account Settings';

  @override
  String get shippingAddress => 'Shipping Address';

  @override
  String get paymentMethods => 'Payment Methods';

  @override
  String get accountSecurity => 'Account Security';

  @override
  String get helpAndSupport => 'Help & Support';

  @override
  String get helpCenter => 'Help Center';

  @override
  String get feedback => 'Feedback';

  @override
  String get aboutUs => 'About Us';

  @override
  String get logout => 'Log Out';

  @override
  String get confirmLogout => 'Confirm Logout';

  @override
  String get logoutConfirmMessage => 'Are you sure you want to log out?';

  @override
  String get exit => 'Exit';

  @override
  String get messages => 'Messages';

  @override
  String get orderUpdate => 'Order Update';

  @override
  String orderShippedMessage(String orderId) {
    return 'Your order #$orderId has been shipped';
  }

  @override
  String minutesAgo(int count) {
    return '$count minutes ago';
  }

  @override
  String hoursAgo(int count) {
    return '$count hours ago';
  }

  @override
  String get yesterday => 'Yesterday';

  @override
  String get promotion => 'Promotion';

  @override
  String get newArrivalsPromo => 'New arrivals, limited time offer!';

  @override
  String get systemNotification => 'System Notification';

  @override
  String get welcomeMessage => 'Welcome to EXPO to WORLD app';

  @override
  String get noSubcategories => 'No subcategories';

  @override
  String productCount(int count) {
    return '$count products';
  }

  @override
  String get selectStore => 'Select Store';

  @override
  String get minimumOrderQuantity => 'Min Order Qty: ';

  @override
  String get addToCart => 'Add to Cart';

  @override
  String get pleaseLoginFirst => 'Please login first to add items to cart';

  @override
  String get cartInitFailed => 'Cart initialization failed, please try again';

  @override
  String get pleaseSelectStoreFirst => 'Please select a store location first';

  @override
  String get defaultCity => 'Lugano';

  @override
  String get defaultStoreName => 'Via Nassa Store';

  @override
  String get featured => 'Featured';

  @override
  String get noSubcategoryProducts => 'No products in this subcategory';

  @override
  String get enterSixDigitCode => 'Please enter 6-digit verification code';

  @override
  String get sendVerificationCode => 'Send Verification Code';

  @override
  String get verifyAndLogin => 'Verify and Login';

  @override
  String resendInSeconds(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get resendVerificationCode => 'Resend Verification Code';

  @override
  String get enterEmailAddress => 'Please enter your email address';

  @override
  String get pleaseEnterEmail => 'Please enter email address';

  @override
  String get pleaseEnterValidEmail => 'Please enter a valid email address';

  @override
  String get enterPhoneNumber => 'Please enter your phone number';

  @override
  String get pleaseEnterValidPhone => 'Please enter a valid phone number';
}
