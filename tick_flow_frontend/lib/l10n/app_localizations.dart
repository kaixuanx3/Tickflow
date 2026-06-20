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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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

  /// No description provided for @menuTitle.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menuTitle;

  /// No description provided for @menuSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Signed in'**
  String get menuSignedIn;

  /// No description provided for @menuSectionAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get menuSectionAccount;

  /// No description provided for @menuSectionPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get menuSectionPreferences;

  /// No description provided for @menuSectionSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get menuSectionSecurity;

  /// No description provided for @menuSectionNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get menuSectionNotifications;

  /// No description provided for @menuSectionSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get menuSectionSupport;

  /// No description provided for @menuAccountDetails.
  ///
  /// In en, this message translates to:
  /// **'Account details'**
  String get menuAccountDetails;

  /// No description provided for @menuSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get menuSubscriptions;

  /// No description provided for @menuPlanFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get menuPlanFree;

  /// No description provided for @menuAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get menuAppearance;

  /// No description provided for @menuLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get menuLanguage;

  /// No description provided for @menuChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get menuChangePassword;

  /// No description provided for @menuBiometrics.
  ///
  /// In en, this message translates to:
  /// **'Biometrics'**
  String get menuBiometrics;

  /// No description provided for @menuPushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push notifications'**
  String get menuPushNotifications;

  /// No description provided for @menuHelpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get menuHelpSupport;

  /// No description provided for @menuAboutApp.
  ///
  /// In en, this message translates to:
  /// **'About Tickflow'**
  String get menuAboutApp;

  /// No description provided for @menuSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get menuSignOut;

  /// No description provided for @menuDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get menuDeleteAccount;

  /// No description provided for @optionSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get optionSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageChinese.
  ///
  /// In en, this message translates to:
  /// **'中文'**
  String get languageChinese;

  /// No description provided for @biometricSetupHint.
  ///
  /// In en, this message translates to:
  /// **'Set up a fingerprint or screen lock on this device to use biometric unlock.'**
  String get biometricSetupHint;

  /// No description provided for @notificationsUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Could not update notifications'**
  String get notificationsUpdateError;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account?'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes your account, watchlist, portfolio, alerts and notifications. This cannot be undone.'**
  String get deleteAccountBody;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @deleteAccountError.
  ///
  /// In en, this message translates to:
  /// **'Could not delete account'**
  String get deleteAccountError;

  /// No description provided for @commonGenericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong — please try again.'**
  String get commonGenericError;

  /// No description provided for @authTagline.
  ///
  /// In en, this message translates to:
  /// **'Track US stocks in real time'**
  String get authTagline;

  /// No description provided for @authEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmail;

  /// No description provided for @authEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get authEnterEmail;

  /// No description provided for @authInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get authInvalidEmail;

  /// No description provided for @authPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// No description provided for @authPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get authPasswordHint;

  /// No description provided for @authShowPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get authShowPassword;

  /// No description provided for @authHidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get authHidePassword;

  /// No description provided for @authPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get authPasswordTooShort;

  /// No description provided for @authCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authCreateAccount;

  /// No description provided for @authSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignIn;

  /// No description provided for @authToggleToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Have an account? Sign in'**
  String get authToggleToSignIn;

  /// No description provided for @authToggleToRegister.
  ///
  /// In en, this message translates to:
  /// **'New here? Create an account'**
  String get authToggleToRegister;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @marketsTitle.
  ///
  /// In en, this message translates to:
  /// **'Markets'**
  String get marketsTitle;

  /// No description provided for @marketsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search US stocks'**
  String get marketsSearchHint;

  /// No description provided for @marketsTabGainers.
  ///
  /// In en, this message translates to:
  /// **'Top gainers'**
  String get marketsTabGainers;

  /// No description provided for @marketsTabLosers.
  ///
  /// In en, this message translates to:
  /// **'Top losers'**
  String get marketsTabLosers;

  /// No description provided for @marketsTabActive.
  ///
  /// In en, this message translates to:
  /// **'Most active'**
  String get marketsTabActive;

  /// No description provided for @marketsNoData.
  ///
  /// In en, this message translates to:
  /// **'No data right now'**
  String get marketsNoData;

  /// No description provided for @favTitle.
  ///
  /// In en, this message translates to:
  /// **'Favourites'**
  String get favTitle;

  /// No description provided for @favEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing starred yet'**
  String get favEmptyTitle;

  /// No description provided for @favEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Star a symbol in Markets and it shows up here with a live price.'**
  String get favEmptyBody;

  /// No description provided for @favRemoveError.
  ///
  /// In en, this message translates to:
  /// **'Could not remove {symbol}'**
  String favRemoveError(String symbol);

  /// No description provided for @portfolioTitle.
  ///
  /// In en, this message translates to:
  /// **'Portfolio'**
  String get portfolioTitle;

  /// No description provided for @portfolioAddHolding.
  ///
  /// In en, this message translates to:
  /// **'Add holding'**
  String get portfolioAddHolding;

  /// No description provided for @portfolioEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No holdings yet'**
  String get portfolioEmptyTitle;

  /// No description provided for @portfolioEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Add what you own — quantity and buy price — and Tickflow tracks value and gain/loss for you.'**
  String get portfolioEmptyBody;

  /// No description provided for @portfolioAddFirst.
  ///
  /// In en, this message translates to:
  /// **'Add your first holding'**
  String get portfolioAddFirst;

  /// No description provided for @portfolioTotalValue.
  ///
  /// In en, this message translates to:
  /// **'Total value'**
  String get portfolioTotalValue;

  /// No description provided for @portfolioAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get portfolioAnalytics;

  /// No description provided for @portfolioToday.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get portfolioToday;

  /// No description provided for @portfolioCost.
  ///
  /// In en, this message translates to:
  /// **'Cost'**
  String get portfolioCost;

  /// No description provided for @portfolioTotalGainLoss.
  ///
  /// In en, this message translates to:
  /// **'Total gain / loss'**
  String get portfolioTotalGainLoss;

  /// No description provided for @portfolioIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Some holdings have no live price right now — totals exclude them.'**
  String get portfolioIncomplete;

  /// No description provided for @portfolioHoldings.
  ///
  /// In en, this message translates to:
  /// **'Holdings'**
  String get portfolioHoldings;

  /// No description provided for @portfolioDragToReorder.
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder'**
  String get portfolioDragToReorder;

  /// No description provided for @portfolioDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get portfolioDone;

  /// No description provided for @portfolioEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get portfolioEdit;

  /// No description provided for @portfolioUnitShares.
  ///
  /// In en, this message translates to:
  /// **'Shares'**
  String get portfolioUnitShares;

  /// No description provided for @portfolioUnitUnits.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get portfolioUnitUnits;

  /// No description provided for @portfolioHoldingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{qty} {unit}, Avg. {avg}'**
  String portfolioHoldingSubtitle(String qty, String unit, String avg);

  /// No description provided for @portfolioCurrentLabel.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get portfolioCurrentLabel;

  /// No description provided for @portfolioEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit {symbol}'**
  String portfolioEditTitle(String symbol);

  /// No description provided for @portfolioSymbol.
  ///
  /// In en, this message translates to:
  /// **'Symbol'**
  String get portfolioSymbol;

  /// No description provided for @portfolioSymbolHint.
  ///
  /// In en, this message translates to:
  /// **'US ticker, e.g. AAPL'**
  String get portfolioSymbolHint;

  /// No description provided for @portfolioEnterSymbol.
  ///
  /// In en, this message translates to:
  /// **'Enter a symbol'**
  String get portfolioEnterSymbol;

  /// No description provided for @portfolioQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get portfolioQuantity;

  /// No description provided for @portfolioQtyError.
  ///
  /// In en, this message translates to:
  /// **'Must be more than 0'**
  String get portfolioQtyError;

  /// No description provided for @portfolioBuyPrice.
  ///
  /// In en, this message translates to:
  /// **'Buy price'**
  String get portfolioBuyPrice;

  /// No description provided for @portfolioPriceError.
  ///
  /// In en, this message translates to:
  /// **'Must be 0 or more'**
  String get portfolioPriceError;

  /// No description provided for @portfolioSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get portfolioSaveChanges;

  /// No description provided for @portfolioDeleteHolding.
  ///
  /// In en, this message translates to:
  /// **'Delete holding'**
  String get portfolioDeleteHolding;

  /// No description provided for @portfolioRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {symbol}?'**
  String portfolioRemoveTitle(String symbol);

  /// No description provided for @portfolioRemoveBody.
  ///
  /// In en, this message translates to:
  /// **'This deletes the holding from your portfolio.'**
  String get portfolioRemoveBody;

  /// No description provided for @portfolioRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get portfolioRemove;

  /// No description provided for @assetTypeStock.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get assetTypeStock;

  /// No description provided for @assetTypeEtf.
  ///
  /// In en, this message translates to:
  /// **'ETF'**
  String get assetTypeEtf;

  /// No description provided for @assetTypeCrypto.
  ///
  /// In en, this message translates to:
  /// **'Crypto'**
  String get assetTypeCrypto;

  /// No description provided for @notifTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifTitle;

  /// No description provided for @notifTabAlerts.
  ///
  /// In en, this message translates to:
  /// **'My alerts'**
  String get notifTabAlerts;

  /// No description provided for @notifTabTriggered.
  ///
  /// In en, this message translates to:
  /// **'Triggered'**
  String get notifTabTriggered;

  /// No description provided for @notifNewAlert.
  ///
  /// In en, this message translates to:
  /// **'New alert'**
  String get notifNewAlert;

  /// No description provided for @alertsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No alerts yet'**
  String get alertsEmptyTitle;

  /// No description provided for @alertsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Get notified when a price crosses your threshold.'**
  String get alertsEmptyBody;

  /// No description provided for @alertsCreateFirst.
  ///
  /// In en, this message translates to:
  /// **'Create your first alert'**
  String get alertsCreateFirst;

  /// No description provided for @alertRearm.
  ///
  /// In en, this message translates to:
  /// **'Re-arm'**
  String get alertRearm;

  /// No description provided for @alertRearmError.
  ///
  /// In en, this message translates to:
  /// **'Could not re-arm the alert'**
  String get alertRearmError;

  /// No description provided for @alertTriggeredCount.
  ///
  /// In en, this message translates to:
  /// **'triggered {count}×'**
  String alertTriggeredCount(int count);

  /// No description provided for @triggeredEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing triggered yet'**
  String get triggeredEmptyTitle;

  /// No description provided for @triggeredEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'When one of your alerts fires, it shows up here.'**
  String get triggeredEmptyBody;

  /// No description provided for @alertRuleAbove.
  ///
  /// In en, this message translates to:
  /// **'Above'**
  String get alertRuleAbove;

  /// No description provided for @alertRuleBelow.
  ///
  /// In en, this message translates to:
  /// **'Below'**
  String get alertRuleBelow;

  /// No description provided for @alertKindOneShot.
  ///
  /// In en, this message translates to:
  /// **'One-shot'**
  String get alertKindOneShot;

  /// No description provided for @alertKindReArm.
  ///
  /// In en, this message translates to:
  /// **'Re-arm'**
  String get alertKindReArm;

  /// No description provided for @alertStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get alertStatusActive;

  /// No description provided for @alertStatusCooldown.
  ///
  /// In en, this message translates to:
  /// **'Cooldown'**
  String get alertStatusCooldown;

  /// No description provided for @alertStatusDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get alertStatusDone;

  /// No description provided for @alertSegPriceAbove.
  ///
  /// In en, this message translates to:
  /// **'Price above'**
  String get alertSegPriceAbove;

  /// No description provided for @alertSegPriceBelow.
  ///
  /// In en, this message translates to:
  /// **'Price below'**
  String get alertSegPriceBelow;

  /// No description provided for @alertHintAbove.
  ///
  /// In en, this message translates to:
  /// **'Triggers when the price goes above the threshold.'**
  String get alertHintAbove;

  /// No description provided for @alertHintBelow.
  ///
  /// In en, this message translates to:
  /// **'Triggers when the price goes below the threshold.'**
  String get alertHintBelow;

  /// No description provided for @alertKindOneShotDesc.
  ///
  /// In en, this message translates to:
  /// **'Fires once, then stays in your history until re-armed.'**
  String get alertKindOneShotDesc;

  /// No description provided for @alertKindReArmDesc.
  ///
  /// In en, this message translates to:
  /// **'Fires, cools down, and automatically re-arms when the price retreats.'**
  String get alertKindReArmDesc;

  /// No description provided for @alertThreshold.
  ///
  /// In en, this message translates to:
  /// **'Threshold'**
  String get alertThreshold;

  /// No description provided for @alertCreate.
  ///
  /// In en, this message translates to:
  /// **'Create alert'**
  String get alertCreate;

  /// No description provided for @alertNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New price alert'**
  String get alertNewTitle;

  /// No description provided for @alertEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit {symbol} alert'**
  String alertEditTitle(String symbol);

  /// No description provided for @alertDeleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete alert'**
  String get alertDeleteButton;

  /// No description provided for @alertDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {symbol} alert?'**
  String alertDeleteTitle(String symbol);

  /// No description provided for @alertDeleteContent.
  ///
  /// In en, this message translates to:
  /// **'{rule} {threshold} — this also removes it from your history of active alerts.'**
  String alertDeleteContent(String rule, String threshold);

  /// No description provided for @navAlerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get navAlerts;

  /// No description provided for @detailDailyBarsNote.
  ///
  /// In en, this message translates to:
  /// **'Free data tier serves daily bars — \"1D\" shows roughly the last week.'**
  String get detailDailyBarsNote;

  /// No description provided for @detailNoChartData.
  ///
  /// In en, this message translates to:
  /// **'No chart data'**
  String get detailNoChartData;

  /// No description provided for @detailCachedChart.
  ///
  /// In en, this message translates to:
  /// **'Showing cached chart data'**
  String get detailCachedChart;

  /// No description provided for @detailDelayed.
  ///
  /// In en, this message translates to:
  /// **'Delayed'**
  String get detailDelayed;

  /// No description provided for @detailCached.
  ///
  /// In en, this message translates to:
  /// **'Cached'**
  String get detailCached;

  /// No description provided for @detailChangeToday.
  ///
  /// In en, this message translates to:
  /// **'{change} ({percent}) today'**
  String detailChangeToday(String change, String percent);

  /// No description provided for @detailTodayTitle.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get detailTodayTitle;

  /// No description provided for @detailStatOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get detailStatOpen;

  /// No description provided for @detailStatHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get detailStatHigh;

  /// No description provided for @detailStatLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get detailStatLow;

  /// No description provided for @detailStatPrevClose.
  ///
  /// In en, this message translates to:
  /// **'Prev close'**
  String get detailStatPrevClose;

  /// No description provided for @detailAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get detailAbout;

  /// No description provided for @detailIndustry.
  ///
  /// In en, this message translates to:
  /// **'Industry'**
  String get detailIndustry;

  /// No description provided for @detailExchange.
  ///
  /// In en, this message translates to:
  /// **'Exchange'**
  String get detailExchange;

  /// No description provided for @detailCountry.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get detailCountry;

  /// No description provided for @detailMarketCap.
  ///
  /// In en, this message translates to:
  /// **'Market cap'**
  String get detailMarketCap;

  /// No description provided for @detailIpo.
  ///
  /// In en, this message translates to:
  /// **'IPO'**
  String get detailIpo;

  /// No description provided for @detailWebsite.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get detailWebsite;

  /// No description provided for @commonClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get commonClear;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search symbol or company'**
  String get searchHint;

  /// No description provided for @searchIdle.
  ///
  /// In en, this message translates to:
  /// **'Search US stocks by symbol or company name.'**
  String get searchIdle;

  /// No description provided for @searchNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches for \"{query}\".'**
  String searchNoMatches(String query);
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
