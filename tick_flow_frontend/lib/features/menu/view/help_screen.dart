import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Static help centre: FAQs, a contact email (tap to copy), and a coming-soon
/// live-chat row. No backend — purely informational.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _supportEmail = 'support@tickflow.my';

  static const _faqs = <(String, String)>[
    (
      'Why are my quotes delayed?',
      'Market data comes from Finnhub and Financial Modeling Prep. On the free '
          'data tier, quotes are delayed and some charts may be unavailable.',
    ),
    (
      'Which markets are covered?',
      'US-listed stocks and ETFs for now. Wider global coverage is on the '
          'roadmap — see Plans.',
    ),
    (
      'How do I add a holding?',
      'Go to the Portfolio tab, tap +, then enter the symbol, quantity and your '
          'buy price. Everything is valued for you automatically.',
    ),
    (
      'How do price alerts work?',
      'Open a symbol and tap Create alert, or add one from the Alerts tab. When '
          'it triggers it shows up in your in-app notifications feed.',
    ),
    (
      'Is my account secure?',
      "Your session is kept in your device's secure storage. On mobile you can "
          'also turn on Biometrics under Menu → Security.',
    ),
  ];

  Future<void> _copyEmail(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: _supportEmail));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$_supportEmail copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'FAQs',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (var i = 0; i < _faqs.length; i++) ...[
                        if (i > 0) const Divider(height: 1),
                        ExpansionTile(
                          title: Text(_faqs[i].$1),
                          shape: const Border(),
                          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          expandedCrossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _faqs[i].$2,
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
                  'Contact',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.mail_outline),
                        title: const Text('Email us'),
                        subtitle: const Text(_supportEmail),
                        trailing: const Icon(Icons.copy_rounded, size: 18),
                        onTap: () => _copyEmail(context),
                      ),
                      const Divider(height: 1),
                      const ListTile(
                        enabled: false,
                        leading: Icon(Icons.chat_bubble_outline),
                        title: Text('Live chat'),
                        subtitle: Text('Coming soon'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'We usually reply within 1–2 business days.',
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
