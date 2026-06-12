import 'package:flutter/material.dart';

import '../../../core/widgets/coming_soon.dart';

class MarketsScreen extends StatelessWidget {
  const MarketsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Markets')),
        body: const ComingSoon(
          icon: Icons.query_stats,
          title: 'Markets',
          message: 'Browse and search US symbols — build order phase 2.',
        ),
      );
}
