import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/error_retry.dart';
import '../viewmodel/portfolio_controller.dart';
import 'allocation_card.dart';

/// Pushed from the Portfolio tab's "Analytics" link. Holds the portfolio's
/// charts and breakdowns (allocation donut today; the value chart and more
/// land here next).
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(portfolioProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: summary.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorRetry(
          message: '$e',
          onRetry: () => ref.invalidate(portfolioProvider),
        ),
        data: (s) => s.holdings.isEmpty
            ? const _EmptyAnalytics()
            : ListView(
                children: [
                  const SizedBox(height: 8),
                  AllocationCard(summary: s),
                  const SizedBox(height: 16),
                ],
              ),
      ),
    );
  }
}

class _EmptyAnalytics extends StatelessWidget {
  const _EmptyAnalytics();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Add holdings to see your analytics.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}
