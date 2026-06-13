import 'package:intl/intl.dart';

final _money = NumberFormat.currency(symbol: r'$');

/// Contract rule: money to 2dp, nullable values render as "—".
String formatMoney(num? value) => value == null ? '—' : _money.format(value);

String formatPercent(num? value) =>
    value == null ? '—' : '${value >= 0 ? '+' : ''}${value.toStringAsFixed(2)}%';

/// Explicit + on gains so red/green isn't the only signal.
String formatSignedMoney(num? value) {
  if (value == null) return '—';
  return value >= 0 ? '+${_money.format(value)}' : _money.format(value);
}

final _qty = NumberFormat('#,##0.####');

String formatQty(num value) => _qty.format(value);

final _compactMoney = NumberFormat.compactCurrency(symbol: r'$');

/// The backend relays Finnhub market caps, which are in MILLIONS of USD.
String formatMarketCapMillions(num? millions) =>
    millions == null ? '—' : _compactMoney.format(millions * 1e6);

final _dayMonth = DateFormat('d MMM');

/// Compact "time ago" for feeds. [now] is injectable for tests.
String formatRelative(DateTime time, {DateTime? now}) {
  final diff = (now ?? DateTime.now()).difference(time);
  if (diff.isNegative || diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return _dayMonth.format(time);
}
