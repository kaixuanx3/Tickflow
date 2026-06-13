import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/notifications/notification_models.dart';
import '../../../data/notifications/notifications_repository.dart';

/// Read-only feed of triggered alerts. Refreshed by pull-to-refresh; the
/// reliable path on web where FCM push is unavailable.
class NotificationsFeedController extends AsyncNotifier<List<TriggeredNotification>> {
  @override
  Future<List<TriggeredNotification>> build() =>
      ref.watch(notificationsRepositoryProvider).fetch();
}

final notificationsFeedProvider =
    AsyncNotifierProvider<NotificationsFeedController, List<TriggeredNotification>>(
  NotificationsFeedController.new,
);
