import 'package:draft_1/model.dart';

/// Aggregated study metrics for a single calendar day, used by the charts on
/// the analytics dashboard.
class DailyStat {
  final DateTime day;
  final int studyMinutes;
  final int cardsReviewed;
  final int correctAnswers;

  const DailyStat({
    required this.day,
    required this.studyMinutes,
    required this.cardsReviewed,
    required this.correctAnswers,
  });

  double get accuracy =>
      cardsReviewed == 0 ? 0 : correctAnswers / cardsReviewed;
}

/// Central, in-memory store of the user's [StudySession]s plus the derived
/// metrics shown on the analytics dashboard (study time, cards reviewed,
/// accuracy, streaks and completed sessions).
///
/// A single global [instance] is shared by the app. Until real session
/// tracking is wired in, it is seeded with representative sample data so the
/// dashboard renders meaningfully.
class StudyAnalytics {
  StudyAnalytics._();

  static final StudyAnalytics instance = StudyAnalytics._();

  /// All recorded study sessions, most-recent last.
  final List<StudySession> sessions = _sampleSessions();

  /// Replaces all recorded sessions with [restored]. Used when loading a
  /// locally-persisted snapshot or restoring a backup from the cloud.
  void replaceSessions(Iterable<StudySession> restored) {
    sessions
      ..clear()
      ..addAll(restored);
  }

  // --- Headline metrics -----------------------------------------------------

  /// Total time spent studying across every session.
  Duration get totalStudyTime => Duration(
        minutes: sessions.fold(0, (sum, s) => sum + s.durationMinutes),
      );

  /// Total number of flashcards reviewed across every session.
  int get totalCardsReviewed =>
      sessions.fold(0, (sum, s) => sum + s.cardsReviewed);

  /// Overall accuracy (correct / reviewed) across every session, 0.0 – 1.0.
  double get overallAccuracy {
    final reviewed = totalCardsReviewed;
    if (reviewed == 0) return 0;
    final correct = sessions.fold(0, (sum, s) => sum + s.correctAnswers);
    return correct / reviewed;
  }

  /// Number of completed study sessions.
  int get completedSessions => sessions.length;

  /// Consecutive days (ending today or yesterday) with at least one session.
  int get currentStreak {
    final studiedDays = _studiedDays();
    if (studiedDays.isEmpty) return 0;

    final today = _dateOnly(DateTime.now());
    // Allow the streak to still count if the user hasn't studied yet today.
    var cursor = studiedDays.contains(today)
        ? today
        : today.subtract(const Duration(days: 1));

    var streak = 0;
    while (studiedDays.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Longest run of consecutive studied days on record.
  int get longestStreak {
    final days = _studiedDays().toList()..sort();
    if (days.isEmpty) return 0;

    var longest = 1;
    var run = 1;
    for (var i = 1; i < days.length; i++) {
      if (days[i].difference(days[i - 1]).inDays == 1) {
        run++;
        if (run > longest) longest = run;
      } else {
        run = 1;
      }
    }
    return longest;
  }

  // --- Chart data -----------------------------------------------------------

  /// Per-day aggregates for the last [days] days, oldest first. Days with no
  /// activity are included with zero values so charts keep a steady axis.
  List<DailyStat> dailyStats({int days = 7}) {
    final today = _dateOnly(DateTime.now());
    return List.generate(days, (i) {
      final day = today.subtract(Duration(days: days - 1 - i));
      final forDay = sessions.where((s) => _dateOnly(s.date) == day);
      return DailyStat(
        day: day,
        studyMinutes: forDay.fold(0, (sum, s) => sum + s.durationMinutes),
        cardsReviewed: forDay.fold(0, (sum, s) => sum + s.cardsReviewed),
        correctAnswers: forDay.fold(0, (sum, s) => sum + s.correctAnswers),
      );
    });
  }

  // --- Helpers --------------------------------------------------------------

  Set<DateTime> _studiedDays() =>
      sessions.map((s) => _dateOnly(s.date)).toSet();

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}

/// Builds a fortnight of plausible study sessions ending today, with a small
/// gap so streak logic is exercised. Generated relative to "now" so the
/// dashboard always shows recent activity.
List<StudySession> _sampleSessions() {
  final today = StudyAnalytics._dateOnly(DateTime.now());

  // (daysAgo, subject, minutes, cards, correct) — a 7-day current streak,
  // a one-day gap, then earlier activity for the longest-streak metric.
  const samples = <List<Object>>[
    [0, 'Chemistry', 35, 40, 36],
    [1, 'Biology', 25, 30, 24],
    [2, 'Chemistry', 50, 55, 51],
    [3, 'History', 20, 22, 17],
    [4, 'Biology', 40, 45, 40],
    [5, 'Chemistry', 30, 35, 29],
    [6, 'History', 45, 50, 41],
    [8, 'Biology', 30, 33, 28],
    [9, 'Chemistry', 55, 60, 57],
    [10, 'History', 25, 28, 21],
    [11, 'Biology', 35, 38, 33],
  ];

  return [
    for (final s in samples)
      StudySession(
        date: today.subtract(Duration(days: s[0] as int)),
        subject: s[1] as String,
        durationMinutes: s[2] as int,
        cardsReviewed: s[3] as int,
        correctAnswers: s[4] as int,
      ),
  ].reversed.toList();
}
