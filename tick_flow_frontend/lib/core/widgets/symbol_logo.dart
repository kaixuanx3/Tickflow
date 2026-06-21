import 'package:cached_network_image/cached_network_image.dart';
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
      child: CachedNetworkImage(
        imageUrl: logo,
        fit: BoxFit.cover,
        // Letter avatar while it downloads / if it fails — never a blank box.
        // Once fetched, it's served from the device disk cache (near-instant on
        // reload); the package auto-evicts (~200 files / 30 days), so it stays
        // tiny. On web the browser cache handles persistence instead.
        placeholder: (_, _) => fallback,
        errorWidget: (_, _, _) => fallback,
        fadeInDuration: const Duration(milliseconds: 200),
      ),
    );
  }
}
