import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tick_flow_app/data/api/api_client.dart';
import 'package:tick_flow_app/data/notifications/notification_models.dart';
import 'package:tick_flow_app/data/notifications/notifications_repository.dart';
import 'package:tick_flow_app/features/notifications/viewmodel/notifications_feed_controller.dart';

class FakeNotificationsRepository implements NotificationsRepository {
  FakeNotificationsRepository(this.items);

  List<TriggeredNotification> items;
  bool fail = false;
  int fetches = 0;

  @override
  Future<List<TriggeredNotification>> fetch() async {
    fetches++;
    if (fail) throw const ApiException(502, 'vendor down');
    return items;
  }
}

TriggeredNotification _n(String id) => TriggeredNotification(
      id: id,
      symbol: 'AAPL',
      message: 'AAPL is above \$200 (now \$201)',
      price: 201,
      createdAt: DateTime.utc(2026, 6, 12, 10),
    );

void main() {
  test('parses a notification payload', () {
    final n = TriggeredNotification.fromJson(const {
      'id': 'n1',
      'symbol': 'TSLA',
      'message': 'TSLA is below \$100 (now \$99)',
      'price': 99,
      'createdAt': '2026-06-12T10:00:00.000Z',
    });
    expect(n.symbol, 'TSLA');
    expect(n.price, 99);
    expect(n.createdAt.toUtc().hour, 10);
  });

  test('loads the feed', () async {
    final container = ProviderContainer(
      overrides: [
        notificationsRepositoryProvider
            .overrideWithValue(FakeNotificationsRepository([_n('a'), _n('b')])),
      ],
    );
    addTearDown(container.dispose);

    final feed = await container.read(notificationsFeedProvider.future);
    expect(feed, hasLength(2));
  });

  test('surfaces errors', () async {
    final container = ProviderContainer(
      overrides: [
        notificationsRepositoryProvider
            .overrideWithValue(FakeNotificationsRepository([])..fail = true),
      ],
    );
    addTearDown(container.dispose);

    // Mount the provider and let build() settle into AsyncError.
    container.listen(notificationsFeedProvider, (_, _) {});
    await Future<void>.delayed(const Duration(milliseconds: 10));

    final state = container.read(notificationsFeedProvider);
    expect(state.hasError, isTrue);
    expect(state.error, isA<ApiException>());
  });
}
