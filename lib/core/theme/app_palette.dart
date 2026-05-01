import 'package:flutter/material.dart';

class AppPalette {
  const AppPalette._();

  static const Color navy = Color(0xFF1B2F5E);
  static const Color deepNavy = Color(0xFF12284D);
  static const Color softNavy = Color(0xFF2C4C84);
  static const Color lightNavy = Color(0xFF3B639E);
  static const Color orange = Color(0xFFE8711A);
  static const Color paleOrange = Color(0xFFFFB978);
  static const Color softOrange = Color(0xFF213C6E);
  static const Color turquoise = Color(0xFF35C9C4);
  static const Color softTurquoise = Color(0xFF7DE7E2);
  static const Color comparisonEmerald = Color(0xFFE8711A);
  static const Color comparisonSoftEmerald = Color(0xFF2B4A80);
  static const Color comparisonBorder = Color(0xFFF3A866);
  static const Color dealsRed = Color(0xFFE8711A);
  static const Color dealsSoftRed = Color(0xFF2A4A82);
  static const Color dealsBorder = Color(0xFFF2A776);
  static const Color shellBackground = Color(0xFF162B52);
  static const Color cardBackground = Color(0xFF1C345F);
  static const Color cardBorder = Color(0xFFEA9A58);
  static const Color panelText = Color(0xFF8BEDEA);
  static const Color mutedText = Color(0xFF63D6D2);
  static const Color shadow = Color(0x141B2F5E);

  // -- Brand-aligned tokens (per BRAND_GUIDELINES.md / UI_DESIGN_GUIDELINES.md) --
  static const Color brandNavy = Color(0xFF1B2F5E);
  static const Color brandNavyDeep = Color(0xFF12284D);
  static const Color brandNavySecondary = Color(0xFF6B7A9A);
  static const Color brandOrange = Color(0xFFE8711A);
  static const Color brandOrangePale = Color(0xFFFFD9BA);
  static const Color brandOrangeBackground = Color(0xFFFFF3E8);
  static const Color brandSurface = Color(0xFFF5F7FF);
  static const Color brandCard = Color(0xFFFFFFFF);
  static const Color brandCardSoft = Color(0xFFF8FAFF);
  static const Color brandCardBorder = Color(0xFFE1E7F4);
  static const Color brandShadow = Color(0x141B2F5E);

  // -- Warm spectrum (for variety beyond a single orange) --
  static const Color orangeWarm = Color(0xFFFFA052);
  static const Color orangeCoral = Color(0xFFF76A4D);
  static const Color orangeCrimson = Color(0xFFC84B1E);

  // -- Sky accents (used sparingly to break warm rhythm) --
  static const Color accentSky = Color(0xFF7FB7E8);
  static const Color accentSkyPale = Color(0xFFD6E6F5);
  static const Color accentSkyDeep = Color(0xFF3B7FBF);

  // -- Reusable brand gradients --
  static const LinearGradient gradientWarmCta = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [orangeWarm, orange, orangeCrimson],
    stops: [0.0, 0.55, 1.0],
  );

  static const LinearGradient gradientWarmSoft = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [orangeWarm, paleOrange],
  );

  static const LinearGradient gradientSky = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentSkyPale, accentSky],
  );
}
