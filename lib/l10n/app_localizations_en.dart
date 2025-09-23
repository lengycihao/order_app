// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'OUHUA RISTOO(Waiter)';

  @override
  String get pleaseEnterLoginName => 'Please enter your login name';

  @override
  String get pleaseEnterPassword => 'Please enter the password';

  @override
  String get login => 'Login';

  @override
  String get copyright =>
      '©2025 Ouhua Zhichuang (Hangzhou) Technology Co., Ltd.';

  @override
  String get loginNameCannotBeEmpty => 'Login name cannot be empty';

  @override
  String get passwordCannotBeEmpty => 'Password cannot be empty.';

  @override
  String get incorrectPassword => 'Incorrect Password';

  @override
  String get loginSuccessful => 'Login Successful';

  @override
  String get loginFailedPleaseRetry => 'Login failed, please retry';

  @override
  String get accountLoggedInOnAnotherDevice =>
      'The account has been logged in on another device';

  @override
  String get table => 'Table';

  @override
  String get more => 'More';

  @override
  String get mergeTables => 'Merge Tables';

  @override
  String get clearTable => 'Clear Table';

  @override
  String get closeTable => 'Close Table';

  @override
  String get confirm => 'Confirm';

  @override
  String get includingTables => 'Including Tables';

  @override
  String get selectTable => 'Select Table';

  @override
  String get reason => 'Reason';

  @override
  String get cancel => 'Cancel';

  @override
  String get tablePeople => 'Table People';

  @override
  String get adults => 'Adults';

  @override
  String get children => 'Children';

  @override
  String get selectMenu => 'Select Menu';

  @override
  String get startOrdering => 'Start Ordering';

  @override
  String get currentTableUnavailable => 'The current table is unavailable';

  @override
  String get onlyOneNonFreeTableCanBeSelected =>
      'Only one of the following non - free tables can be selected.';

  @override
  String get pleaseSelectNumberOfDiners => 'Please select the number of diners';

  @override
  String get standardAdultsForThisTable =>
      'Standard number of adults for this table: [4]';

  @override
  String get standardChildrenForThisTable =>
      'Standard number of children for this table:[5]';

  @override
  String get pleaseSelectMenu => 'Please select a menu';

  @override
  String get mergeSuccessful => 'Merge successful';

  @override
  String get mergeFailedPleaseRetry => 'Merge failed, please retry.';

  @override
  String get oneTableMustRemainWhenRemoving =>
      'When removing tables, one table must remain.';

  @override
  String get tableRemovalSuccessful => 'Table removal successful';

  @override
  String get tableRemovalFailedPleaseRetry =>
      'Table removal failed, please retry';

  @override
  String get tableClosingSuccessful => 'Table closing successful';

  @override
  String get tableClosingFailedPleaseRetry =>
      'Table closing failed, please retry';

  @override
  String get tableOpeningSuccessful => 'Table opening successful';

  @override
  String get tableOpeningFailedPleaseRetry =>
      'Table opening failed, please retry';

  @override
  String get pleaseEnterLast4DigitsOfReservedPhone =>
      'Please enter the last 4 digits of the reserved phone number?/Cancel/Confirm';

  @override
  String get numberIncorrectPleaseReenter =>
      'The number is incorrect, please re-enter';

  @override
  String get numberCorrectEnjoyYourMeal =>
      'The number is correct. Enjoy your meal!';

  @override
  String get menu => 'Menu';

  @override
  String get ordered => 'Ordered';

  @override
  String get enterDishCodeOrName => 'Enter dish code or name';

  @override
  String get max1PerPerson => 'Max 1/pers.';

  @override
  String get twoLeft => '2 left';

  @override
  String get selectSpecification => 'Variante';

  @override
  String get placeOrder => 'Order';

  @override
  String get clear => 'Clear';

  @override
  String get allergens => 'Allergens';

  @override
  String get excludeDishesWithAllergens =>
      'Exclude dishes containing the specified allergens';

  @override
  String get selected => 'Selected:';

  @override
  String get cart => 'Cart';

  @override
  String get changeTable => 'Change Table';

  @override
  String get changeMenu => 'Change Menu';

  @override
  String get increaseNumberOfPeople => 'Increase Number of People';

  @override
  String get roundQuantity => 'Round: 1/2; Quantity: 4/6';

  @override
  String get noRelevantDishesFound => 'No relevant dishes found';

  @override
  String get dishSoldOutPleaseChooseAnother =>
      '[某菜名] is sold out. Please choose another dish.';

  @override
  String get dishQuantityExceedsLimit =>
      '[某菜名]Quantity exceeds limit, Max 1/person';

  @override
  String get dishInsufficientStock => '[某菜名]Insufficient stock,2 left';

  @override
  String get nextRoundTimeNotReached => 'Next round time not reached';

  @override
  String get dishPlusOne => '[某菜品]+1';

  @override
  String get cartHasNewChanges => 'Cart has new changes';

  @override
  String get orderPlacedSuccessfully => 'Order placed successfully';

  @override
  String get orderPlacementFailedContactWaiter =>
      'Order Placement Failed, Please Contact the Waiter';

  @override
  String get clearShoppingCart => 'Clear shopping cart?/Cancel/Confirm';

  @override
  String get dishQuantityExceedsLimitPlaceAtOriginalPrice =>
      '[某菜名]Quantity exceeds the limit. Place order at original price?';

  @override
  String get takeaway => 'Takeaway';

  @override
  String get unsettled => 'Unsettled';

  @override
  String get settled => 'Settled';

  @override
  String get pleaseEnterPickupCode => 'Please enter pickup code';

  @override
  String get orderInformation => 'Order Information';

  @override
  String get pickupCode => 'Pickup Code';

  @override
  String get pickupTime => 'Pickup Time';

  @override
  String get remarks => 'Remarks';

  @override
  String get orderSource => 'Order Source';

  @override
  String get orderPlacementTime => 'Order Placement Time';

  @override
  String get checkoutTime => 'Checkout Time';

  @override
  String get productInformation => 'Product Information';

  @override
  String get additionalInformation => 'Additional Information';

  @override
  String get otherTime => 'Other Time';

  @override
  String get pleaseSelectPickupTime => 'Please select a pickup time';

  @override
  String get pickupTimeMustBeAtLeast30MinutesLater =>
      'The pickup time must be at least 30 minutes later.';

  @override
  String get profile => 'Profile';

  @override
  String get account => 'Account';

  @override
  String get expirationDate => 'Expiration Date';

  @override
  String get remainingDays => 'Remaining Days';

  @override
  String get changePassword => 'Change Password';

  @override
  String get language => 'Language';

  @override
  String get systemVersion => 'System Version';

  @override
  String get update => 'Update';

  @override
  String get logout => 'Logout';

  @override
  String get newPassword => 'New Password';

  @override
  String get anyCharactersOf8OrMoreDigits =>
      'Any characters of 8 or more digits';

  @override
  String get pleaseEnterNewPassword => 'Please enter new password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get pleaseReenterNewPassword => 'Please re-enter new password';

  @override
  String get submit => 'Submit';

  @override
  String get passwordUpdatedSuccessfully => 'Password updated successfully';

  @override
  String get passwordChangeFailedPleaseRetry =>
      'Password change failed, please retry.';

  @override
  String get languageSwitchedSuccessfully => 'Language switched successfully';

  @override
  String get languageSwitchFailedPleaseRetry =>
      'Language switch failed, please retry.';

  @override
  String get networkErrorPleaseTryAgain => 'Network error, please try again';

  @override
  String get operationTooFrequentPleaseTryAgainLater =>
      'Operation is too frequent, please try again later.';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get chinese => 'Chinese';

  @override
  String get english => 'English';

  @override
  String get italian => 'Italian';

  @override
  String get systemTitle => 'OUHUA Restaurant System';

  @override
  String get noData => 'No Data';

  @override
  String get pending => 'Pending';

  @override
  String get quantity => 'Quantity';

  @override
  String get specifications => 'Specifications';

  @override
  String get info => 'Info';

  @override
  String get home => 'Home';

  @override
  String get order => 'Order';

  @override
  String get moreDishesComingSoon => 'More dishes coming soon';

  @override
  String get switchLanguage => 'Switch Language';

  @override
  String get authDebug => 'Auth Debug';

  @override
  String get welcomeToUse => 'Welcome to Use';
}
