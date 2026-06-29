import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

// Re-export so existing `import 'theme/app_theme.dart'` keeps giving screens
// access to AppColors and the `context.colors` extension.
export 'app_colors.dart';
export 'app_components.dart';
export 'app_spacing.dart';
export 'app_typography.dart';

/// Builds the app's light and dark [ThemeData] from the central palette,
/// typography and spacing scales.
///
/// Everything that can be themed once — colours, fonts, app bar, cards, inputs,
/// buttons, sliders, switches, progress and dialogs — is configured here so
/// screens stay free of duplicated styling.
abstract final class AppTheme {
  static ThemeData get light => _build(
        brightness: Brightness.light,
        colors: AppColors.light,
        base: ThemeData.light(useMaterial3: true),
      );

  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        colors: AppColors.dark,
        base: ThemeData.dark(useMaterial3: true),
      );

  static ThemeData _build({
    required Brightness brightness,
    required AppColors colors,
    required ThemeData base,
  }) {
    // A full ColorScheme derived from the same palette as AppColors, so the
    // Material widgets (buttons, dialogs, etc.) are coloured from one source.
    final colorScheme = base.colorScheme.copyWith(
      brightness: brightness,
      primary: colors.surface,
      onPrimary: colors.onSurface,
      secondary: colors.positive,
      onSecondary: Colors.white,
      surface: colors.background,
      onSurface: colors.bodyText,
      surfaceContainerHighest: colors.surface,
      onSurfaceVariant: colors.onSurface,
    );

    final textTheme = AppTypography.textTheme(colors.bodyText);

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.background,
      textTheme: textTheme,

      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.headlineMedium?.copyWith(
          color: colors.onSurface,
        ),
      ),

      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        margin: EdgeInsets.zero,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.surface,
          foregroundColor: colors.onSurface,
          textStyle: textTheme.labelLarge,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.surface,
          textStyle: textTheme.labelLarge,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        labelStyle: TextStyle(color: colors.onSurface),
        hintStyle: TextStyle(color: colors.onSurface),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),

      sliderTheme: base.sliderTheme.copyWith(
        activeTrackColor: colors.positive,
        inactiveTrackColor: colors.onSurface,
        thumbColor: colors.positive,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colors.positive
              : null,
        ),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.positive,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: colors.background,
        titleTextStyle: textTheme.titleMedium,
        contentTextStyle: textTheme.bodyLarge,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),

      extensions: [colors],
    );
  }
}
