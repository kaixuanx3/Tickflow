import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/biometric_lock.dart';
import '../../../core/locale_controller.dart';
import '../../../core/theme_mode.dart';
import '../../../data/api/api_client.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/viewmodel/auth_controller.dart';

class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(authControllerProvider).value;
    final email = user?.email ?? '';
    final mode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final bioAvailable = ref.watch(biometricSupportedProvider);
    final bioEnabled = ref.watch(biometricEnabledProvider);
    // Unknown (older session) → assume there's a password; Google-only hides it.
    final canChangePassword = user?.hasPassword ?? true;
    final pushOn = user?.pushEnabled ?? true;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.menuTitle)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 8),
        children: [
          _ProfileCard(name: user?.name, email: email),
          _SectionHeader(l10n.menuSectionAccount),
          _MenuCard(
            children: [
              _MenuRow(
                icon: Icons.person_outline,
                title: l10n.menuAccountDetails,
                onTap: () => context.push('/account'),
              ),
              _MenuRow(
                icon: Icons.workspace_premium_outlined,
                title: l10n.menuSubscriptions,
                value: l10n.menuPlanFree,
                onTap: () => context.push('/plans'),
              ),
            ],
          ),
          _SectionHeader(l10n.menuSectionPreferences),
          _MenuCard(
            children: [
              _MenuRow(
                icon: Icons.brightness_6_outlined,
                title: l10n.menuAppearance,
                value: _themeLabel(l10n, mode),
                onTap: () => _showThemeSheet(context, ref, mode),
              ),
              _MenuRow(
                icon: Icons.language,
                title: l10n.menuLanguage,
                value: _languageLabel(l10n, locale),
                onTap: () => _showLanguageSheet(context, ref, locale),
              ),
            ],
          ),
          if (canChangePassword || bioAvailable) ...[
            _SectionHeader(l10n.menuSectionSecurity),
            _MenuCard(
              children: [
                if (canChangePassword)
                  _MenuRow(
                    icon: Icons.lock_outline,
                    title: l10n.menuChangePassword,
                    onTap: () => context.push('/change-password'),
                  ),
                if (bioAvailable)
                  _MenuRow(
                    icon: Icons.fingerprint,
                    title: l10n.menuBiometrics,
                    onTap: () => _toggleBiometric(context, ref, !bioEnabled),
                    trailing: Switch(
                      value: bioEnabled,
                      onChanged: (v) => _toggleBiometric(context, ref, v),
                    ),
                  ),
              ],
            ),
          ],
          _SectionHeader(l10n.menuSectionNotifications),
          _MenuCard(
            children: [
              _MenuRow(
                icon: Icons.notifications_outlined,
                title: l10n.menuPushNotifications,
                onTap: () => _togglePush(context, ref, !pushOn),
                trailing: Switch(
                  value: pushOn,
                  onChanged: (v) => _togglePush(context, ref, v),
                ),
              ),
            ],
          ),
          _SectionHeader(l10n.menuSectionSupport),
          _MenuCard(
            children: [
              _MenuRow(
                icon: Icons.help_outline,
                title: l10n.menuHelpSupport,
                onTap: () => context.push('/help'),
              ),
              _MenuRow(
                icon: Icons.info_outline,
                title: l10n.menuAboutApp,
                onTap: () => _showAbout(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
            child: OutlinedButton.icon(
              onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
              icon: const Icon(Icons.logout),
              label: Text(l10n.menuSignOut),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TextButton.icon(
              onPressed: () => _confirmDelete(context, ref),
              icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
              label: Text(l10n.menuDeleteAccount,
                  style: TextStyle(color: theme.colorScheme.error)),
              style: TextButton.styleFrom(minimumSize: const Size.fromHeight(46)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Center(
              child: Text(
                'Tickflow v1.0.0 · Market data via Finnhub & FMP',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _themeLabel(AppLocalizations l10n, ThemeMode m) => switch (m) {
      ThemeMode.system => l10n.optionSystem,
      ThemeMode.light => l10n.themeLight,
      ThemeMode.dark => l10n.themeDark,
    };

String _languageLabel(AppLocalizations l10n, Locale locale) =>
    locale.languageCode == 'zh' ? l10n.languageChinese : l10n.languageEnglish;

/// Avatar initials from a name or email: "Alex Thompson" → "AT",
/// "kaixuanx3@gmail.com" → "KA".
String _initials(String label) {
  final source = label.contains('@') ? label.split('@').first : label;
  final words = source.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.length >= 2) {
    return (words[0][0] + words[1][0]).toUpperCase();
  }
  final letters = source.replaceAll(RegExp('[^A-Za-z]'), '');
  if (letters.isEmpty) return label.isEmpty ? '?' : label[0].toUpperCase();
  return letters.substring(0, letters.length >= 2 ? 2 : 1).toUpperCase();
}

Future<void> _togglePush(BuildContext context, WidgetRef ref, bool value) async {
  try {
    await ref.read(authControllerProvider.notifier).updateProfile(pushEnabled: value);
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e is ApiException
            ? e.message
            : AppLocalizations.of(context).notificationsUpdateError),
      ),
    );
  }
}

Future<void> _toggleBiometric(BuildContext context, WidgetRef ref, bool value) async {
  if (value) {
    final ok = await ref.read(biometricEnabledProvider.notifier).enable();
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).biometricSetupHint)),
      );
    }
  } else {
    await ref.read(biometricEnabledProvider.notifier).disable();
  }
}

void _showAbout(BuildContext context) => showAboutDialog(
      context: context,
      applicationName: 'Tickflow',
      applicationVersion: '1.0.0',
      applicationLegalese:
          'Market data via Finnhub & Financial Modeling Prep — quotes are '
          'delayed on the free data tier.',
    );

void _showThemeSheet(BuildContext context, WidgetRef ref, ThemeMode current) {
  final l10n = AppLocalizations.of(context);
  final options = <(ThemeMode, String, IconData)>[
    (ThemeMode.system, l10n.optionSystem, Icons.brightness_auto_outlined),
    (ThemeMode.light, l10n.themeLight, Icons.light_mode_outlined),
    (ThemeMode.dark, l10n.themeDark, Icons.dark_mode_outlined),
  ];
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final option in options)
            ListTile(
              leading: Icon(option.$3),
              title: Text(option.$2),
              trailing: current == option.$1 ? const Icon(Icons.check) : null,
              onTap: () {
                ref.read(themeModeProvider.notifier).set(option.$1);
                Navigator.of(sheetContext).pop();
              },
            ),
        ],
      ),
    ),
  );
}

