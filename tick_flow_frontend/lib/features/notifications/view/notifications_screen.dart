import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formats.dart';
import '../../../core/widgets/error_retry.dart';
import '../../../data/alerts/alert_models.dart';
import '../../../data/api/api_client.dart';
import '../../../data/notifications/notification_models.dart';
import '../viewmodel/alerts_controller.dart';
import '../viewmodel/notifications_feed_controller.dart';
import 'alert_sheet.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
          bottom: const TabBar(
            tabs: [Tab(text: 'My alerts'), Tab(text: 'Triggered')],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          tooltip: 'New alert',
          onPressed: () => showAlertSheet(context),
          child: const Icon(Icons.add_alert),
        ),
        body: const TabBarView(
          children: [_AlertsTab(), _TriggeredTab()],
        ),
      ),
    );
  }
}

class _AlertsTab extends ConsumerWidget {
  const _AlertsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final alerts = ref.watch(alertsProvider);

    return alerts.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorRetry(
        message: '$e',
        onRetry: () => ref.invalidate(alertsProvider),
      ),
      data: (list) {
        if (list.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_alert,
                      size: 48, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(height: 12),
                  Text('No alerts yet', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Get notified when a price crosses your threshold.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => showAlertSheet(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Create your first alert'),
                  ),
                ],
              ),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () => ref.refresh(alertsProvider.future),
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 80), // FAB clearance
            itemCount: list.length,
            itemBuilder: (_, i) => _AlertRow(alert: list[i]),
          ),
        );
      },
    );
  }
}

class _AlertRow extends ConsumerWidget {
  const _AlertRow({required this.alert});

  final Alert alert;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final a = alert;

    return ListTile(
      onTap: () => showAlertSheet(context, existing: a),
      title: Row(
        children: [
          Text(a.symbol, style: theme.textTheme.titleSmall),
          const SizedBox(width: 8),
          _StatusChip(status: a.status),
        ],
      ),
      subtitle: Text(
        '${a.ruleType.label} ${formatMoney(a.threshold)} · ${a.kind.label}'
        '${a.triggerCount > 0 ? ' · triggered ${a.triggerCount}×' : ''}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: a.status == AlertStatus.active
          ? null
          : TextButton(
              onPressed: () async {
                try {
                  await ref.read(alertsProvider.notifier).rearm(a.id);
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        e is ApiException ? e.message : 'Could not re-arm the alert',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Re-arm'),
            ),
    );
  }
}

class _TriggeredTab extends ConsumerWidget {
  const _TriggeredTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final feed = ref.watch(notificationsFeedProvider);

    return feed.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorRetry(
        message: '$e',
        onRetry: () => ref.invalidate(notificationsFeedProvider),
      ),
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_none,
                      size: 48, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(height: 12),
                  Text('Nothing triggered yet', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    'When one of your alerts fires, it shows up here.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () => ref.refresh(notificationsFeedProvider.future),
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 80), // FAB clearance
            itemCount: items.length,
            itemBuilder: (_, i) => _NotificationRow(item: items[i]),
          ),
        );
      },
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({required this.item});

  final TriggeredNotification item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: () => context.push('/symbol/${item.symbol}'),
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.secondaryContainer,
        child: Icon(
          Icons.notifications_active,
          size: 20,
          color: theme.colorScheme.onSecondaryContainer,
        ),
      ),
      title: Text(item.message),
      subtitle: Text(formatRelative(item.createdAt)),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final AlertStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (bg, fg) = switch (status) {
      AlertStatus.active => (scheme.secondaryContainer, scheme.onSecondaryContainer),
      AlertStatus.cooldown => (scheme.tertiaryContainer, scheme.onTertiaryContainer),
      AlertStatus.done => (scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg),
      ),
    );
  }
}
