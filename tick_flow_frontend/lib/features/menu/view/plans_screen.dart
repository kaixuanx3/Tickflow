import 'package:flutter/material.dart';

/// Display-only plans preview. There is no billing — Pro is a "coming soon"
/// roadmap card, not a real purchase (the Pro perks like global data are vendor
/// limitations we can't unlock today).
class PlansScreen extends StatelessWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Plans')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "You're on the Free plan",
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pro unlocks more once it launches — no charge today.',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 20),
                _PlanCard(
                  name: 'Free',
                  badge: 'Current',
                  price: r'$0',
                  priceSuffix: '/month',
                  tagline: 'Everything you need to track US markets.',
                  features: const [
                    'US stocks & ETFs',
                    'Live (delayed) quotes',
                    'Watchlist & portfolio',
                    'Price alerts + notifications feed',
                    'Daily charts',
                  ],
                  buttonLabel: 'Current plan',
                ),
                const SizedBox(height: 16),
                _PlanCard(
                  name: 'Pro',
                  badge: 'Coming soon',
                  badgeAccent: true,
                  highlighted: true,
                  tagline: 'For tracking the whole market, in real time.',
                  features: const [
                    'Global markets, not just US',
                    'Real-time quotes (no delay)',
                    'Intraday charts & extended history',
                    'Unlimited alerts',
                    'Priority support',
                  ],
                  buttonLabel: 'Coming soon',
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    "Pro is in development — these features aren't available yet.",
                    textAlign: TextAlign.center,
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

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.name,
    required this.badge,
    required this.tagline,
    required this.features,
    required this.buttonLabel,
    this.price,
    this.priceSuffix,
    this.badgeAccent = false,
    this.highlighted = false,
  });

  final String name;
  final String badge;
  final String? price;
  final String? priceSuffix;
  final String tagline;
  final List<String> features;
  final String buttonLabel;
  final bool badgeAccent;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlighted ? accent : theme.colorScheme.outlineVariant,
          width: highlighted ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                name,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: highlighted ? accent : null,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeAccent
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: badgeAccent
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (price != null) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  price!,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                if (priceSuffix != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    priceSuffix!,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: 8),
          Text(
            tagline,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          for (final f in features)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle, size: 18, color: accent),
                  const SizedBox(width: 10),
                  Expanded(child: Text(f, style: theme.textTheme.bodyMedium)),
                ],
              ),
            ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: null, // display-only — no billing
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(46)),
              child: Text(buttonLabel),
            ),
          ),
        ],
      ),
    );
  }
}
