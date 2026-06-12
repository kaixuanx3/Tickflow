import 'package:flutter/material.dart';

import '../../../core/widgets/coming_soon.dart';

class PortfolioScreen extends StatelessWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Portfolio')),
        body: const ComingSoon(
          icon: Icons.pie_chart_outline,
          title: 'Portfolio',
          message: 'Holdings, allocation donut and gain/loss — build order phase 4.',
        ),
      );
}
