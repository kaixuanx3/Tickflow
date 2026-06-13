class TriggeredNotification {
  const TriggeredNotification({
    required this.id,
    required this.symbol,
    required this.message,
    required this.price,
    required this.createdAt,
  });

  factory TriggeredNotification.fromJson(Map<String, dynamic> json) =>
      TriggeredNotification(
        id: json['id'] as String,
        symbol: json['symbol'] as String,
        message: json['message'] as String,
        price: (json['price'] as num).toDouble(),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  final String id;
  final String symbol;
  final String message;
  final double price;
  final DateTime createdAt;
}
