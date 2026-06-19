import 'package:flutter/material.dart';

const _palette = <Color>[
  Color(0xFF3B82F6), // blue
  Color(0xFF10B981), // emerald
  Color(0xFFF59E0B), // amber
  Color(0xFF8B5CF6), // violet
  Color(0xFFEC4899), // pink
  Color(0xFF06B6D4), // cyan
  Color(0xFFEF4444), // red
  Color(0xFF14B8A6), // teal
];

/// Deterministic colour per symbol so an avatar always looks the same.
Color _colorFor(String symbol) {
  var hash = 0;
  for (final unit in symbol.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  return _palette[hash % _palette.length];
}

/// Rounded-square avatar with the symbol's first letter, tinted per symbol.
class SymbolAvatar extends StatelessWidget {
  const SymbolAvatar({super.key, required this.symbol, this.size = 40, this.circle = false});

  final String symbol;
  final double size;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(symbol);
    final letter = symbol.isEmpty ? '?' : symbol.substring(0, 1).toUpperCase();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(size * 0.28),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: size * 0.4),
      ),
    );
  }
}
