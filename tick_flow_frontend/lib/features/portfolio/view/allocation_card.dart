import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/formats.dart';
import '../../../core/theme.dart';
import '../../../data/portfolio/portfolio_models.dart';
import '../viewmodel/allocation.dart';

class AllocationCard extends StatefulWidget {
  const AllocationCard({super.key, required this.summary});

  final PortfolioSummary summary;

  @override
  State<AllocationCard> createState() => _AllocationCardState();
}

class _AllocationCardState extends State<AllocationCard> {
  AllocationMode _mode = AllocationMode.holding;
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final slices = condenseSlices(allocationSlices(widget.summary, _mode));
    if (slices.isEmpty) return const SizedBox.shrink();
    final colors = _palette(theme.colorScheme);

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('Allocation', style: theme.textTheme.labelLarge)),
                SegmentedButton<AllocationMode>(
                  segments: const [
                    ButtonSegment(value: AllocationMode.holding, label: Text('Holding')),
                    ButtonSegment(value: AllocationMode.assetType, label: Text('Type')),
                  ],
                  selected: {_mode},
                  showSelectedIcon: false,
                  style: const ButtonStyle(visualDensity: VisualDensity.compact),
                  onSelectionChanged: (s) => setState(() {
                    _mode = s.first;
                    _touchedIndex = -1; // slices change with the mode
                  }),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Big centred donut with the largest slice called out in the hole.
            SizedBox(
              height: 210,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      centerSpaceRadius: 72,
                      sectionsSpace: 2,
                      pieTouchData: PieTouchData(
                        touchCallback: (event, response) {
                          if (event is! FlTapUpEvent) return;
                          setState(() {
                            final i = response?.touchedSection
                                    ?.touchedSectionIndex ??
                                -1;
                            _touchedIndex = (i == _touchedIndex) ? -1 : i;
                          });
                        },
                      ),
                      sections: [
                        for (var i = 0; i < slices.length; i++)
                          PieChartSectionData(
                            value: slices[i].value,
                            color: colors[i % colors.length],
                            radius: i == _touchedIndex ? 38 : 30,
                            showTitle: false,
                          ),
                      ],
                    ),
                  ),
                  SizedBox(width: 132, child: _centerContent(theme, slices)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Legend in two columns, paired two slices per row.
            for (var i = 0; i < slices.length; i += 2)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: _legendItem(theme, slices[i], colors[i % colors.length]),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: i + 1 < slices.length
                          ? _legendItem(theme, slices[i + 1],
                              colors[(i + 1) % colors.length])
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// One legend entry: colour dot, label, right-aligned percent.
  Widget _legendItem(ThemeData theme, DonutSlice slice, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            slice.label,
            style: theme.textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${slice.percent.toStringAsFixed(1)}%',
          style: tabularDigits(theme.textTheme.bodySmall!)
              .copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  /// Donut hole: the tapped slice's details, or a hint to tap when nothing
  /// is selected.
  Widget _centerContent(ThemeData theme, List<DonutSlice> slices) {
    if (_touchedIndex < 0 || _touchedIndex >= slices.length) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.touch_app_outlined,
              size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 4),
          Text(
            'Tap a slice',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      );
    }
    final slice = slices[_touchedIndex];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          slice.label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style:
              theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          '${slice.percent.toStringAsFixed(1)}%',
          style: tabularDigits(theme.textTheme.headlineSmall!)
              .copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          formatMoney(slice.value),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

List<Color> _palette(ColorScheme scheme) => [
      scheme.primary,
      scheme.tertiary,
      const Color(0xFF0EA5E9), // sky
      const Color(0xFFF59E0B), // amber
      scheme.secondary,
      scheme.outline, // last slot doubles as "Other"
    ];
