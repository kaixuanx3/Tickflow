import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/biometric_lock.dart';
import '../../../core/theme_mode.dart';
import '../../../data/api/api_client.dart';
import '../../auth/viewmodel/auth_controller.dart';

class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final email = ref.watch(authControllerProvider).value?.email ?? '';
    final mode = ref.watch(themeModeProvider);
    final bioAvailable = ref.watch(biometricAvailableProvider).value ?? false;
    final bioEnabled = ref.watch(biometricEnabledProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Menu')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 8),
        children: [
          _ProfileCard(email: email),
          const _SectionHeader('Preferences'),
          _MenuCard(
            children: [
              _MenuRow(
                icon: Icons.brightness_6_outlined,
                title: 'Appearance',
                value: _themeLabel(mode),
                onTap: () => _showThemeSheet(context, ref, mode),
              ),
            ],
          ),
          if (bioAvailable) ...[
            const _SectionHeader('Security'),
            _MenuCard(
              children: [
                _MenuRow(
                  icon: Icons.fingerprint,
                  title: 'Biometric unlock',
                  onTap: () => _toggleBiometric(context, ref, !bioEnabled),
                  trailing: Switch(
                    value: bioEnabled,
                    onChanged: (v) => _toggleBiometric(context, ref, v),
                  ),
                ),
              ],
            ),
          ],
          const _SectionHeader('About'),
          _MenuCard(
            children: [
              _MenuRow(
                icon: Icons.info_outline,
                title: 'About Tickflow',
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
              label: const Text('Sign out'),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TextButton.icon(
              onPressed: () => _confirmDelete(context, ref),
              icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
              label: Text('Delete account',
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

String _themeLabel(ThemeMode m) => switch (m) {
      ThemeMode.system => 'System',
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
    };

/// First up-to-2 letters of the email's local part, e.g. kaixuanx3 → "KA".
String _initials(String email) {
  final local = email.split('@').first;
  final letters = local.replaceAll(RegExp('[^A-Za-z]'), '');
  if (letters.isEmpty) return email.isEmpty ? '?' : email[0].toUpperCase();
  return letters.substring(0, letters.length >= 2 ? 2 : 1).toUpperCase();
}

Future<void> _toggleBiometric(BuildContext context, WidgetRef ref, bool value) async {
  if (value) {
    final ok = await ref.read(biometricEnabledProvider.notifier).enable();
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not enable biometric unlock')),
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
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final option in const [
            (ThemeMode.system, 'System', Icons.brightness_auto_outlined),
            (ThemeMode.light, 'Light', Icons.light_mode_outlined),
            (ThemeMode.dark, 'Dark', Icons.dark_mode_outlined),
          ])
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

Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Delete account?'),
      content: const Text(
        'This permanently deletes your account, watchlist, portfolio, alerts '
        'and notifications. This cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(dialogContext).colorScheme.error,
          ),
          child: const Text('Delete'),
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
        content: Text(e is ApiException ? e.message : 'Could not delete account'),
      ),
    );
  }
}

/// Account summary card at the top of the menu.
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                _initials(email),
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
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Signed in',
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
