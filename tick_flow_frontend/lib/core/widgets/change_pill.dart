import 'package:flutter/material.dart';

import '../formats.dart';
import '../theme.dart';

/// Green/red tinted pill showing a signed percentage change. Null → "—".
class ChangePill extends StatelessWidget {
  const ChangePill({super.key, required this.percent, this.compact = false});

  final double? percent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (percent == null) {
      return Text(
        '—',
        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      );
    }
    final market = theme.extension<MarketColors>()!;
    final color = percent! >= 0 ? market.gain : market.loss;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 8, vertical: compact ? 2 : 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        formatPercent(percent),
        style: tabularDigits(theme.textTheme.labelSmall!)
            .copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
