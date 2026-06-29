import 'package:flutter/widgets.dart';

/// Centralized spacing scale for the whole app.
///
/// Use these constants instead of sprinkling magic numbers through layouts so
/// padding, margins and gaps stay consistent across every screen.
abstract final class AppSpacing {
  /// 4dp — hairline gaps (e.g. between an icon and its dot).
  static const double xs = 4;

  /// 8dp — tight gaps between closely related elements.
  static const double sm = 8;

  /// 12dp — default gap between grouped controls.
  static const double md = 12;

  /// 16dp — standard screen / card padding.
  static const double lg = 16;

  /// 20dp — generous padding inside emphasised cards.
  static const double xl = 20;

  /// 24dp — separation between major sections.
  static const double xxl = 24;
}

/// Centralized corner-radius scale.
abstract final class AppRadius {
  /// 8dp — small chips / nested containers.
  static const double sm = 8;

  /// 12dp — inputs and standard controls.
  static const double md = 12;

  /// 16dp — cards and surfaces.
  static const double lg = 16;

  /// 30dp — fully rounded "pill" shapes (e.g. the chat composer).
  static const double pill = 30;
}

/// Convenience vertical/horizontal gap widgets so screens can write
/// `const VGap(AppSpacing.lg)` instead of `SizedBox(height: 16)`.
class VGap extends StatelessWidget {
  final double size;
  const VGap(this.size, {super.key});

  @override
  Widget build(BuildContext context) => SizedBox(height: size);
}

class HGap extends StatelessWidget {
  final double size;
  const HGap(this.size, {super.key});

  @override
  Widget build(BuildContext context) => SizedBox(width: size);
}
