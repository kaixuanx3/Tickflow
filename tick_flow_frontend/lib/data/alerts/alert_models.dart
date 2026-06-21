enum AlertRuleType {
  priceAbove('price_above', 'Above'),
  priceBelow('price_below', 'Below');

  const AlertRuleType(this.api, this.label);

  final String api;
  final String label;

  static AlertRuleType fromApi(String? value) => values.firstWhere(
        (r) => r.api == value,
        orElse: () => priceAbove,
      );
}

enum AlertKind {
  oneShot('one_shot', 'One-shot'),
  reArm('re_arm', 'Re-arm');

  const AlertKind(this.api, this.label);

  final String api;
  final String label;

  static AlertKind fromApi(String? value) => values.firstWhere(
        (k) => k.api == value,
        orElse: () => oneShot,
      );
}

/// Engine-owned lifecycle: active → (condition met) → cooldown/done. Clients
/// may pause/resume an alert (active ↔ paused) and re-arm (→ active); the
/// engine owns every other transition.
enum AlertStatus {
  active('Active'),
  cooldown('Cooldown'),
  done('Done'),
  paused('Paused');

  const AlertStatus(this.label);

  final String label;
}

class Alert {
  const Alert({
    required this.id,
    required this.symbol,
    required this.ruleType,
    required this.threshold,
    required this.kind,
    required this.status,
    required this.triggerCount,
    required this.lastTriggeredAt,
  });

  factory Alert.fromJson(Map<String, dynamic> json) => Alert(
        id: json['id'] as String,
        symbol: json['symbol'] as String,
        ruleType: AlertRuleType.fromApi(json['ruleType'] as String?),
        threshold: (json['threshold'] as num).toDouble(),
        kind: AlertKind.fromApi(json['kind'] as String?),
        status: AlertStatus.values.asNameMap()[json['status']] ?? AlertStatus.active,
        triggerCount: json['triggerCount'] as int? ?? 0,
        lastTriggeredAt: json['lastTriggeredAt'] == null
            ? null
            : DateTime.parse(json['lastTriggeredAt'] as String),
      );

  final String id;
  final String symbol;
  final AlertRuleType ruleType;
  final double threshold;
  final AlertKind kind;
  final AlertStatus status;
  final int triggerCount;
  final DateTime? lastTriggeredAt;
}
