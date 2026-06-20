import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme_mode.dart'; // sharedPreferencesProvider

/// The app's selected locale. `null` means "follow the device" (System).
/// Persisted in shared_preferences and fed to MaterialApp.locale.
class LocaleController extends Notifier<Locale?> {
  static const _key = 'app_locale';

  @override
  Locale? build() {
    final code = ref.watch(sharedPreferencesProvider).getString(_key);
    return (code == null || code.isEmpty) ? null : Locale(code);
  }

  void set(Locale? locale) {
    state = locale;
    final prefs = ref.read(sharedPreferencesProvider);
    if (locale == null) {
      prefs.remove(_key);
    } else {
      prefs.setString(_key, locale.languageCode);
    }
  }
}

final localeProvider = NotifierProvider<LocaleController, Locale?>(LocaleController.new);
