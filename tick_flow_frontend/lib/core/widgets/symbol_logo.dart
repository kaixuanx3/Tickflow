import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/markets/market_providers.dart';
import 'symbol_avatar.dart';

/// Circular company/fund logo from the backend profile, falling back to the
/// coloured letter avatar when the vendor has no logo (or while it loads).
class SymbolLogo extends ConsumerWidget {
  const SymbolLogo({super.key, required this.symbol, this.size = 40});

  final String symbol;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logo = ref.watch(profileProvider(symbol)).value?.logo;
    final fallback = SymbolAvatar(symbol: symbol, size: size, circle: true);
    if (logo == null || logo.isEmpty) return fallback;
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      // White backing keeps transparent/white logos visible on the dark theme.
      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
      child: Image.network(
        logo,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : fallback,
      ),
    );
  }
}
