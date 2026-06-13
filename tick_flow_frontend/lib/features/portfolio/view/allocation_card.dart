import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

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
                  onSelectionChanged: (s) => setState(() => _mode = s.first),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 168,
              child: Row(
                children: [
                  SizedBox(
                    width: 150,
                    child: PieChart(
                      PieChartData(
                        centerSpaceRadius: 46,
                        sectionsSpace: 2,
                        sections: [
                          for (var i = 0; i < slices.length; i++)
                            PieChartSectionData(
                              value: slices[i].value,
                              color: colors[i % colors.length],
                              radius: 26,
                              showTitle: false,
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          for (var i = 0; i < slices.length; i++)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: colors[i % colors.length],
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      slices[i].label,
                                      style: theme.textTheme.bodySmall,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '${slices[i].percent.toStringAsFixed(1)}%',
                                    style: tabularDigits(theme.textTheme.bodySmall!)
                                        .copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
