import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_localizations.dart';

/// Static help centre: FAQs, a contact email (tap to copy), and a coming-soon
/// live-chat row. No backend — purely informational.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _supportEmail = 'support@tickflow.my';

  Future<void> _copyEmail(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    await Clipboard.setData(const ClipboardData(text: _supportEmail));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.helpEmailCopied(_supportEmail))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final faqs = <(String, String)>[
      (l10n.helpFaqQ1, l10n.helpFaqA1),
      (l10n.helpFaqQ2, l10n.helpFaqA2),
      (l10n.helpFaqQ3, l10n.helpFaqA3),
      (l10n.helpFaqQ4, l10n.helpFaqA4),
      (l10n.helpFaqQ5, l10n.helpFaqA5),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.menuHelpSupport)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.helpFaqsHeader,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (var i = 0; i < faqs.length; i++) ...[
                        if (i > 0) const Divider(height: 1),
                        ExpansionTile(
                          title: Text(faqs[i].$1),
                          shape: const Border(),
                          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          expandedCrossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              faqs[i].$2,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.helpContactHeader,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.mail_outline),
                        title: Text(l10n.helpEmailUs),
                        subtitle: const Text(_supportEmail),
                        trailing: const Icon(Icons.copy_rounded, size: 18),
                        onTap: () => _copyEmail(context),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        enabled: false,
                        leading: const Icon(Icons.chat_bubble_outline),
                        title: Text(l10n.helpLiveChat),
                        subtitle: Text(l10n.commonComingSoon),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    l10n.helpReplyTime,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
