import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The three kinds of interval in a Pomodoro cycle.
enum PomodoroPhase { work, shortBreak, longBreak }

/// Whether the timer is stopped, counting down, or temporarily held.
enum PomodoroStatus { idle, running, paused }

extension PomodoroPhaseLabel on PomodoroPhase {
  /// Human-readable label shown on the timer screen.
  String get label {
    switch (this) {
      case PomodoroPhase.work:
        return 'Focus';
      case PomodoroPhase.shortBreak:
        return 'Short break';
      case PomodoroPhase.longBreak:
        return 'Long break';
    }
  }

  /// Whether this phase is a rest interval (as opposed to focused work).
  bool get isBreak => this != PomodoroPhase.work;
}

/// User-configurable durations for a Pomodoro cycle. All durations are whole
/// minutes; [sessionsBeforeLongBreak] is how many focus sessions happen before
/// a long break replaces a short one.
@immutable
class PomodoroSettings {
  final int workMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;
  final int sessionsBeforeLongBreak;

  const PomodoroSettings({
    this.workMinutes = 25,
    this.shortBreakMinutes = 5,
    this.longBreakMinutes = 15,
    this.sessionsBeforeLongBreak = 4,
  });

  /// Returns a copy with the given fields replaced and every value clamped to a
  /// sane range, so a malformed stored value or an extreme slider can never
  /// produce a zero-length or absurd interval.
  PomodoroSettings copyWith({
    int? workMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
    int? sessionsBeforeLongBreak,
  }) {
    return PomodoroSettings(
      workMinutes: (workMinutes ?? this.workMinutes).clamp(1, 120),
      shortBreakMinutes: (shortBreakMinutes ?? this.shortBreakMinutes).clamp(1, 60),
      longBreakMinutes: (longBreakMinutes ?? this.longBreakMinutes).clamp(1, 60),
      sessionsBeforeLongBreak:
          (sessionsBeforeLongBreak ?? this.sessionsBeforeLongBreak).clamp(1, 12),
    );
  }

  /// Duration, in seconds, of a given [phase] under these settings.
  int secondsFor(PomodoroPhase phase) {
    switch (phase) {
      case PomodoroPhase.work:
        return workMinutes * 60;
      case PomodoroPhase.shortBreak:
        return shortBreakMinutes * 60;
      case PomodoroPhase.longBreak:
        return longBreakMinutes * 60;
    }
  }
}

/// Emitted whenever one interval finishes and the timer rolls into the next, so
/// the UI can surface a notification ("break's over, back to work").
@immutable
class PomodoroEvent {
  /// The phase that just ended.
  final PomodoroPhase completed;

  /// The phase the timer has rolled into.
  final PomodoroPhase next;

  const PomodoroEvent({required this.completed, required this.next});
}

/// Drives a configurable Pomodoro timer that cycles focus sessions with short
/// and long breaks.
///
/// A single global [instance] is shared by the app so the countdown keeps
/// running while the user moves between screens. The controller is a
/// [ChangeNotifier]: the UI rebuilds from [phase], [status], [remaining] and
/// [completedSessions], and separately listens to [events] to show a
/// notification (sound + haptics are fired here so they happen on any screen).
class PomodoroController extends ChangeNotifier {
  PomodoroController._();
  static final PomodoroController instance = PomodoroController._();

  static const _kWork = 'pomodoro.workMinutes';
  static const _kShortBreak = 'pomodoro.shortBreakMinutes';
  static const _kLongBreak = 'pomodoro.longBreakMinutes';
  static const _kSessions = 'pomodoro.sessionsBeforeLongBreak';

  PomodoroSettings _settings = const PomodoroSettings();
  PomodoroSettings get settings => _settings;

  PomodoroPhase _phase = PomodoroPhase.work;
  PomodoroPhase get phase => _phase;

  PomodoroStatus _status = PomodoroStatus.idle;
  PomodoroStatus get status => _status;

  /// Seconds left in the current phase.
  late int _remaining = _settings.secondsFor(_phase);
  int get remaining => _remaining;

  /// Number of focus sessions completed in the current cycle.
  int _completedSessions = 0;
  int get completedSessions => _completedSessions;

  Timer? _ticker;
  final StreamController<PomodoroEvent> _events =
      StreamController<PomodoroEvent>.broadcast();

  /// Fires each time a phase ends and the timer advances to the next one.
  Stream<PomodoroEvent> get events => _events.stream;

  /// Set to false in tests so [start]/[resume] don't spin up a real periodic
  /// timer; tests drive the countdown deterministically with [tick].
  @visibleForTesting
  bool autoTick = true;

  bool get isRunning => _status == PomodoroStatus.running;
  bool get isPaused => _status == PomodoroStatus.paused;
  bool get isIdle => _status == PomodoroStatus.idle;

  /// Total seconds in the current phase, used to draw the progress ring.
  int get phaseLengthSeconds => _settings.secondsFor(_phase);

  /// Fraction of the current phase elapsed, in 0.0 – 1.0.
  double get progress {
    final total = phaseLengthSeconds;
    if (total <= 0) return 0;
    return (1 - _remaining / total).clamp(0.0, 1.0);
  }

