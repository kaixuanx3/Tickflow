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
}
