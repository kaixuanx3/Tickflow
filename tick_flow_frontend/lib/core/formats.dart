import 'package:intl/intl.dart';

final _money = NumberFormat.currency(symbol: r'$');

/// Contract rule: money to 2dp, nullable values render as "—".
String formatMoney(num? value) => value == null ? '—' : _money.format(value);

String formatPercent(num? value) =>
    value == null ? '—' : '${value >= 0 ? '+' : ''}${value.toStringAsFixed(2)}%';
