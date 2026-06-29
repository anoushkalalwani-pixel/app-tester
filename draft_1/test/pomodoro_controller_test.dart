import 'package:draft_1/pomodoro/pomodoro_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Drives the controller's countdown deterministically: each [tick] is one
/// "second", so we can finish a phase without waiting on a real timer.
void advance(PomodoroController c, int seconds) {
  for (var i = 0; i < seconds; i++) {
    c.tick();
  }
}

void main() {
  late PomodoroController controller;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    controller = PomodoroController.instance;
    controller.resetForTest();
    // Don't spin up a real periodic timer; we tick manually.
    controller.autoTick = false;
  });

  tearDown(() => controller.resetForTest());

  test('starts idle on a full focus session', () {
    expect(controller.status, PomodoroStatus.idle);
    expect(controller.phase, PomodoroPhase.work);
    expect(controller.remaining, 25 * 60);
    expect(controller.completedSessions, 0);
  });

  test('start, pause, resume and reset move through the expected states', () {
    controller.start();
    expect(controller.isRunning, isTrue);

    advance(controller, 60);
    expect(controller.remaining, 25 * 60 - 60);

    controller.pause();
    expect(controller.isPaused, isTrue);
    // Ticks while paused are ignored.
    advance(controller, 10);
    expect(controller.remaining, 25 * 60 - 60);

    controller.resume();
    expect(controller.isRunning, isTrue);
    advance(controller, 60);
    expect(controller.remaining, 25 * 60 - 120);

    controller.reset();
    expect(controller.isIdle, isTrue);
    expect(controller.phase, PomodoroPhase.work);
    expect(controller.remaining, 25 * 60);
    expect(controller.completedSessions, 0);
  });

  test('finishing a focus session rolls into a short break and emits an event',
      () async {
    final events = <PomodoroEvent>[];
    final sub = controller.events.listen(events.add);

    controller.start();
    advance(controller, 25 * 60);

    expect(controller.phase, PomodoroPhase.shortBreak);
    expect(controller.completedSessions, 1);
    expect(controller.remaining, 5 * 60);

    await Future<void>.delayed(Duration.zero); // let the broadcast deliver
    expect(events, hasLength(1));
    expect(events.single.completed, PomodoroPhase.work);
    expect(events.single.next, PomodoroPhase.shortBreak);

    await sub.cancel();
  });

  test('a long break replaces the short one every Nth focus session', () {
    controller.start();
    // Four focus sessions (with the breaks between them) → long break.
    for (var session = 1; session <= 4; session++) {
      advance(controller, controller.remaining); // finish focus
      if (session < 4) {
        expect(controller.phase, PomodoroPhase.shortBreak,
            reason: 'session $session should lead to a short break');
        advance(controller, controller.remaining); // finish the break
      }
    }
    expect(controller.completedSessions, 4);
    expect(controller.phase, PomodoroPhase.longBreak);
    expect(controller.remaining, 15 * 60);
  });

  test('skip ends the current phase immediately', () {
    controller.start();
    controller.skip();
    expect(controller.phase, PomodoroPhase.shortBreak);
    expect(controller.completedSessions, 1);
  });

  test('updateSettings persists and refreshes the idle countdown', () async {
    await controller.updateSettings(
      const PomodoroSettings(workMinutes: 30, shortBreakMinutes: 10),
    );
    expect(controller.settings.workMinutes, 30);
    expect(controller.remaining, 30 * 60);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('pomodoro.workMinutes'), 30);
    expect(prefs.getInt('pomodoro.shortBreakMinutes'), 10);
  });

  test('settings are clamped to a sane range', () {
    const settings = PomodoroSettings(
      workMinutes: 0,
      sessionsBeforeLongBreak: 99,
    );
    final clamped = settings.copyWith();
    expect(clamped.workMinutes, 1);
    expect(clamped.sessionsBeforeLongBreak, 12);
  });
}
