import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Raw palette — the single source of truth for every colour in the app.
//
// Nothing outside this file should construct a raw `Color`. Screens read
// semantic colours from [AppColors] (via `context.colors`) or from the
// Material [ColorScheme] (via `Theme.of(context).colorScheme`); both are
// derived from these constants in app_theme.dart.
// ---------------------------------------------------------------------------

/// The signature navy used for cards, app bars and the nav bar.
const Color kNavy = Color.fromARGB(255, 0, 37, 68);

/// Green action / success accent (save buttons, progress, sliders, charts).
const Color kGreen = Color.fromARGB(255, 0, 208, 90);

/// Light theme: a near-white blue page background behind the navy surfaces.
const Color kLightBackground = Color(0xFFEAF7FF);
const Color kLightAccentText = Color.fromARGB(255, 50, 30, 130);

/// Dark theme: a deep navy page background with a slightly raised navy
/// surface for cards and soft light-blue text.
const Color kDarkBackground = Color(0xFF0D1B2A);
const Color kDarkSurface = Color(0xFF16324F);
const Color kDarkBodyText = Color(0xFFE3F2FD);
const Color kDarkAccentText = Color(0xFFB39DFF);

/// Neutral grey used for secondary chat bubbles / hint text.
const Color kNeutralGrey = Color.fromARGB(255, 93, 93, 93);

// ---------------------------------------------------------------------------
// Semantic colours
// ---------------------------------------------------------------------------

/// App-specific semantic colours that don't map cleanly onto the Material
/// [ColorScheme] roles, resolved per-theme so screens never hardcode raw
/// colour values. Read with `context.colors` (see the extension below).
@immutable
class AppColors extends ThemeExtension<AppColors> {
  /// Page / scaffold background.
  final Color background;

  /// Navy "card" surface used for cards, app bars, the nav bar and inputs.
  final Color surface;

  /// Text / icons that sit on top of [surface].
  final Color onSurface;

  /// Primary body text shown directly on [background].
  final Color bodyText;

  /// Accent used for greeting / prompt headlines.
  final Color accentText;

  /// Green action colour (save buttons, progress, slider, charts).
  final Color positive;

  /// Curved navigation bar foreground colour.
  final Color navBar;

  /// Neutral grey for de-emphasised bubbles and hint text.
  final Color neutral;

  const AppColors({
    required this.background,
    required this.surface,
    required this.onSurface,
    required this.bodyText,
    required this.accentText,
    required this.positive,
    required this.navBar,
    required this.neutral,
  });

  /// Light theme semantic colours.
  static const AppColors light = AppColors(
    background: kLightBackground,
    surface: kNavy,
    onSurface: Colors.white,
    bodyText: kNavy,
    accentText: kLightAccentText,
    positive: kGreen,
    navBar: kNavy,
    neutral: kNeutralGrey,
  );

  /// Dark theme semantic colours.
  static const AppColors dark = AppColors(
    background: kDarkBackground,
    surface: kDarkSurface,
    onSurface: Colors.white,
    bodyText: kDarkBodyText,
    accentText: kDarkAccentText,
    positive: kGreen,
    navBar: kDarkSurface,
    neutral: kNeutralGrey,
  );

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? onSurface,
    Color? bodyText,
    Color? accentText,
    Color? positive,
    Color? navBar,
    Color? neutral,
  }) {
    return AppColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      onSurface: onSurface ?? this.onSurface,
      bodyText: bodyText ?? this.bodyText,
      accentText: accentText ?? this.accentText,
      positive: positive ?? this.positive,
      navBar: navBar ?? this.navBar,
      neutral: neutral ?? this.neutral,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      onSurface: Color.lerp(onSurface, other.onSurface, t)!,
      bodyText: Color.lerp(bodyText, other.bodyText, t)!,
      accentText: Color.lerp(accentText, other.accentText, t)!,
      positive: Color.lerp(positive, other.positive, t)!,
      navBar: Color.lerp(navBar, other.navBar, t)!,
      neutral: Color.lerp(neutral, other.neutral, t)!,
    );
  }
}

/// Convenience accessor: `context.colors.surface`.
extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
