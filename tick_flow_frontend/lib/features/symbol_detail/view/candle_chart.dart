import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme.dart';
import '../../../data/markets/market_models.dart';

/// Daily candlesticks, x = candle index (even spacing regardless of
/// weekends/holiday gaps). Caller guarantees a non-empty list.
class CandleChart extends StatelessWidget {
  const CandleChart({super.key, required this.candles});

  final List<Candle> candles;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final market = theme.extension<MarketColors>()!;
    final labelStyle =
        theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final dateFormat = DateFormat('d MMM');

    final minLow = candles.map((c) => c.l).reduce(math.min);
    final maxHigh = candles.map((c) => c.h).reduce(math.max);
    final pad = (maxHigh - minLow) * 0.05 + 0.01;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Body width is in pixels — shrink it as the candle count grows.
        final bodyWidth =
            ((constraints.maxWidth - 48) / candles.length * 0.6).clamp(1.0, 9.0);

        return CandlestickChart(
          CandlestickChartData(
            minY: minLow - pad,
            maxY: maxHigh + pad,
            candlestickSpots: [
              for (var i = 0; i < candles.length; i++)
                CandlestickSpot(
                  x: i.toDouble(),
                  open: candles[i].o,
                  high: candles[i].h,
                  low: candles[i].l,
                  close: candles[i].c,
                ),
            ],
            candlestickPainter: DefaultCandlestickPainter(
              candlestickStyleProvider: (spot, index) {
                final color = spot.close >= spot.open ? market.gain : market.loss;
                return CandlestickStyle(
                  lineColor: color,
                  lineWidth: 1,
                  bodyStrokeColor: color,
                  bodyStrokeWidth: 1,
                  bodyFillColor: color,
                  bodyWidth: bodyWidth,
                  bodyRadius: 1,
                );
              },
            ),
            gridData: FlGridData(
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => FlLine(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 48,
                  getTitlesWidget: (value, meta) =>
                      Text(meta.formattedValue, style: labelStyle),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 26,
                  interval: math.max(1, (candles.length / 4).floorToDouble()),
                  getTitlesWidget: (value, meta) {
                    final i = value.toInt();
                    if (i < 0 || i >= candles.length) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(dateFormat.format(candles[i].time), style: labelStyle),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
