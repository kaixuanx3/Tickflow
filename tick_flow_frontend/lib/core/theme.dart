import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Semantic market colors the Material scheme doesn't model.
/// Always read via `Theme.of(context).extension<MarketColors>()!` — never raw hex
/// in widgets, so gain/loss stay readable in both modes (WCAG-checked shades).
@immutable
class MarketColors extends ThemeExtension<MarketColors> {
  const MarketColors({required this.gain, required this.loss});

  final Color gain;
  final Color loss;

  @override
  MarketColors copyWith({Color? gain, Color? loss}) =>
      MarketColors(gain: gain ?? this.gain, loss: loss ?? this.loss);

  @override
  MarketColors lerp(MarketColors? other, double t) {
    if (other == null) return this;
    return MarketColors(
      gain: Color.lerp(gain, other.gain, t)!,
      loss: Color.lerp(loss, other.loss, t)!,
    );
  }
}

const _seed = Color(0xFF1E40AF); // deep blue; green/red are reserved for gain/loss

/// Monospace digits for prices so live tick updates don't shift layout.
TextStyle tabularDigits(TextStyle base) => GoogleFonts.firaCode(textStyle: base);

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(seedColor: _seed, brightness: brightness);

  return ThemeData(
    colorScheme: scheme,
    textTheme: GoogleFonts.firaSansTextTheme(ThemeData(brightness: brightness).textTheme),
    scaffoldBackgroundColor: dark ? null : const Color(0xFFF8FAFC),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(minimumSize: const Size(64, 48)),
    ),
    extensions: [
      MarketColors(
        gain: dark ? const Color(0xFF4ADE80) : const Color(0xFF15803D),
        loss: dark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
      ),
    ],
  );
}
