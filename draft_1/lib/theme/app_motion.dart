import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

// ---------------------------------------------------------------------------
// Motion primitives + reusable interaction widgets.
//
// One place for the app's animation timings, curves and the small building
// blocks (press feedback, staggered entrances, skeleton loaders, empty states,
// page routes, snackbars, haptics) so every screen feels consistent rather
// than each re-inventing its own durations and effects.
//
// Re-exported from app_theme.dart, so screens that already
// `import 'theme/app_theme.dart'` get all of this for free.
// ---------------------------------------------------------------------------

/// Shared animation durations. Kept short so the UI feels responsive, never
/// sluggish.
abstract final class AppDurations {
  /// 150ms — taps, ripples and other immediate feedback.
  static const Duration fast = Duration(milliseconds: 150);

  /// 250ms — most transitions (page swaps, switchers, card entrances).
  static const Duration medium = Duration(milliseconds: 250);

  /// 400ms — larger reveals (theme switch, chart draw-in).
  static const Duration slow = Duration(milliseconds: 400);
}

/// Shared easing curves. [standard] is the workhorse decelerate curve used for
/// almost everything; [emphasized] adds a touch more character for hero moments.
abstract final class AppCurves {
  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeOutBack;
}

// ---------------------------------------------------------------------------
// Haptics
// ---------------------------------------------------------------------------

/// Best-effort haptic feedback. Swallows the unsupported-platform case (web,
/// desktop, tests) so callers can sprinkle haptics freely without guards.
abstract final class AppHaptics {
  /// A light tick for taps on cards, list items and nav destinations.
  static void selection() => _run(HapticFeedback.selectionClick);

  /// A slightly firmer tap for primary actions (Save, Generate, Start).
  static void light() => _run(HapticFeedback.lightImpact);

  /// A confirming bump for completed / committed actions.
  static void medium() => _run(HapticFeedback.mediumImpact);

  static void _run(Future<void> Function() fn) {
    try {
      fn().ignore();
    } catch (_) {
      // No haptics engine available — ignore.
    }
  }
}

// ---------------------------------------------------------------------------
// Press feedback
// ---------------------------------------------------------------------------

/// Adds a subtle "press in" scale to its [child] while a finger is down.
///
/// Implemented with a [Listener] (which only observes pointer events and never
/// joins the gesture arena), so it composes cleanly on top of an inner
/// [InkWell] / button without stealing its taps or ripple.
class PressableScale extends StatefulWidget {
  final Widget child;

  /// Scale applied while pressed. Defaults to a gentle 2% squeeze.
  final double pressedScale;

  const PressableScale({
    super.key,
    required this.child,
    this.pressedScale = 0.97,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _set(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1.0,
        duration: AppDurations.fast,
        curve: AppCurves.standard,
        child: widget.child,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Entrance animation
// ---------------------------------------------------------------------------

/// Fades and lifts its [child] into place once, the first time it is built.
///
/// Pass an increasing [delay] (e.g. `index * 60ms`) to stagger a list so items
/// cascade in instead of popping all at once.
class EntranceFade extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;

  /// Vertical distance (in logical pixels) the child travels up as it fades in.
  final double offset;

  const EntranceFade({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = AppDurations.medium,
    this.offset = 14,
  });

  /// Convenience for staggering the [index]-th item of a list.
  factory EntranceFade.staggered({
    Key? key,
    required int index,
    required Widget child,
    Duration step = const Duration(milliseconds: 55),
    Duration maxDelay = const Duration(milliseconds: 400),
  }) {
    final ms = (index * step.inMilliseconds).clamp(0, maxDelay.inMilliseconds);
    return EntranceFade(
      key: key,
      delay: Duration(milliseconds: ms),
      child: child,
    );
  }

  @override
  State<EntranceFade> createState() => _EntranceFadeState();
}

class _EntranceFadeState extends State<EntranceFade>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  late final Animation<double> _curved =
      _controller.drive(CurveTween(curve: AppCurves.standard));

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curved,
      child: AnimatedBuilder(
        animation: _curved,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, widget.offset * (1 - _curved.value)),
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Skeleton loading
// ---------------------------------------------------------------------------

/// A shimmering placeholder block shown while real content loads.
///
/// Several [Skeleton]s share the look of the surface they sit on; combine a few
/// to sketch the shape of the screen that is about to appear.
class Skeleton extends StatefulWidget {
  final double? width;
  final double height;
  final double radius;

  const Skeleton({
    super.key,
    this.width,
    this.height = 16,
    this.radius = AppRadius.sm,
  });

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = context.colors.onSurface.withValues(alpha: 0.10);
    final highlight = context.colors.onSurface.withValues(alpha: 0.22);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [base, highlight, base],
              stops: const [0.1, 0.5, 0.9],
              // Sweep the highlight across the block left-to-right.
              transform: _SlideGradient(_controller.value),
            ),
          ),
        );
      },
    );
  }
}

/// Slides a [LinearGradient] horizontally for the shimmer sweep.
class _SlideGradient extends GradientTransform {
  final double t;
  const _SlideGradient(this.t);

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    final dx = bounds.width * (2 * t - 1);
    return Matrix4.translationValues(dx, 0, 0);
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

/// A friendly, centred empty-state: a soft icon, a title and a short message,
/// with an optional call-to-action. Animates in gently so an empty screen never
/// feels broken.
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: EntranceFade(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: colors.positive.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 40, color: colors.positive),
              ),
              const VGap(AppSpacing.lg),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: colors.bodyText),
              ),
              if (message != null) ...[
                const VGap(AppSpacing.sm),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.bodyText.withValues(alpha: 0.7),
                      ),
                ),
              ],
              if (action != null) ...[
                const VGap(AppSpacing.xl),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Page transitions
// ---------------------------------------------------------------------------

/// A modern fade-through page transition: the incoming page fades up while the
/// outgoing one fades away. Applied to every platform via the app theme so all
/// `Navigator.push`es share one tasteful motion.
class FadeThroughPageTransitionsBuilder extends PageTransitionsBuilder {
  const FadeThroughPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final fade = animation.drive(CurveTween(curve: AppCurves.standard));
    final slide = animation.drive(
      Tween(begin: const Offset(0, 0.025), end: Offset.zero)
          .chain(CurveTween(curve: AppCurves.standard)),
    );
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(position: slide, child: child),
    );
  }
}

// ---------------------------------------------------------------------------
// Snackbars
// ---------------------------------------------------------------------------

/// Shows a themed snackbar with a leading icon. Replaces any visible snackbar so
/// rapid messages don't stack up.
void showAppSnackBar(
  BuildContext context,
  String message, {
  IconData icon = Icons.info_outline,
}) {
  final colors = context.colors;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: colors.onSurface, size: 20),
            const HGap(AppSpacing.md),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
}
