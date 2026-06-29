import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized typography for the app.
///
/// Every text style in the app is built from Nunito and mapped onto Material's
/// [TextTheme] slots, so screens use semantic roles
/// (`Theme.of(context).textTheme.titleMedium`) instead of repeating
/// `GoogleFonts.nunito(fontSize: …, fontWeight: …)` everywhere.
///
/// Role guide (sizes/weights chosen to match the app's existing look):
///  * headlineMedium — app-bar titles, big stat values, prompt headlines (24 / bold)
///  * headlineSmall  — section + month titles (20 / bold)
///  * titleLarge     — large plain numerals such as calendar days (20 / regular)
///  * titleMedium    — card headings, list item titles (18 / bold)
///  * bodyLarge      — primary body text and list rows (16 / regular)
///  * bodyMedium     — secondary labels (14 / regular)
///  * bodySmall      — captions and chart sub-labels (13 / regular)
///  * labelLarge     — button labels (18 / bold)
///  * labelSmall     — tiny chart value labels (11 / semibold)
abstract final class AppTypography {
  /// Builds the app's [TextTheme] with all text rendered in [color].
  ///
  /// Text shown on the navy card [AppColors.surface] should override the colour
  /// with `.copyWith(color: context.colors.onSurface)`; everything else inherits
  /// this on-background colour.
  static TextTheme textTheme(Color color) {
    final base = GoogleFonts.nunitoTextTheme();
    return base
        .apply(bodyColor: color, displayColor: color)
        .copyWith(
          headlineMedium: GoogleFonts.nunito(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          headlineSmall: GoogleFonts.nunito(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          titleLarge: GoogleFonts.nunito(
            fontSize: 20,
            fontWeight: FontWeight.w400,
            color: color,
          ),
          titleMedium: GoogleFonts.nunito(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          bodyLarge: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: color,
          ),
          bodyMedium: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: color,
          ),
          bodySmall: GoogleFonts.nunito(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: color,
          ),
          labelLarge: GoogleFonts.nunito(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          labelSmall: GoogleFonts.nunito(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        );
  }
}

/// Shorthand for `Theme.of(context).textTheme`, e.g. `context.text.titleMedium`.
extension AppTextX on BuildContext {
  TextTheme get text => Theme.of(this).textTheme;
}
