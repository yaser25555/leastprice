import 'package:flutter/material.dart';

final ValueNotifier<bool> isFeminineTheme = ValueNotifier<bool>(false);


final ValueNotifier<bool> isFeminineTheme = ValueNotifier<bool>(false);


class AppPalette {
  const AppPalette._();

  static Color get navy => isFeminineTheme.value ? const Color(0xFF005A9C) : const Color(0xFF1B2F5E);
  static Color get deepNavy => isFeminineTheme.value ? const Color(0xFF003F7A) : const Color(0xFF12284D);
  static Color get softNavy => isFeminineTheme.value ? const Color(0xFF3388CC) : const Color(0xFF2C4C84);
  static Color get lightNavy => isFeminineTheme.value ? const Color(0xFF55AADD) : const Color(0xFF3B639E);
  static Color get orange => isFeminineTheme.value ? const Color(0xFFFF4081) : const Color(0xFFE8711A);
  static Color get paleOrange => isFeminineTheme.value ? const Color(0xFFFF80AB) : const Color(0xFFFFB978);
  static Color get softOrange => isFeminineTheme.value ? const Color(0xFF004C8C) : const Color(0xFF213C6E);
  static Color get turquoise => isFeminineTheme.value ? const Color(0xFFE040FB) : const Color(0xFF35C9C4);
  static Color get softTurquoise => isFeminineTheme.value ? const Color(0xFFEA80FC) : const Color(0xFF7DE7E2);
  static Color get comparisonEmerald => isFeminineTheme.value ? const Color(0xFFFF4081) : const Color(0xFFE8711A);
  static Color get comparisonSoftEmerald => isFeminineTheme.value ? const Color(0xFF005A9C) : const Color(0xFF2B4A80);
  static Color get comparisonBorder => isFeminineTheme.value ? const Color(0xFFFF80AB) : const Color(0xFFF3A866);
  static Color get dealsRed => isFeminineTheme.value ? const Color(0xFFFF4081) : const Color(0xFFE8711A);
  static Color get dealsSoftRed => isFeminineTheme.value ? const Color(0xFF005A9C) : const Color(0xFF2A4A82);
  static Color get dealsBorder => isFeminineTheme.value ? const Color(0xFFFF80AB) : const Color(0xFFF2A776);
  static Color get shellBackground => isFeminineTheme.value ? const Color(0xFF003F7A) : const Color(0xFF162B52);
  static Color get cardBackground => isFeminineTheme.value ? const Color(0xFF004C8C) : const Color(0xFF1C345F);
  static Color get cardBorder => isFeminineTheme.value ? const Color(0xFFFF80AB) : const Color(0xFFEA9A58);
  static Color get panelText => isFeminineTheme.value ? const Color(0xFFFFE4FF) : const Color(0xFF8BEDEA);
  static Color get mutedText => isFeminineTheme.value ? const Color(0xFFFFB3FF) : const Color(0xFF63D6D2);
  static Color get shadow => isFeminineTheme.value ? const Color(0x14005A9C) : const Color(0x141B2F5E);

  // -- Brand-aligned tokens (per BRAND_GUIDELINES.md / UI_DESIGN_GUIDELINES.md) --
  static Color get brandNavy => isFeminineTheme.value ? Color(0xFF1B2F5E) : Color(0xFF1B2F5E);
  static Color get brandNavyDeep => isFeminineTheme.value ? Color(0xFF12284D) : Color(0xFF12284D);
  static Color get brandNavySecondary => isFeminineTheme.value ? Color(0xFF6B7A9A) : Color(0xFF6B7A9A);
  static Color get brandOrange => isFeminineTheme.value ? Color(0xFFE8711A) : Color(0xFFE8711A);
  static Color get brandOrangePale => isFeminineTheme.value ? Color(0xFFFFD9BA) : Color(0xFFFFD9BA);
  static Color get brandOrangeBackground => isFeminineTheme.value ? Color(0xFFFFF3E8) : Color(0xFFFFF3E8);
  static Color get brandSurface => isFeminineTheme.value ? Color(0xFFF5F7FF) : Color(0xFFF5F7FF);
  static Color get brandCard => isFeminineTheme.value ? Color(0xFFFFFFFF) : Color(0xFFFFFFFF);
  static Color get brandCardSoft => isFeminineTheme.value ? Color(0xFFF8FAFF) : Color(0xFFF8FAFF);
  static Color get brandCardBorder => isFeminineTheme.value ? Color(0xFFE1E7F4) : Color(0xFFE1E7F4);
  static Color get brandShadow => isFeminineTheme.value ? Color(0x141B2F5E) : Color(0x141B2F5E);

  // -- Warm spectrum (for variety beyond a single orange) --
  static Color get orangeWarm => isFeminineTheme.value ? Color(0xFFFFA052) : Color(0xFFFFA052);
  static Color get orangeCoral => isFeminineTheme.value ? Color(0xFFF76A4D) : Color(0xFFF76A4D);
  static Color get orangeCrimson => isFeminineTheme.value ? Color(0xFFC84B1E) : Color(0xFFC84B1E);

  // -- Sky accents (used sparingly to break warm rhythm) --
  static Color get accentSky => isFeminineTheme.value ? Color(0xFF7FB7E8) : Color(0xFF7FB7E8);
  static Color get accentSkyPale => isFeminineTheme.value ? Color(0xFFD6E6F5) : Color(0xFFD6E6F5);
  static Color get accentSkyDeep => isFeminineTheme.value ? Color(0xFF3B7FBF) : Color(0xFF3B7FBF);

  // -- Reusable brand gradients --
  static LinearGradient get gradientWarmCta => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [orangeWarm, orange, orangeCrimson],
    stops: [0.0, 0.55, 1.0],
  );

  static LinearGradient get gradientWarmSoft => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [orangeWarm, paleOrange],
  );

  static LinearGradient get gradientSky => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentSkyPale, accentSky],
  );
}
