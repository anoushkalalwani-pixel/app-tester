import 'dart:async';

import 'package:flutter/material.dart';

import 'package:draft_1/pomodoro/pomodoro_controller.dart';
import 'package:draft_1/theme/app_theme.dart';

/// Pomodoro focus timer screen.
///
/// Shows the current interval as a progress ring with a `mm:ss` countdown,
/// offers start / pause / resume / reset (and skip) controls, lets the user
/// tune the durations, and pops an in-app notification when a focus or break
/// interval ends. Rebuilds from [PomodoroController] (a [ChangeNotifier]) and
/// listens to its event stream for the end-of-interval cue.
class UserPomodoro extends StatefulWidget {
  const UserPomodoro({super.key});

  @override
  State<UserPomodoro> createState() => _UserPomodoroState();
}

class _UserPomodoroState extends State<UserPomodoro> {
  final PomodoroController _controller = PomodoroController.instance;
  StreamSubscription<PomodoroEvent>? _eventsSub;

  @override
  void initState() {
    super.initState();
    _eventsSub = _controller.events.listen(_onPhaseEnded);
  }

  @override
  void dispose() {
    _eventsSub?.cancel();
    super.dispose();
  }

  /// Shows a snackbar when an interval ends. Sound/haptics are fired by the
  /// controller itself, so the cue still reaches the user on other screens.
  void _onPhaseEnded(PomodoroEvent event) {
    if (!mounted) return;
    final message = event.completed.isBreak
        ? 'Break over — time to focus.'
        : '${event.next.label} time! Take a breather.';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Focus timer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Timer settings',
            onPressed: _openSettings,
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _PhaseChip(phase: _controller.phase),
                const VGap(AppSpacing.xxl),
                _TimerRing(controller: _controller),
                const VGap(AppSpacing.lg),
                Text(
                  'Focus sessions completed: ${_controller.completedSessions}',
                  style:
                      context.text.bodyLarge?.copyWith(color: colors.bodyText),
                ),
                const VGap(AppSpacing.xxl),
                _Controls(controller: _controller),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _openSettings() async {
    final updated = await showDialog<PomodoroSettings>(
      context: context,
      builder: (_) => _SettingsDialog(initial: _controller.settings),
    );
    if (updated != null) {
      await _controller.updateSettings(updated);
    }
  }
}

/// A pill showing the current interval (Focus / Short break / Long break).
class _PhaseChip extends StatelessWidget {
  final PomodoroPhase phase;
  const _PhaseChip({required this.phase});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = phase.isBreak ? colors.positive : colors.surface;
    // Smoothly recolour the pill (and cross-fade the label) when the interval
    // changes between focus and break.
    return AnimatedContainer(
      duration: AppDurations.medium,
      curve: AppCurves.standard,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: AnimatedSwitcher(
        duration: AppDurations.fast,
        child: Text(
          phase.label,
          key: ValueKey(phase.label),
          style: context.text.titleMedium?.copyWith(color: colors.onSurface),
        ),
      ),
    );
  }
}

/// The circular progress ring with the `mm:ss` countdown in the centre.
class _TimerRing extends StatelessWidget {
  final PomodoroController controller;
  const _TimerRing({required this.controller});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      width: 240,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: controller.progress,
              strokeWidth: 12,
              backgroundColor: colors.surface.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(colors.positive),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                controller.remainingLabel,
                style: context.text.headlineMedium?.copyWith(
                  color: colors.bodyText,
                  fontSize: 56,
                ),
              ),
              Text(
                controller.isPaused ? 'Paused' : controller.phase.label,
                style: context.text.bodyLarge?.copyWith(color: colors.bodyText),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Start / pause / resume plus reset and skip, shown according to state.
class _Controls extends StatelessWidget {
  final PomodoroController controller;
  const _Controls({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (controller.isIdle)
              ElevatedButton.icon(
                style: AppButtons.positive(context),
                onPressed: () {
                  AppHaptics.light();
                  controller.start();
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start'),
              )
            else if (controller.isRunning)
              ElevatedButton.icon(
                style: AppButtons.positive(context),
                onPressed: () {
                  AppHaptics.light();
                  controller.pause();
                },
                icon: const Icon(Icons.pause),
                label: const Text('Pause'),
              )
            else
              ElevatedButton.icon(
                style: AppButtons.positive(context),
                onPressed: () {
                  AppHaptics.light();
                  controller.resume();
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Resume'),
              ),
          ],
        ),
        const VGap(AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              onPressed: controller.isIdle
                  ? null
                  : () {
                      AppHaptics.selection();
                      controller.skip();
                    },
              icon: const Icon(Icons.skip_next),
              label: const Text('Skip'),
            ),
            const HGap(AppSpacing.lg),
            TextButton.icon(
              onPressed: controller.isIdle
                  ? null
                  : () {
                      AppHaptics.selection();
                      controller.reset();
                    },
              icon: const Icon(Icons.restart_alt),
              label: const Text('Reset'),
            ),
          ],
        ),
      ],
    );
  }
}

/// Dialog with steppers for the four configurable durations. Returns the new
/// [PomodoroSettings] when saved, or null when cancelled.
class _SettingsDialog extends StatefulWidget {
  final PomodoroSettings initial;
  const _SettingsDialog({required this.initial});

  @override
  State<_SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<_SettingsDialog> {
  late int _work = widget.initial.workMinutes;
  late int _shortBreak = widget.initial.shortBreakMinutes;
  late int _longBreak = widget.initial.longBreakMinutes;
  late int _sessions = widget.initial.sessionsBeforeLongBreak;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Timer settings'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Stepper(
              label: 'Focus',
              suffix: 'min',
              value: _work,
              min: 1,
              max: 120,
              onChanged: (v) => setState(() => _work = v),
            ),
            _Stepper(
              label: 'Short break',
              suffix: 'min',
              value: _shortBreak,
              min: 1,
              max: 60,
              onChanged: (v) => setState(() => _shortBreak = v),
            ),
            _Stepper(
              label: 'Long break',
              suffix: 'min',
              value: _longBreak,
              min: 1,
              max: 60,
              onChanged: (v) => setState(() => _longBreak = v),
            ),
            _Stepper(
              label: 'Sessions / long break',
              value: _sessions,
              min: 1,
              max: 12,
              onChanged: (v) => setState(() => _sessions = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(
            PomodoroSettings(
              workMinutes: _work,
              shortBreakMinutes: _shortBreak,
              longBreakMinutes: _longBreak,
              sessionsBeforeLongBreak: _sessions,
            ),
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

/// A label with `-`/`+` buttons and the current value, used in the settings
/// dialog. Bounds the value to [min] – [max].
class _Stepper extends StatelessWidget {
  final String label;
  final String? suffix;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _Stepper({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: context.text.bodyLarge?.copyWith(color: colors.bodyText),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: value > min ? () => onChanged(value - 1) : null,
          ),
          SizedBox(
            width: 56,
            child: Text(
              suffix == null ? '$value' : '$value $suffix',
              textAlign: TextAlign.center,
              style: context.text.titleMedium?.copyWith(color: colors.bodyText),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: value < max ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}
