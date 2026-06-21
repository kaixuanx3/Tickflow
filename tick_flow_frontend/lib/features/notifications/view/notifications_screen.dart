import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/formats.dart';
import '../../../core/widgets/error_retry.dart';
import '../../../data/alerts/alert_models.dart';
import '../../../data/api/api_client.dart';
import '../../../data/markets/quotes_cache.dart';
import '../../../data/notifications/notification_models.dart';
import '../../../l10n/app_localizations.dart';
import '../viewmodel/alerts_controller.dart';
import '../viewmodel/notifications_feed_controller.dart';
import 'alert_sheet.dart';

String _ruleLabel(AppLocalizations l10n, AlertRuleType r) => switch (r) {
      AlertRuleType.priceAbove => l10n.alertRuleAbove,
      AlertRuleType.priceBelow => l10n.alertRuleBelow,
    };

String _statusLabel(AppLocalizations l10n, AlertStatus s) => switch (s) {
      AlertStatus.active => l10n.alertStatusActive,
      AlertStatus.cooldown => l10n.alertStatusCooldown,
      AlertStatus.done => l10n.alertStatusDone,
      AlertStatus.paused => l10n.alertStatusPaused,
    };

/// Localized relative time for the Triggered feed (e.g. "2h ago" / "2 小时前").
String _relativeTime(BuildContext context, DateTime time) {
  final l10n = AppLocalizations.of(context);
  final diff = DateTime.now().difference(time);
  if (diff.isNegative || diff.inSeconds < 60) return l10n.timeJustNow;
  if (diff.inMinutes < 60) return l10n.timeMinutesAgo(diff.inMinutes);
  if (diff.inHours < 24) return l10n.timeHoursAgo(diff.inHours);
  if (diff.inDays < 7) return l10n.timeDaysAgo(diff.inDays);
  return DateFormat.MMMd(Localizations.localeOf(context).toString()).format(time);
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.notifTitle),
          bottom: TabBar(
            tabs: [Tab(text: l10n.notifTabAlerts), Tab(text: l10n.notifTabTriggered)],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          tooltip: l10n.notifNewAlert,
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
    final l10n = AppLocalizations.of(context);
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
                  Text(l10n.alertsEmptyTitle, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    l10n.alertsEmptyBody,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => showAlertSheet(context),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.alertsCreateFirst),
                  ),
                ],
              ),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () => ref.refresh(alertsProvider.future),
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 80), // gap below tabs + FAB clearance
            itemCount: list.length,
            itemBuilder: (_, i) => _AlertRow(alert: list[i]),
          ),
        );
      },
    );
  }
}

class _AlertRow extends ConsumerStatefulWidget {
  const _AlertRow({required this.alert});

  final Alert alert;

  @override
  ConsumerState<_AlertRow> createState() => _AlertRowState();
}

class _AlertRowState extends ConsumerState<_AlertRow> {
  @override
  void initState() {
    super.initState();
    // Snapshot quote for the "· now $price" reference (REST batch, debounced).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(quotesProvider.notifier).request(widget.alert.symbol);
    });
  }

  /// The toggle reads ON while the engine is watching this alert.
  bool get _armed =>
      widget.alert.status == AlertStatus.active ||
      widget.alert.status == AlertStatus.cooldown;

  Future<void> _toggle(bool on) async {
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(alertsProvider.notifier);
    try {
      // off→on resumes a paused alert / re-arms a done|cooldown one (both → active);
      // on→off pauses an active|cooldown one.
      on ? await notifier.rearm(widget.alert.id) : await notifier.pause(widget.alert.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is ApiException ? e.message : l10n.alertUpdateError)),
      );
    }
  }

  Future<void> _confirmDelete() async {
    final l10n = AppLocalizations.of(context);
    final a = widget.alert;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.alertDeleteTitle(a.symbol)),
        content: Text(
          l10n.alertDeleteContent(_ruleLabel(l10n, a.ruleType), formatMoney(a.threshold)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.commonCancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.commonDelete)),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ref.read(alertsProvider.notifier).removeAlert(a.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is ApiException ? e.message : l10n.commonGenericError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final a = widget.alert;
    final quote = ref.watch(quotesProvider.select((m) => m[a.symbol]));

    final rule = StringBuffer()
      ..write(_ruleLabel(l10n, a.ruleType))
      ..write(' ')
      ..write(formatMoney(a.threshold));
    if (quote != null) {
      rule
        ..write(' · ')
        ..write(l10n.alertNow)
        ..write(' ')
        ..write(formatMoney(quote.price));
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showAlertSheet(context, existing: a),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
          child: Row(
            children: [
              _SymbolAvatar(symbol: a.symbol),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            a.symbol,
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusChip(status: a.status),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      rule.toString(),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Tooltip(
                message: _armed ? l10n.alertPauseTooltip : l10n.alertResumeTooltip,
                child: Switch(value: _armed, onChanged: _toggle),
              ),
              IconButton(
                tooltip: l10n.alertDeleteButton,
                icon: const Icon(Icons.delete_outline),
                color: theme.colorScheme.onSurfaceVariant,
                onPressed: _confirmDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Rounded-square ticker monogram (first two letters of the symbol).
class _SymbolAvatar extends StatelessWidget {
  const _SymbolAvatar({required this.symbol});

  final String symbol;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = symbol.length >= 2 ? symbol.substring(0, 2) : symbol;
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        initials,
        style: theme.textTheme.labelLarge
            ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.5),
      ),
    );
  }
}

class _TriggeredTab extends ConsumerWidget {
  const _TriggeredTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
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
                  Text(l10n.triggeredEmptyTitle, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    l10n.triggeredEmptyBody,
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
      subtitle: Text(_relativeTime(context, item.createdAt)),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final AlertStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final (bg, fg) = switch (status) {
      AlertStatus.active => (scheme.secondaryContainer, scheme.onSecondaryContainer),
      AlertStatus.cooldown => (scheme.tertiaryContainer, scheme.onTertiaryContainer),
      AlertStatus.done => (scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
      AlertStatus.paused => (scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _statusLabel(l10n, status).toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg),
      ),
    );
  }
}
