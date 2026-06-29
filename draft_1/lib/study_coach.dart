import 'package:draft_1/globals.dart' as globals;
import 'package:draft_1/study_analytics.dart';

/// How urgently a subject should be reviewed. Drives the colour and ordering of
/// the cards on the coach screen.
enum ReviewPriority { high, medium, low }

/// A per-subject summary derived from the user's study history and upcoming
/// test schedule.
///
/// This is the deterministic evidence the coach reasons over — and the exact
/// data handed to the AI provider — covering the three signals the coach
/// weighs: how *often* a subject is studied ([daysSinceLastStudied],
/// [sessionCount]), how *well* the user performs on it ([accuracy]), and how
/// *soon* its next test is ([daysUntilTest]).
class SubjectInsight {
  /// Display name of the subject (first-seen spelling).
  final String subject;

  /// Number of logged study sessions for this subject.
  final int sessionCount;

  /// Total minutes spent studying this subject.
  final int totalMinutes;

  /// Total flashcards reviewed for this subject.
  final int cardsReviewed;

  /// Mean accuracy across sessions (0.0–1.0), or null if never studied.
  final double? accuracy;

  /// Whole days since the most recent session, or null if never studied.
  final int? daysSinceLastStudied;

  /// Whole days until the next scheduled test, or null if none upcoming.
  final int? daysUntilTest;

  const SubjectInsight({
    required this.subject,
    required this.sessionCount,
    required this.totalMinutes,
    required this.cardsReviewed,
    required this.accuracy,
    required this.daysSinceLastStudied,
    required this.daysUntilTest,
  });

  /// A 0–100 "review now" score combining the three signals. Higher means the
  /// subject is more in need of attention. Used to rank recommendations and to
  /// derive [priority].
  double get priorityScore {
    // Weak performance → more need. Unknown performance is treated as moderate.
    final perfPart =
        accuracy == null ? 0.5 : (1 - accuracy!).clamp(0.0, 1.0);

    // Stale review → more need. Never studied is maximally stale.
    final recencyPart = daysSinceLastStudied == null
        ? 1.0
        : (daysSinceLastStudied! / 14).clamp(0.0, 1.0);

    // Imminent test → more need. No upcoming test contributes nothing.
    final urgencyPart = daysUntilTest == null
        ? 0.0
        : ((30 - daysUntilTest!) / 30).clamp(0.0, 1.0);

    return 100 * (0.4 * perfPart + 0.3 * recencyPart + 0.3 * urgencyPart);
  }

  /// [priorityScore] bucketed into a [ReviewPriority].
  ReviewPriority get priority {
    final score = priorityScore;
    if (score >= 60) return ReviewPriority.high;
    if (score >= 35) return ReviewPriority.medium;
    return ReviewPriority.low;
  }

  /// A concise, data-grounded explanation of why the subject needs review,
  /// used as the offline fallback reason.
  String get reason {
    final clauses = <String>[];
    if (accuracy == null) {
      clauses.add('no study sessions logged yet');
    } else {
      clauses.add('${(accuracy! * 100).round()}% average accuracy');
    }
    if (daysSinceLastStudied != null && daysSinceLastStudied! >= 4) {
      clauses.add('not reviewed in $daysSinceLastStudied days');
    }
    if (daysUntilTest != null) {
      clauses.add(switch (daysUntilTest!) {
        0 => 'test is today',
        1 => 'test is tomorrow',
        final d => 'test in $d days',
      });
    }
    if (clauses.isEmpty) return 'Keep this subject fresh with a quick review.';
    final joined = clauses.join(', ');
    return '${joined[0].toUpperCase()}${joined.substring(1)}.';
  }

  /// A concrete next study action, used as the offline fallback action.
  String get suggestedAction {
    if (daysUntilTest != null && daysUntilTest! <= 7) {
      return 'Do a focused review and a timed practice quiz before the test.';
    }
    if (accuracy != null && accuracy! < 0.7) {
      return 'Re-study the fundamentals and redo the cards you missed.';
    }
    if (daysSinceLastStudied == null) {
      return 'Start with a short session to build a baseline.';
    }
    return 'Run a quick refresher session to keep it sharp.';
  }