void _showLanguageSheet(BuildContext context, WidgetRef ref, Locale current) {
  final l10n = AppLocalizations.of(context);
  final options = <(Locale, String, IconData)>[
    (const Locale('en'), l10n.languageEnglish, Icons.translate_outlined),
    (const Locale('zh'), l10n.languageChinese, Icons.translate_outlined),
  ];
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final option in options)
            ListTile(
              leading: Icon(option.$3),
              title: Text(option.$2),
              trailing: current.languageCode == option.$1.languageCode
                  ? const Icon(Icons.check)
                  : null,
              onTap: () {
                ref.read(localeProvider.notifier).set(option.$1);
                Navigator.of(sheetContext).pop();
              },
            ),
        ],
      ),
    ),
  );
}

Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.deleteAccountTitle),
      content: Text(l10n.deleteAccountBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.commonCancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(dialogContext).colorScheme.error,
          ),
          child: Text(l10n.commonDelete),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  try {
    // On success the session clears and the router redirects to login.
    await ref.read(authControllerProvider.notifier).deleteAccount();
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e is ApiException ? e.message : l10n.deleteAccountError),
      ),
    );
  }
}

/// Account summary card at the top of the menu.
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.name, required this.email});

  final String? name;
  final String email;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasName = name != null && name!.isNotEmpty;
    final primary = hasName ? name! : email;
    final secondary = hasName ? email : AppLocalizations.of(context).menuSignedIn;
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                _initials(primary),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    primary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    secondary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small uppercase group label, e.g. "PREFERENCES".
class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Text(
        label.toUpperCase(),
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

/// A card grouping one or more [_MenuRow]s, hairline-divided.
class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 64),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Single-line settings row: icon tile · title · optional value/trailing · chevron.
class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.title,
    this.value,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? value;
  final VoidCallback? onTap;

  /// Replaces the trailing chevron (e.g. a Switch for a toggle row).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
            if (value != null) ...[
              Text(
                value!,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(width: 6),
            ],
            if (trailing != null)
              trailing!
            else if (onTap != null)
              Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
