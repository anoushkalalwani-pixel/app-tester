import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

/// Reusable visual building blocks layered on top of the theme.
///
/// These centralize the card / button / input recipes that were previously
/// copied across screens, so every screen renders them identically.

/// A rounded navy "surface" card — the app's signature container, used for
/// stat cards, chart panels, list items and form step boxes.
///
/// Defaults match the most common usage; override [padding] / [radius] for the
/// occasional variant.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double? width;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.radius = AppRadius.lg,
    this.width,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);
    final card = Container(
      width: width,
      padding: padding,
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: borderRadius,
      ),
      child: child,
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: onTap,
        child: card,
      ),
    );
  }
}

/// Shared input decorations so every text field looks the same.
abstract final class AppInputs {
  /// A filled, rounded field on the navy [AppColors.surface] (profile form).
  static InputDecoration filled(
    BuildContext context, {
    String? label,
    Widget? suffixIcon,
  }) {
    final colors = context.colors;
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: colors.onSurface),
      filled: true,
      fillColor: colors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      suffixIcon: suffixIcon,
    );
  }

  /// A borderless field used inside an [AppCard] (the add-test wizard steps),
  /// where the surrounding card already provides the navy background.
  static InputDecoration onCard(
    BuildContext context, {
    String? hint,
  }) {
    return InputDecoration(
      hintText: hint,
      filled: false,
      border: InputBorder.none,
      hintStyle: TextStyle(color: context.colors.onSurface),
    );
  }
}

/// Shared button styles beyond the theme defaults.
abstract final class AppButtons {
  /// Green "positive" action button (e.g. Save), with comfortable padding.
  static ButtonStyle positive(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: context.colors.positive,
      foregroundColor: context.colors.onSurface,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl,
        vertical: AppSpacing.md,
      ),
    );
  }
}