  /// Compact JSON sent to the AI provider. Keys are chosen to be
  /// self-describing so the prompt can reference them directly.
  Map<String, dynamic> toJson() => {
        'subject': subject,
        'sessions': sessionCount,
        'totalMinutes': totalMinutes,
        'cardsReviewed': cardsReviewed,
        'accuracyPercent': accuracy == null ? null : (accuracy! * 100).round(),
        'daysSinceLastStudied': daysSinceLastStudied,
        'daysUntilNextTest': daysUntilTest,
      };
}

/// A single coaching recommendation: which subject to review next, how urgent
/// it is, why, and what to do about it.
class Recommendation {
  final String subject;
  final ReviewPriority priority;
  final String reason;
  final String suggestedAction;

  /// True if produced by the AI provider, false if from the offline ranking.
  final bool aiGenerated;

  const Recommendation({
    required this.subject,
    required this.priority,
    required this.reason,
    required this.suggestedAction,
    required this.aiGenerated,
  });

  /// Maps an AI-supplied priority string onto a [ReviewPriority], defaulting to
  /// medium for anything unrecognised.
  static ReviewPriority priorityFromString(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'high':
        return ReviewPriority.high;
      case 'low':
        return ReviewPriority.low;
      default:
        return ReviewPriority.medium;
    }
  }
}

/// Personalized study coach.
///
/// Combines the recorded study history ([StudyAnalytics]) with the upcoming
/// test schedule ([globals.tests]) into per-subject [SubjectInsight]s, and
/// turns those into ranked [Recommendation]s. The deterministic ranking here
/// works fully offline; richer natural-language recommendations are produced by
/// [OpenAIAPI.generateStudyRecommendations], which consumes the same insights.
class StudyCoach {
  StudyCoach._();

  static final StudyCoach instance = StudyCoach._();

  final StudyAnalytics _analytics = StudyAnalytics.instance;

  /// Builds one [SubjectInsight] per subject seen in either the study history
  /// or the test schedule. Subjects are grouped case-insensitively, keeping the
  /// first-seen spelling for display.
  List<SubjectInsight> subjectInsights() {
    final sessions = _analytics.sessions;
    final tests = globals.tests;
    final today = _dateOnly(DateTime.now());

    // Union of subjects, in first-seen order, mapping a lowercase key to its
    // display spelling.
    final order = <String>[];
    final display = <String, String>{};
    void register(String raw) {
      final name = raw.trim();
      if (name.isEmpty) return;
      final key = name.toLowerCase();
      if (!display.containsKey(key)) {
        display[key] = name;
        order.add(key);
      }
    }

    for (final s in sessions) {
      register(s.subject);
    }
    for (final t in tests) {
      register(t.subject);
    }

    final insights = <SubjectInsight>[];
    for (final key in order) {
      final subjSessions =
          sessions.where((s) => s.subject.trim().toLowerCase() == key);

      final cards = subjSessions.fold(0, (n, s) => n + s.cardsReviewed);
      final correct = subjSessions.fold(0, (n, s) => n + s.correctAnswers);
      final minutes = subjSessions.fold(0, (n, s) => n + s.durationMinutes);

      int? daysSince;
      if (subjSessions.isNotEmpty) {
        final last = subjSessions
            .map((s) => _dateOnly(s.date))
            .reduce((a, b) => a.isAfter(b) ? a : b);
        daysSince = today.difference(last).inDays;
      }

      // Nearest test scheduled today or later.
      final upcoming = tests
          .where((t) => t.subject.trim().toLowerCase() == key)
          .map((t) => _dateOnly(t.testDate))
          .where((d) => !d.isBefore(today))
          .toList()
        ..sort();
      final daysUntil =
          upcoming.isEmpty ? null : upcoming.first.difference(today).inDays;

      insights.add(SubjectInsight(
        subject: display[key]!,
        sessionCount: subjSessions.length,
        totalMinutes: minutes,
        cardsReviewed: cards,
        accuracy: cards == 0 ? null : correct / cards,
        daysSinceLastStudied: daysSince,
        daysUntilTest: daysUntil,
      ));
    }
    return insights;
  }

  /// Deterministic, offline ranking — most urgent first. Seeds the screen
  /// instantly and is the fallback when the AI provider is unavailable.
  List<Recommendation> localRecommendations() {
    final insights = subjectInsights()
      ..sort((a, b) => b.priorityScore.compareTo(a.priorityScore));
    return [
      for (final insight in insights)
        Recommendation(
          subject: insight.subject,
          priority: insight.priority,
          reason: insight.reason,
          suggestedAction: insight.suggestedAction,
          aiGenerated: false,
        ),
    ];
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
