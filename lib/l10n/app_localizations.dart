import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_it.dart';
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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('it'),
    Locale('zh')
  ];

  /// Application title
  ///
  /// In en, this message translates to:
  /// **'OUHUA RISTOO(Waiter)'**
  String get appTitle;

  /// Please enter your login name
  ///
  /// In en, this message translates to:
  /// **'Please enter your login name'**
  String get pleaseEnterLoginName;

  /// Please enter the password
  ///
  /// In en, this message translates to:
  /// **'Please enter the password'**
  String get pleaseEnterPassword;

  /// Login
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// Copyright information
  ///
  /// In en, this message translates to:
  /// **'©2025 Ouhua Zhichuang (Hangzhou) Technology Co., Ltd.'**
  String get copyright;

  /// Account cannot be empty
  ///
  /// In en, this message translates to:
  /// **'Account cannot be empty'**
  String get loginNameCannotBeEmpty;

  /// Password cannot be empty
  ///
  /// In en, this message translates to:
  /// **'Password cannot be empty.'**
  String get passwordCannotBeEmpty;

  /// Incorrect Password
  ///
  /// In en, this message translates to:
  /// **'Incorrect Password'**
  String get incorrectPassword;

  /// Login Successful
  ///
  /// In en, this message translates to:
  /// **'Login Successful'**
  String get loginSuccessful;

  /// Login failed, please retry
  ///
  /// In en, this message translates to:
  /// **'Login failed, please retry'**
  String get loginFailedPleaseRetry;

  /// The account has been logged in on another device
  ///
  /// In en, this message translates to:
  /// **'The account has been logged in on another device'**
  String get accountLoggedInOnAnotherDevice;

  /// Table
  ///
  /// In en, this message translates to:
  /// **'Table '**
  String get table;

  /// More
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// Merge Tables
  ///
  /// In en, this message translates to:
  /// **'Merge Tables'**
  String get mergeTables;

  /// Clear Table
  ///
  /// In en, this message translates to:
  /// **'Clear Table'**
  String get clearTable;

  /// Close Table
  ///
  /// In en, this message translates to:
  /// **'Close Table'**
  String get closeTable;

  /// Confirm
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// Including Tables
  ///
  /// In en, this message translates to:
  /// **'Including Tables'**
  String get includingTables;

  /// Select Table
  ///
  /// In en, this message translates to:
  /// **'Select Table'**
  String get selectTable;

  /// Reason
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reason;

  /// Cancel
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Table People
  ///
  /// In en, this message translates to:
  /// **'Table People'**
  String get tablePeople;

  /// Adults
  ///
  /// In en, this message translates to:
  /// **'Adults'**
  String get adults;

  /// Children
  ///
  /// In en, this message translates to:
  /// **'Children'**
  String get children;

  /// Select Menu
  ///
  /// In en, this message translates to:
  /// **'Select Menu'**
  String get selectMenu;

  /// Start Ordering
  ///
  /// In en, this message translates to:
  /// **'Start Ordering'**
  String get startOrdering;

  /// The current table is unavailable
  ///
  /// In en, this message translates to:
  /// **'The current table is unavailable'**
  String get currentTableUnavailable;

  /// Only one of the following non - free tables can be selected
  ///
  /// In en, this message translates to:
  /// **'Only one of the following non - free tables can be selected.'**
  String get onlyOneNonFreeTableCanBeSelected;

  /// Please select the number of diners
  ///
  /// In en, this message translates to:
  /// **'Please select the number of diners'**
  String get pleaseSelectNumberOfDiners;

  /// Standard number of adults for this table
  ///
  /// In en, this message translates to:
  /// **'Standard number of adults for this table: '**
  String get standardAdultsForThisTable;

  /// Standard number of children for this table
  ///
  /// In en, this message translates to:
  /// **'Standard number of children for this table:'**
  String get standardChildrenForThisTable;

  /// Please select a menu
  ///
  /// In en, this message translates to:
  /// **'Please select a menu'**
  String get pleaseSelectMenu;

  /// Merge successful
  ///
  /// In en, this message translates to:
  /// **'Merge successful'**
  String get mergeSuccessful;

  /// Merge failed, please retry
  ///
  /// In en, this message translates to:
  /// **'Merge failed, please retry.'**
  String get mergeFailedPleaseRetry;

  /// When removing tables, one table must remain
  ///
  /// In en, this message translates to:
  /// **'When removing tables, one table must remain.'**
  String get oneTableMustRemainWhenRemoving;

  /// Table removal successful
  ///
  /// In en, this message translates to:
  /// **'Table removal successful'**
  String get tableRemovalSuccessful;

  /// Table removal failed, please retry
  ///
  /// In en, this message translates to:
  /// **'Table removal failed, please retry'**
  String get tableRemovalFailedPleaseRetry;

  /// Table closing successful
  ///
  /// In en, this message translates to:
  /// **'Table closing successful'**
  String get tableClosingSuccessful;

  /// Table closing failed, please retry
  ///
  /// In en, this message translates to:
  /// **'Table closing failed, please retry'**
  String get tableClosingFailedPleaseRetry;

  /// Table opening successful
  ///
  /// In en, this message translates to:
  /// **'Table opening successful'**
  String get tableOpeningSuccessful;

  /// Table opening failed, please retry
  ///
  /// In en, this message translates to:
  /// **'Table opening failed, please retry'**
  String get tableOpeningFailedPleaseRetry;

  /// Please enter the last 4 digits of the reserved phone number
  ///
  /// In en, this message translates to:
  /// **'Please enter the last 4 digits of the reserved phone number?'**
  String get pleaseEnterLast4DigitsOfReservedPhone;

  /// The number is incorrect, please re-enter
  ///
  /// In en, this message translates to:
  /// **'The number is incorrect, please re-enter'**
  String get numberIncorrectPleaseReenter;

  /// The number is correct. Enjoy your meal
  ///
  /// In en, this message translates to:
  /// **'The number is correct. Enjoy your meal!'**
  String get numberCorrectEnjoyYourMeal;

  /// Menu
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

  /// Ordered
  ///
  /// In en, this message translates to:
  /// **'Ordered'**
  String get ordered;

  /// Enter dish code or name
  ///
  /// In en, this message translates to:
  /// **'Enter dish code or name'**
  String get enterDishCodeOrName;

  /// Select specification
  ///
  /// In en, this message translates to:
  /// **'Variante'**
  String get selectSpecification;

  /// Place order
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get placeOrder;

  /// Clear
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// Allergens
  ///
  /// In en, this message translates to:
  /// **'Allergens'**
  String get allergens;

  /// Exclude dishes containing the specified allergens
  ///
  /// In en, this message translates to:
  /// **'Exclude dishes containing the specified allergens'**
  String get excludeDishesWithAllergens;

  /// Selected
  ///
  /// In en, this message translates to:
  /// **'Selected:'**
  String get selected;

  /// Cart
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get cart;

  /// Change Table
  ///
  /// In en, this message translates to:
  /// **'Change Table'**
  String get changeTable;

  /// Change Menu
  ///
  /// In en, this message translates to:
  /// **'Change Menu'**
  String get changeMenu;

  /// Increase Number of People
  ///
  /// In en, this message translates to:
  /// **'Increase Number of People'**
  String get increaseNumberOfPeople;

  /// No relevant dishes found
  ///
  /// In en, this message translates to:
  /// **'No relevant dishes found'**
  String get noRelevantDishesFound;

  /// is sold out. Please choose another dish
  ///
  /// In en, this message translates to:
  /// **'is sold out. Please choose another dish.'**
  String get dishSoldOutPleaseChooseAnother;

  /// Next round time not reached
  ///
  /// In en, this message translates to:
  /// **'Next round time not reached'**
  String get nextRoundTimeNotReached;

  /// Cart has new changes
  ///
  /// In en, this message translates to:
  /// **'Cart has new changes'**
  String get cartHasNewChanges;

  /// Order placed successfully
  ///
  /// In en, this message translates to:
  /// **'Order placed successfully'**
  String get orderPlacedSuccessfully;

  /// Order Placement Failed, Please Contact the Waiter
  ///
  /// In en, this message translates to:
  /// **'Order Placement Failed, Please Contact the Waiter'**
  String get orderPlacementFailedContactWaiter;

  /// Clear shopping cart
  ///
  /// In en, this message translates to:
  /// **'Clear shopping cart?'**
  String get clearShoppingCart;

  /// Quantity exceeds the limit. Place order at original price
  ///
  /// In en, this message translates to:
  /// **'Quantity exceeds the limit. Place order at original price?'**
  String get quantityExceedsLimitPlaceAtOriginalPrice;

  /// Takeaway
  ///
  /// In en, this message translates to:
  /// **'Takeaway'**
  String get takeaway;

  /// Unsettled
  ///
  /// In en, this message translates to:
  /// **'Unsettled'**
  String get unsettled;

  /// Settled
  ///
  /// In en, this message translates to:
  /// **'Settled'**
  String get settled;

  /// Please enter pickup code
  ///
  /// In en, this message translates to:
  /// **'Please enter pickup code'**
  String get pleaseEnterPickupCode;

  /// Order Information
  ///
  /// In en, this message translates to:
  /// **'Order Information'**
  String get orderInformation;

  /// Pickup Code
  ///
  /// In en, this message translates to:
  /// **'Pickup Code'**
  String get pickupCode;

  /// Pickup Time
  ///
  /// In en, this message translates to:
  /// **'Pickup Time'**
  String get pickupTime;

  /// Remarks
  ///
  /// In en, this message translates to:
  /// **'Remarks'**
  String get remarks;

  /// Order Source
  ///
  /// In en, this message translates to:
  /// **'Order Source'**
  String get orderSource;

  /// Order Placement Time
  ///
  /// In en, this message translates to:
  /// **'Order Placement Time'**
  String get orderPlacementTime;

  /// Checkout Time
  ///
  /// In en, this message translates to:
  /// **'Checkout Time'**
  String get checkoutTime;

  /// Product Information
  ///
  /// In en, this message translates to:
  /// **'Product Information'**
  String get productInformation;

  /// Additional Information
  ///
  /// In en, this message translates to:
  /// **'Additional Information'**
  String get additionalInformation;

  /// Other Time
  ///
  /// In en, this message translates to:
  /// **'Other Time'**
  String get otherTime;

  /// Please select a pickup time
  ///
  /// In en, this message translates to:
  /// **'Please select a pickup time'**
  String get pleaseSelectPickupTime;

  /// The pickup time must be at least 30 minutes later
  ///
  /// In en, this message translates to:
  /// **'The pickup time must be at least 30 minutes later.'**
  String get pickupTimeMustBeAtLeast30MinutesLater;

  /// Profile
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Account
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// Expiry date
  ///
  /// In en, this message translates to:
  /// **'Expiry date'**
  String get expirationDate;

  /// Remaining Days
  ///
  /// In en, this message translates to:
  /// **'Remaining Days'**
  String get remainingDays;

  /// Change Password
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// Language
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// System Version
  ///
  /// In en, this message translates to:
  /// **'System Version'**
  String get systemVersion;

  /// Update
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// Logout
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// New Password
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// Any characters of 8 or more digits
  ///
  /// In en, this message translates to:
  /// **'Any characters of 8 or more digits'**
  String get anyCharactersOf8OrMore;

  /// Please enter new password
  ///
  /// In en, this message translates to:
  /// **'Please enter new password'**
  String get pleaseEnterNewPassword;

  /// Confirm Password
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// Please re-enter new password
  ///
  /// In en, this message translates to:
  /// **'Please re-enter new password'**
  String get pleaseReenterNewPassword;

  /// Submit
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// Password updated successfully
  ///
  /// In en, this message translates to:
  /// **'Password updated successfully'**
  String get passwordUpdatedSuccessfully;

  /// Password change failed, please retry
  ///
  /// In en, this message translates to:
  /// **'Password change failed, please retry.'**
  String get passwordChangeFailedPleaseRetry;

  /// Language switched successfully
  ///
  /// In en, this message translates to:
  /// **'Language switched successfully'**
  String get languageSwitchedSuccessfully;

  /// Language switch failed, please retry
  ///
  /// In en, this message translates to:
  /// **'Language switch failed, please retry.'**
  String get languageSwitchFailedPleaseRetry;

  /// Network error, please try again
  ///
  /// In en, this message translates to:
  /// **'Network error, please try again'**
  String get networkErrorPleaseTryAgain;

  /// Operation is too frequent, please try again later
  ///
  /// In en, this message translates to:
  /// **'Operation is too frequent, please try again later.'**
  String get operationTooFrequentPleaseTryAgainLater;

  /// No data available
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noData;

  /// Retry
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get loadAgain;

  /// All
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allData;

  /// Loading...
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loadingData;

  /// Success
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// Failed
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed;

  /// Select people
  ///
  /// In en, this message translates to:
  /// **'Select people'**
  String get selectPeople;

  /// Menu loading failed
  ///
  /// In en, this message translates to:
  /// **'Menu loading failed'**
  String get loadMenuFailed;

  /// Passwords do not match
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get twoPasswordsDoNotMatch;

  /// Minimum 8 characters
  ///
  /// In en, this message translates to:
  /// **'Minimum 8 characters'**
  String get passwordLengthCannotBeLessThan8;

  /// per portion
  ///
  /// In en, this message translates to:
  /// **'per portion'**
  String get perPortion;

  /// Replace
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get replace;

  /// Change guests
  ///
  /// In en, this message translates to:
  /// **'Change guests'**
  String get changePerson;

  /// Failed to get table
  ///
  /// In en, this message translates to:
  /// **'Failed to get table'**
  String get getTableFailed;

  /// Please select a table
  ///
  /// In en, this message translates to:
  /// **'Please select a table'**
  String get pleaseSelectTable;

  /// Please exit the ordering page and re-enter!
  ///
  /// In en, this message translates to:
  /// **'Please exit the ordering page and re-enter!'**
  String get pleaseExitAndInAdain;

  /// No available tables
  ///
  /// In en, this message translates to:
  /// **'No available tables'**
  String get noCanUseTable;

  /// No available menu
  ///
  /// In en, this message translates to:
  /// **'No available menu'**
  String get noCanUseMenu;

  /// Please select at least 1 person
  ///
  /// In en, this message translates to:
  /// **'Please select at least 1 person'**
  String get pleaseSelectAtLeastOnePerson;

  /// Merging...
  ///
  /// In en, this message translates to:
  /// **'Merging...'**
  String get merging;

  /// Please select at least 2 tables to merge
  ///
  /// In en, this message translates to:
  /// **'Please select at least 2 tables to merge'**
  String get pleaseSelectAtLeastTwoTables;

  /// Please select at least 1 table
  ///
  /// In en, this message translates to:
  /// **'Please select at least 1 table'**
  String get pleaseSelectAtLeastOneTable;

  /// Closing table...
  ///
  /// In en, this message translates to:
  /// **'Closing table...'**
  String get closingTable;

  /// Removing table...
  ///
  /// In en, this message translates to:
  /// **'Removing table...'**
  String get removingTable;

  /// Unknown
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// The shopping cart is empty
  ///
  /// In en, this message translates to:
  /// **'The shopping cart is empty'**
  String get cartIsEmpty;

  /// Do you want to delete this dish?
  ///
  /// In en, this message translates to:
  /// **'Do you want to delete this dish?'**
  String get areYouSureToDeleteTheDish;

  /// Delete
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Quantity
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// Please select
  ///
  /// In en, this message translates to:
  /// **'Please select'**
  String get pleaseSelect;

  /// Filter dishes containing allergens
  ///
  /// In en, this message translates to:
  /// **'Filter dishes containing allergens'**
  String get filterDishesWithAllergens;

  /// No order data available
  ///
  /// In en, this message translates to:
  /// **'No order data available'**
  String get noOrder;

  /// Go to order
  ///
  /// In en, this message translates to:
  /// **'Go to order'**
  String get goToOrder;

  /// Unpaid
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get unpaid;

  /// Paid
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// Order Number
  ///
  /// In en, this message translates to:
  /// **'Order Number'**
  String get orderNo;

  /// No description provided for @orderSourceNew.
  ///
  /// In en, this message translates to:
  /// **'Source of Document'**
  String get orderSourceNew;

  /// Product Details
  ///
  /// In en, this message translates to:
  /// **'Product Details'**
  String get productDetails;

  /// Confirm Action
  ///
  /// In en, this message translates to:
  /// **'Confirm Action'**
  String get operationConfirmed;

  /// Do you want to log out?
  ///
  /// In en, this message translates to:
  /// **'Do you want to log out?'**
  String get areYouSureToLogout;

  /// Confirm Logout
  ///
  /// In en, this message translates to:
  /// **'Confirm Logout'**
  String get sureLogout;

  /// Welcome
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// Server
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get serviceApp;

  /// Password
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Remark
  ///
  /// In en, this message translates to:
  /// **'Remark'**
  String get remark;

  /// Add Remark
  ///
  /// In en, this message translates to:
  /// **'Add Remark'**
  String get addRemark;

  /// Edit Remark
  ///
  /// In en, this message translates to:
  /// **'Edit Remark'**
  String get editRemark;

  /// Confirm order?
  ///
  /// In en, this message translates to:
  /// **'Confirm order?'**
  String get confirmOrder;

  /// Please enter
  ///
  /// In en, this message translates to:
  /// **'Please enter'**
  String get pleaseEnter;

  /// Logging in...
  ///
  /// In en, this message translates to:
  /// **'Logging in...'**
  String get logining;

  /// Server Address
  ///
  /// In en, this message translates to:
  /// **'Server Address'**
  String get serverAddress;

  /// IP Address
  ///
  /// In en, this message translates to:
  /// **'IP Address'**
  String get ipAddress;

  /// Port
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get port;

  /// Please enter IP address
  ///
  /// In en, this message translates to:
  /// **'Please enter IP address'**
  String get pleaseEnterIpAddress;

  /// Please enter port
  ///
  /// In en, this message translates to:
  /// **'Please enter port'**
  String get pleaseEnterPort;

  /// Server configuration saved successfully
  ///
  /// In en, this message translates to:
  /// **'Server configuration saved successfully'**
  String get serverConfigSavedSuccessfully;

  /// Server configuration save failed
  ///
  /// In en, this message translates to:
  /// **'Server configuration save failed'**
  String get serverConfigSaveFailed;

  /// Invalid IP address format
  ///
  /// In en, this message translates to:
  /// **'Invalid IP address format'**
  String get invalidIpAddress;

  /// Invalid port format
  ///
  /// In en, this message translates to:
  /// **'Invalid port format'**
  String get invalidPort;

  /// Please select a reason
  ///
  /// In en, this message translates to:
  /// **'Please select a reason'**
  String get selectReason;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'it', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'it': return AppLocalizationsIt();
    case 'zh': return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
