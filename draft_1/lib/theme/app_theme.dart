import 'package:flutter/material.dart';

/// Semantic colors for the app, resolved per-theme so screens never hardcode
/// raw color values. Read with `Theme.of(context).extension<AppColors>()!`
/// (or the `context.colors` helper at the bottom of this file).
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

  /// Accent used for the home greeting headline.
  final Color accentText;

  /// Green action color (save buttons, progress, slider).
  final Color positive;

  /// Curved navigation bar foreground color.
  final Color navBar;

  const AppColors({
    required this.background,
    required this.surface,
    required this.onSurface,
    required this.bodyText,
    required this.accentText,
    required this.positive,
    required this.navBar,
  });

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? onSurface,
    Color? bodyText,
    Color? accentText,
    Color? positive,
    Color? navBar,
  }) {
    return AppColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      onSurface: onSurface ?? this.onSurface,
      bodyText: bodyText ?? this.bodyText,
      accentText: accentText ?? this.accentText,
      positive: positive ?? this.positive,
      navBar: navBar ?? this.navBar,
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
    );
  }
}

// ---------------------------------------------------------------------------
// Raw palette
// ---------------------------------------------------------------------------

// The signature navy used throughout the original app.
const Color _navy = Color.fromARGB(255, 0, 37, 68);
const Color _green = Color.fromARGB(255, 0, 208, 90);

// Light theme: an even-lighter near-white blue background (the task asked to
// make the light theme lighter), keeping the navy surfaces and text.
const Color _lightBackground = Color(0xFFEAF7FF);
const Color _lightAccentText = Color.fromARGB(255, 50, 30, 130);

// Dark theme: a deep navy background that preserves the blue identity, with a
// slightly raised navy surface so cards stay legible, and soft light-blue text.
const Color _darkBackground = Color(0xFF0D1B2A);
const Color _darkSurface = Color(0xFF16324F);
const Color _darkBodyText = Color(0xFFE3F2FD);
const Color _darkAccentText = Color(0xFFB39DFF);

const AppColors _lightColors = AppColors(
  background: _lightBackground,
  surface: _navy,
  onSurface: Colors.white,
  bodyText: _navy,
  accentText: _lightAccentText,
  positive: _green,
  navBar: _navy,
);

const AppColors _darkColors = AppColors(
  background: _darkBackground,
  surface: _darkSurface,
  onSurface: Colors.white,
  bodyText: _darkBodyText,
  accentText: _darkAccentText,
  positive: _green,
  navBar: _darkSurface,
);

class AppTheme {
  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: _lightColors.background,
      colorScheme: base.colorScheme.copyWith(
        primary: _navy,
        secondary: _green,
        surface: _lightColors.background,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _navy,
          foregroundColor: Colors.white,
        ),
      ),
      extensions: const [_lightColors],
    );
  }

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: _darkColors.background,
      colorScheme: base.colorScheme.copyWith(
        primary: _darkSurface,
        secondary: _green,
        surface: _darkColors.surface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: _darkSurface,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _darkSurface,
          foregroundColor: Colors.white,
        ),
      ),
      extensions: const [_darkColors],
    );
  }
}

/// Convenience accessor: `context.colors.surface`.
extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
