import 'package:flutter_test/flutter_test.dart';
import 'package:tick_flow_app/data/alerts/alert_models.dart';

void main() {
  test('parses a full alert payload', () {
    final a = Alert.fromJson(const {
      'id': 'a1',
      'userId': 'u1',
      'symbol': 'AAPL',
      'ruleType': 'price_below',
      'threshold': 150.5,
      'kind': 're_arm',
      'status': 'cooldown',
      'triggerCount': 3,
      'lastTriggeredAt': '2026-06-12T10:00:00.000Z',
      'createdAt': '2026-06-01T00:00:00.000Z',
    });

    expect(a.ruleType, AlertRuleType.priceBelow);
    expect(a.kind, AlertKind.reArm);
    expect(a.status, AlertStatus.cooldown);
    expect(a.threshold, 150.5);
    expect(a.triggerCount, 3);
    expect(a.lastTriggeredAt!.toUtc().hour, 10);
  });

  test('tolerates never-triggered alerts and unknown enum values', () {
    final a = Alert.fromJson(const {
      'id': 'a2',
      'symbol': 'TSLA',
      'ruleType': 'percent_move', // not supported by this client version
      'threshold': 5,
      'kind': 'one_shot',
      'status': 'expired', // not a status this client version knows
      'lastTriggeredAt': null,
    });

    expect(a.ruleType, AlertRuleType.priceAbove); // safe fallback
    expect(a.status, AlertStatus.active);
    expect(a.triggerCount, 0);
    expect(a.lastTriggeredAt, isNull);
  });
}
