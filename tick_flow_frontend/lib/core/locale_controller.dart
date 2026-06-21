import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme_mode.dart'; // sharedPreferencesProvider

/// The app's selected locale. Defaults to English (not the device language),
/// with Chinese as the only other option. Persisted in shared_preferences and
/// fed to MaterialApp.locale.
class LocaleController extends Notifier<Locale> {
  static const _key = 'app_locale';

  @override
  Locale build() {
    final code = ref.watch(sharedPreferencesProvider).getString(_key);
    return Locale(code == null || code.isEmpty ? 'en' : code);
  }

  void set(Locale locale) {
    state = locale;
    ref.read(sharedPreferencesProvider).setString(_key, locale.languageCode);
  }
}

final localeProvider = NotifierProvider<LocaleController, Locale>(LocaleController.new);
