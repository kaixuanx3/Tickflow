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
  String get authForgotPassword => 'Forgot password?';

  @override
  String get authForgotPasswordMsg =>
      'Password reset isn\'t available yet. For help, email support@tickflow.my.';

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

  @override
  String get notifTitle => 'Notifications';

  @override
  String get notifTabAlerts => 'My alerts';

  @override
  String get notifTabTriggered => 'Triggered';

  @override
  String get notifNewAlert => 'New alert';

  @override
  String get alertsEmptyTitle => 'No alerts yet';

  @override
  String get alertsEmptyBody =>
      'Get notified when a price crosses your threshold.';

  @override
  String get alertsCreateFirst => 'Create your first alert';

  @override
  String get alertRearm => 'Re-arm';

  @override
  String get alertRearmError => 'Could not re-arm the alert';

  @override
  String get alertUpdateError => 'Couldn\'t update the alert';

  @override
  String get alertNow => 'now';

  @override
  String get alertPauseTooltip => 'Pause alert';

  @override
  String get alertResumeTooltip => 'Resume alert';

  @override
  String alertTriggeredCount(int count) {
    return 'triggered $count×';
  }

  @override
  String get triggeredEmptyTitle => 'Nothing triggered yet';

  @override
  String get triggeredEmptyBody =>
      'When one of your alerts fires, it shows up here.';

  @override
  String get alertRuleAbove => 'Above';

  @override
  String get alertRuleBelow => 'Below';

  @override
  String get alertKindOneShot => 'One-shot';

  @override
  String get alertKindReArm => 'Re-arm';

  @override
  String get alertStatusActive => 'Active';

  @override
  String get alertStatusCooldown => 'Cooldown';

  @override
  String get alertStatusDone => 'Done';

  @override
  String get alertStatusPaused => 'Paused';

  @override
  String get alertSegPriceAbove => 'Price above';

  @override
  String get alertSegPriceBelow => 'Price below';

  @override
  String get alertHintAbove =>
      'Triggers when the price goes above the threshold.';

  @override
  String get alertHintBelow =>
      'Triggers when the price goes below the threshold.';

  @override
  String get alertKindOneShotDesc =>
      'Fires once, then stays in your history until re-armed.';

  @override
  String get alertKindReArmDesc =>
      'Fires, cools down, and automatically re-arms when the price retreats.';

  @override
  String get alertThreshold => 'Threshold';

  @override
  String get alertCreate => 'Create alert';

  @override
  String get alertNewTitle => 'New price alert';

  @override
  String alertEditTitle(String symbol) {
    return 'Edit $symbol alert';
  }

  @override
  String get alertDeleteButton => 'Delete alert';

  @override
  String alertDeleteTitle(String symbol) {
    return 'Delete $symbol alert?';
  }

  @override
  String alertDeleteContent(String rule, String threshold) {
    return '$rule $threshold — this also removes it from your history of active alerts.';
  }

  @override
  String get navAlerts => 'Alerts';

  @override
  String get detailDailyBarsNote =>
      'Free data tier serves daily bars — \"1D\" shows roughly the last week.';

  @override
  String get detailNoChartData => 'No chart data';

  @override
  String get detailCachedChart => 'Showing cached chart data';

  @override
  String get detailDelayed => 'Delayed';

  @override
  String get detailCached => 'Cached';

  @override
  String detailChangeToday(String change, String percent) {
    return '$change ($percent) today';
  }

  @override
  String get detailTodayTitle => 'Today';

  @override
  String get detailStatOpen => 'Open';

  @override
  String get detailStatHigh => 'High';

  @override
  String get detailStatLow => 'Low';

  @override
  String get detailStatPrevClose => 'Prev close';

  @override
  String get detailAbout => 'About';

  @override
  String get detailIndustry => 'Industry';

  @override
  String get detailExchange => 'Exchange';

  @override
  String get detailCountry => 'Country';

  @override
  String get detailMarketCap => 'Market cap';

  @override
  String get detailIpo => 'IPO';

  @override
  String get detailWebsite => 'Website';

  @override
  String get commonClear => 'Clear';

  @override
  String get searchHint => 'Search symbol or company';

  @override
  String get searchIdle => 'Search US stocks by symbol or company name.';

  @override
  String searchNoMatches(String query) {
    return 'No matches for \"$query\".';
  }

  @override
  String get accountUpdated => 'Profile updated';

  @override
  String get accountEmailHint => 'Your email can\'t be changed';

  @override
  String get accountDisplayName => 'Display name';

  @override
  String get accountDisplayNameHint =>
      'Shown on your profile · leave blank to use your email';

  @override
  String get commonSave => 'Save';

  @override
  String get changePwSuccess => 'Password changed';

  @override
  String get changePwCurrent => 'Current password';

  @override
  String get changePwCurrentError => 'Enter your current password';

  @override
  String get changePwNew => 'New password';

  @override
  String get changePwNewError => 'New password must be at least 8 characters';

  @override
  String get changePwConfirm => 'Confirm new password';

  @override
  String get changePwMismatch => 'Passwords don\'t match';

  @override
  String get commonComingSoon => 'Coming soon';

  @override
  String get helpFaqsHeader => 'FAQs';

  @override
  String get helpContactHeader => 'Contact';

  @override
  String get helpEmailUs => 'Email us';

  @override
  String helpEmailCopied(String email) {
    return '$email copied to clipboard';
  }

  @override
  String get helpLiveChat => 'Live chat';

  @override
  String get helpReplyTime => 'We usually reply within 1–2 business days.';

  @override
  String get helpFaqQ1 => 'Why are my quotes delayed?';

  @override
  String get helpFaqA1 =>
      'Market data comes from Finnhub and Financial Modeling Prep. On the free data tier, quotes are delayed and some charts may be unavailable.';

  @override
  String get helpFaqQ2 => 'Which markets are covered?';

  @override
  String get helpFaqA2 =>
      'US-listed stocks and ETFs for now. Wider global coverage is on the roadmap — see Subscriptions.';

  @override
  String get helpFaqQ3 => 'How do I add a holding?';

  @override
  String get helpFaqA3 =>
      'Go to the Portfolio tab, tap +, then enter the symbol, quantity and your buy price. Everything is valued for you automatically.';

  @override
  String get helpFaqQ4 => 'How do price alerts work?';

  @override
  String get helpFaqA4 =>
      'Open a symbol and tap Create alert, or add one from the Alerts tab. When it triggers it shows up in your in-app notifications feed.';

  @override
  String get helpFaqQ5 => 'Is my account secure?';

  @override
  String get helpFaqA5 =>
      'Your session is kept in your device\'s secure storage. On mobile you can also turn on Biometrics under Menu → Security.';

  @override
  String get plansOnFree => 'You\'re on the Free plan';

  @override
  String get plansSubtitle =>
      'Pro unlocks more once it launches — no charge today.';

  @override
  String get plansBadgeCurrent => 'Current';

  @override
  String get plansPriceMonth => '/month';

  @override
  String get plansFreeTagline => 'Everything you need to track US markets.';

  @override
  String get plansFreeFeature1 => 'US stocks & ETFs';

  @override
  String get plansFreeFeature2 => 'Live (delayed) quotes';

  @override
  String get plansFreeFeature3 => 'Watchlist & portfolio';

  @override
  String get plansFreeFeature4 => 'Price alerts + notifications feed';

  @override
  String get plansFreeFeature5 => 'Daily charts';

  @override
  String get plansCurrentPlan => 'Current plan';

  @override
  String get plansProTagline => 'For tracking the whole market, in real time.';

  @override
  String get plansProFeature1 => 'Global markets, not just US';

  @override
  String get plansProFeature2 => 'Real-time quotes (no delay)';

  @override
  String get plansProFeature3 => 'Intraday charts & extended history';

  @override
  String get plansProFeature4 => 'Unlimited alerts';

  @override
  String get plansProFeature5 => 'Priority support';

  @override
  String get plansProNote =>
      'Pro is in development — these features aren\'t available yet.';

  @override
  String get analyticsEstValueTitle => 'Estimated value';

  @override
  String get analyticsEstValueBody =>
      'This line reconstructs your value from each holding\'s daily closing prices (today\'s quantities). Holdings without price history — crypto and some ETFs the data provider doesn\'t cover — aren\'t included, so it can differ from your Total value.';

  @override
  String get analyticsGotIt => 'Got it';

  @override
  String get analyticsPortfolioValue => 'Portfolio value';

  @override
  String get analyticsChartUnavailable => 'Chart unavailable';

  @override
  String get analyticsEstFromCloses => 'Estimated from daily closes';

  @override
  String get analyticsTopContributors => 'Top contributors';

  @override
  String get analyticsQuickStats => 'Quick stats';

  @override
  String get analyticsLargestPosition => 'Largest position';

  @override
  String get analyticsAssetMix => 'Asset mix';

  @override
  String get analyticsEmpty => 'Add holdings to see your analytics.';

  @override
  String analyticsMixStock(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Stocks',
      one: '1 Stock',
    );
    return '$_temp0';
  }

  @override
  String analyticsMixEtf(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ETFs',
      one: '1 ETF',
    );
    return '$_temp0';
  }

  @override
  String analyticsMixCrypto(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Crypto',
      one: '1 Crypto',
    );
    return '$_temp0';
  }

  @override
  String get allocationTitle => 'Allocation';

  @override
  String get allocationByHolding => 'Holding';

  @override
  String get allocationByType => 'Type';

  @override
  String get allocationTapHint => 'Tap a slice';

  @override
  String get timeJustNow => 'just now';

  @override
  String timeMinutesAgo(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String timeHoursAgo(int hours) {
    return '${hours}h ago';
  }

  @override
  String timeDaysAgo(int days) {
    return '${days}d ago';
  }

  @override
  String get allocationOther => 'Other';
}
