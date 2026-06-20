// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get menuTitle => 'Menu';

  @override
  String get menuSignedIn => 'Signed in';

  @override
  String get menuSectionAccount => 'Account';

  @override
  String get menuSectionPreferences => 'Preferences';

  @override
  String get menuSectionSecurity => 'Security';

  @override
  String get menuSectionNotifications => 'Notifications';

  @override
  String get menuSectionSupport => 'Support';

  @override
  String get menuAccountDetails => 'Account details';

  @override
  String get menuSubscriptions => 'Subscriptions';

  @override
  String get menuPlanFree => 'Free';

  @override
  String get menuAppearance => 'Appearance';

  @override
  String get menuLanguage => 'Language';

  @override
  String get menuChangePassword => 'Change password';

  @override
  String get menuBiometrics => 'Biometrics';

  @override
  String get menuPushNotifications => 'Push notifications';

  @override
  String get menuHelpSupport => 'Help & Support';

  @override
  String get menuAboutApp => 'About Tickflow';

  @override
  String get menuSignOut => 'Sign out';

  @override
  String get menuDeleteAccount => 'Delete account';

  @override
  String get optionSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageChinese => '中文';

  @override
  String get biometricSetupHint =>
      'Set up a fingerprint or screen lock on this device to use biometric unlock.';

  @override
  String get notificationsUpdateError => 'Could not update notifications';

  @override
  String get deleteAccountTitle => 'Delete account?';

  @override
  String get deleteAccountBody =>
      'This permanently deletes your account, watchlist, portfolio, alerts and notifications. This cannot be undone.';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get deleteAccountError => 'Could not delete account';

  @override
  String get commonGenericError => 'Something went wrong — please try again.';

  @override
  String get authTagline => 'Track US stocks in real time';

  @override
  String get authEmail => 'Email';

  @override
  String get authEnterEmail => 'Enter your email';

  @override
  String get authInvalidEmail => 'Enter a valid email';

  @override
  String get authPassword => 'Password';

  @override
  String get authPasswordHint => 'At least 8 characters';

  @override
  String get authShowPassword => 'Show password';

  @override
  String get authHidePassword => 'Hide password';

  @override
  String get authPasswordTooShort => 'Password must be at least 8 characters';

  @override
  String get authCreateAccount => 'Create account';

  @override
  String get authSignIn => 'Sign in';

  @override
  String get authToggleToSignIn => 'Have an account? Sign in';

  @override
  String get authToggleToRegister => 'New here? Create an account';

  @override
  String get commonRetry => 'Retry';

  @override
  String get marketsTitle => 'Markets';

  @override
  String get marketsSearchHint => 'Search US stocks';

  @override
  String get marketsTabGainers => 'Top gainers';

  @override
  String get marketsTabLosers => 'Top losers';

  @override
  String get marketsTabActive => 'Most active';

  @override
  String get marketsNoData => 'No data right now';

  @override
  String get favTitle => 'Favourites';

  @override
  String get favEmptyTitle => 'Nothing starred yet';

  @override
  String get favEmptyBody =>
      'Star a symbol in Markets and it shows up here with a live price.';

  @override
  String favRemoveError(String symbol) {
    return 'Could not remove $symbol';
  }

  @override
  String get portfolioTitle => 'Portfolio';

  @override
  String get portfolioAddHolding => 'Add holding';

  @override
  String get portfolioEmptyTitle => 'No holdings yet';

  @override
  String get portfolioEmptyBody =>
      'Add what you own — quantity and buy price — and Tickflow tracks value and gain/loss for you.';

  @override
  String get portfolioAddFirst => 'Add your first holding';

  @override
  String get portfolioTotalValue => 'Total value';

  @override
  String get portfolioAnalytics => 'Analytics';

  @override
  String get portfolioToday => 'today';

  @override
  String get portfolioCost => 'Cost';

  @override
  String get portfolioTotalGainLoss => 'Total gain / loss';

  @override
  String get portfolioIncomplete =>
      'Some holdings have no live price right now — totals exclude them.';

  @override
  String get portfolioHoldings => 'Holdings';

  @override
  String get portfolioDragToReorder => 'Drag to reorder';

  @override
  String get portfolioDone => 'Done';

  @override
  String get portfolioEdit => 'Edit';

  @override
  String get portfolioUnitShares => 'Shares';

  @override
  String get portfolioUnitUnits => 'Units';

  @override
  String portfolioHoldingSubtitle(String qty, String unit, String avg) {
    return '$qty $unit, Avg. $avg';
  }

  @override
  String get portfolioCurrentLabel => 'Current';

  @override
  String portfolioEditTitle(String symbol) {
    return 'Edit $symbol';
  }

  @override
  String get portfolioSymbol => 'Symbol';

  @override
  String get portfolioSymbolHint => 'US ticker, e.g. AAPL';

  @override
  String get portfolioEnterSymbol => 'Enter a symbol';

  @override
  String get portfolioQuantity => 'Quantity';

  @override
  String get portfolioQtyError => 'Must be more than 0';

  @override
  String get portfolioBuyPrice => 'Buy price';

  @override
  String get portfolioPriceError => 'Must be 0 or more';

  @override
  String get portfolioSaveChanges => 'Save changes';

  @override
  String get portfolioDeleteHolding => 'Delete holding';

  @override
  String portfolioRemoveTitle(String symbol) {
    return 'Remove $symbol?';
  }

  @override
  String get portfolioRemoveBody =>
      'This deletes the holding from your portfolio.';

  @override
  String get portfolioRemove => 'Remove';

  @override
  String get assetTypeStock => 'Stock';

  @override
  String get assetTypeEtf => 'ETF';

  @override
  String get assetTypeCrypto => 'Crypto';
}
