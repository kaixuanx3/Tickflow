import 'package:flutter/material.dart';

import '../../../core/widgets/coming_soon.dart';

class FavouritesScreen extends StatelessWidget {
  const FavouritesScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Favourites')),
        body: const ComingSoon(
          icon: Icons.star_border,
          title: 'Favourites',
          message: 'Your watchlist with live prices and sparklines — build order phase 3.',
        ),
      );
}
