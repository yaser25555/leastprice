import 'package:flutter/material.dart';

final ValueNotifier<bool> isFeminineTheme = ValueNotifier<bool>(false);

class AppPalette {
  const AppPalette._();

  static Color get navy => isFeminineTheme.value ? const Color(0xFF005A9C) : const Color(0xFF1B2F5E);
  static Color get deepNavy => isFeminineTheme.value ? const Color(0xFF003F7A) : const Color(0xFF12284D);
  static Color get softNavy => isFeminineTheme.value ? const Color(0xFF3388CC) : const Color(0xFF2C4C84);
  static Color get lightNavy => isFeminineTheme.value ? const Color(0xFF7FB7E8) : const Color(0xFF3B639E);
  static Color get orange => isFeminineTheme.value ? const Color(0xFFE91E63) : const Color(0xFFE8711A);
  static Color get paleOrange => isFeminineTheme.value ? const Color(0xFFF48FB1) : const Color(0xFFFFB978);
  static Color get softOrange => isFeminineTheme.value ? const Color(0xFFF06292) : const Color(0xFF213C6E);
  static Color get turquoise => isFeminineTheme.value ? const Color(0xFF007FFF) : const Color(0xFF35C9C4);
  static Color get softTurquoise => isFeminineTheme.value ? const Color(0xFF3399FF) : const Color(0xFF7DE7E2);
  static Color get comparisonEmerald => isFeminineTheme.value ? const Color(0xFFE91E63) : const Color(0xFFE8711A);
  static Color get comparisonSoftEmerald => isFeminineTheme.value ? const Color(0xFF005A9C) : const Color(0xFF2B4A80);
  static Color get comparisonBorder => isFeminineTheme.value ? const Color(0xFFF48FB1) : const Color(0xFFF3A866);
  static Color get dealsRed => isFeminineTheme.value ? const Color(0xFFE91E63) : const Color(0xFFE8711A);
  static Color get dealsSoftRed => isFeminineTheme.value ? const Color(0xFF005A9C) : const Color(0xFF2A4A82);
  static Color get dealsBorder => isFeminineTheme.value ? const Color(0xFFF48FB1) : const Color(0xFFF2A776);
  static Color get shellBackground => isFeminineTheme.value ? const Color(0xFFFCE4EC) : const Color(0xFF162B52);
  static Color get cardBackground => isFeminineTheme.value ? const Color(0xFFFCE4EC) : const Color(0xFF162B52);
  static Color get cardBorder => Colors.transparent;
  static Color get panelText => isFeminineTheme.value ? const Color(0xFF003F7A) : const Color(0xFF8BEDEA);
  static Color get mutedText => isFeminineTheme.value ? const Color(0xFF3388CC) : const Color(0xFF63D6D2);
  static Color get shadow => isFeminineTheme.value ? const Color(0x1A003F7A) : const Color(0x141B2F5E);
  static Color get pureWhite => isFeminineTheme.value ? const Color(0xFFFFFFFF) : Colors.white;
  static Color pureWhiteOpacity(double opacity) => isFeminineTheme.value 
      ? const Color(0xFFFFFFFF).withOpacity(opacity) 
      : Colors.white.withOpacity(opacity);

  // -- Premium 3D Neumorphic Shadows --
  static List<BoxShadow> get premium3DBoxShadow => isFeminineTheme.value 
      ? [
          const BoxShadow(color: Color(0xFFF48FB1), blurRadius: 15, offset: Offset(6, 6)),
          const BoxShadow(color: Color(0xFFFFFFFF), blurRadius: 15, offset: Offset(-6, -6)),
        ]
      : [
          const BoxShadow(color: Color(0xFF0F1E3A), blurRadius: 15, offset: Offset(6, 6)),
          const BoxShadow(color: Color(0xFF1D386A), blurRadius: 15, offset: Offset(-6, -6)),
        ];

  // -- Brand-aligned tokens (per BRAND_GUIDELINES.md / UI_DESIGN_GUIDELINES.md) --
  static Color get brandNavy => isFeminineTheme.value ? const Color(0xFF005A9C) : const Color(0xFF1B2F5E);
  static Color get brandNavyDeep => isFeminineTheme.value ? const Color(0xFF003F7A) : const Color(0xFF12284D);
  static Color get brandNavySecondary => isFeminineTheme.value ? const Color(0xFF3388CC) : const Color(0xFF6B7A9A);
  static Color get brandOrange => isFeminineTheme.value ? const Color(0xFFE91E63) : const Color(0xFFE8711A);
  static Color get brandOrangePale => isFeminineTheme.value ? const Color(0xFFF48FB1) : const Color(0xFFFFD9BA);
  static Color get brandOrangeBackground => isFeminineTheme.value ? const Color(0xFFFCE4EC) : const Color(0xFFFFF3E8);
  static Color get brandSurface => isFeminineTheme.value ? const Color(0xFFFCE4EC) : const Color(0xFFF5F7FF);
  static Color get brandCard => isFeminineTheme.value ? const Color(0xFF005A9C) : const Color(0xFFFFFFFF);
  static Color get brandCardSoft => isFeminineTheme.value ? const Color(0xFFFCE4EC) : const Color(0xFFF8FAFF);
  static Color get brandCardBorder => isFeminineTheme.value ? const Color(0xFF003F7A) : const Color(0xFFE1E7F4);
  static Color get brandShadow => isFeminineTheme.value ? const Color(0x26003F7A) : const Color(0x141B2F5E);

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