  /// `mm:ss` countdown for the current phase.
  String get remainingLabel {
    final minutes = _remaining ~/ 60;
    final seconds = _remaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  /// Loads the persisted settings. Call once before `runApp`.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _settings = PomodoroSettings(
      workMinutes: prefs.getInt(_kWork) ?? 25,
      shortBreakMinutes: prefs.getInt(_kShortBreak) ?? 5,
      longBreakMinutes: prefs.getInt(_kLongBreak) ?? 15,
      sessionsBeforeLongBreak: prefs.getInt(_kSessions) ?? 4,
    ).copyWith();
    if (_status == PomodoroStatus.idle) {
      _remaining = _settings.secondsFor(_phase);
    }
    notifyListeners();
  }

  /// Begins the countdown from an idle (reset) state.
  void start() {
    if (_status == PomodoroStatus.running) return;
    _status = PomodoroStatus.running;
    _startTicker();
    notifyListeners();
  }

  /// Holds the countdown where it is; resumable with [resume].
  void pause() {
    if (_status != PomodoroStatus.running) return;
    _status = PomodoroStatus.paused;
    _ticker?.cancel();
    notifyListeners();
  }

  /// Continues a paused countdown.
  void resume() {
    if (_status != PomodoroStatus.paused) return;
    _status = PomodoroStatus.running;
    _startTicker();
    notifyListeners();
  }

  /// Stops the timer and returns to a fresh focus session at the start of a new
  /// cycle.
  void reset() {
    _ticker?.cancel();
    _status = PomodoroStatus.idle;
    _phase = PomodoroPhase.work;
    _completedSessions = 0;
    _remaining = _settings.secondsFor(_phase);
    notifyListeners();
  }

  /// Ends the current phase immediately and advances to the next one, exactly
  /// as if it had counted down to zero (including the end-of-phase
  /// notification).
  void skip() {
    if (_status == PomodoroStatus.idle) return;
    _advancePhase();
  }

  /// Applies new [settings], persists them, and — when idle — refreshes the
  /// countdown so the change is visible immediately. Durations of a phase
  /// already in progress are left alone until the next time that phase starts.
  Future<void> updateSettings(PomodoroSettings settings) async {
    _settings = settings.copyWith();
    if (_status == PomodoroStatus.idle) {
      _remaining = _settings.secondsFor(_phase);
    }
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kWork, _settings.workMinutes);
    await prefs.setInt(_kShortBreak, _settings.shortBreakMinutes);
    await prefs.setInt(_kLongBreak, _settings.longBreakMinutes);
    await prefs.setInt(_kSessions, _settings.sessionsBeforeLongBreak);
  }

  /// Advances the countdown by one second. Invoked by the internal periodic
  /// timer; exposed for deterministic testing.
  @visibleForTesting
  void tick() {
    if (_status != PomodoroStatus.running) return;
    if (_remaining > 1) {
      _remaining--;
      notifyListeners();
      return;
    }
    _advancePhase();
  }

  void _startTicker() {
    _ticker?.cancel();
    if (!autoTick) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  /// Rolls from the current phase into the next, resets the countdown for it,
  /// and notifies the user that the interval ended.
  void _advancePhase() {
    final completed = _phase;
    if (completed == PomodoroPhase.work) {
      _completedSessions++;
    }
    final next = _nextPhase(completed);
    _phase = next;
    _remaining = _settings.secondsFor(next);
    notifyListeners();
    _notify(PomodoroEvent(completed: completed, next: next));
  }

  /// A finished focus session leads to a long break every
  /// [PomodoroSettings.sessionsBeforeLongBreak] sessions, otherwise a short
  /// one; any break leads back to focus.
  PomodoroPhase _nextPhase(PomodoroPhase completed) {
    if (completed != PomodoroPhase.work) return PomodoroPhase.work;
    final everyN = _settings.sessionsBeforeLongBreak;
    return _completedSessions % everyN == 0
        ? PomodoroPhase.longBreak
        : PomodoroPhase.shortBreak;
  }

  /// Surfaces the end of an interval: emits an [event] for any visible screen
  /// to show, and plays a sound + haptic so the cue reaches the user even when
  /// the timer screen is in the background.
  void _notify(PomodoroEvent event) {
    if (!_events.isClosed) _events.add(event);
    // Platform feedback is best-effort — swallow both synchronous failures and
    // rejected futures (e.g. no binding in tests, unsupported on web).
    try {
      SystemSound.play(SystemSoundType.alert).ignore();
      HapticFeedback.mediumImpact().ignore();
    } catch (_) {}
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _events.close();
    super.dispose();
  }

  /// Restores the singleton to a pristine state between tests.
  @visibleForTesting
  void resetForTest() {
    _ticker?.cancel();
    _ticker = null;
    _settings = const PomodoroSettings();
    _phase = PomodoroPhase.work;
    _status = PomodoroStatus.idle;
    _remaining = _settings.secondsFor(_phase);
    _completedSessions = 0;
  }
}
