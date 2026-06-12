import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/api_client.dart';
import '../../data/watchlist/watchlist_store.dart';

/// Favourite toggle used on list rows and the detail app bar.
class StarButton extends ConsumerWidget {
  const StarButton({super.key, required this.symbol});

  final String symbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavourite = ref.watch(
      watchlistProvider.select((list) => list.value?.contains(symbol) ?? false),
    );

    return IconButton(
      tooltip: isFavourite ? 'Remove from favourites' : 'Add to favourites',
      icon: Icon(
        isFavourite ? Icons.star : Icons.star_border,
        color: isFavourite ? Colors.amber : null,
      ),
      onPressed: () async {
        try {
          await ref.read(watchlistProvider.notifier).toggle(symbol);
        } catch (e) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                e is ApiException ? e.message : 'Could not update favourites',
              ),
            ),
          );
        }
      },
    );
  }
}
