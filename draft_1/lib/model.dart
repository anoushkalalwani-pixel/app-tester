

enum TestType { unit, quiz, finals }
enum TestDifficulty { veryeasy, easy, normal, hard, veryhard }

/// Resolves an enum value from its [Enum.name], falling back to [fallback] when
/// the stored name is missing or unrecognised. Used when restoring models from
/// JSON so a renamed or corrupt value never crashes a sync/restore.
T enumByName<T extends Enum>(List<T> values, Object? name, T fallback) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  return fallback;
}

class Test {
  String _subject = "unspecified";
  DateTime _testDate = DateTime.now();
  TestType _testType = TestType.unit;
  TestDifficulty _testDifficulty = TestDifficulty.normal;
  int _currentGrade = 0;
  int _targetGrade = 100;

  // Constructor
  Test(
    this._subject,
    this._testDate,
    this._testType,
    this._testDifficulty,
    this._currentGrade,
    this._targetGrade,
  );

  // Getter methods
  String get subject => _subject;
  DateTime get testDate => _testDate;
  TestType get testType => _testType;
  TestDifficulty get testDifficulty => _testDifficulty;
  int get currentGrade => _currentGrade;
  int get targetGrade => _targetGrade;

  // Setter methods
  set subject(String newSubject) {
    if (newSubject.isNotEmpty) {
      _subject = newSubject;
    }
  }

  set testDate(DateTime newTestDate) {
    _testDate = newTestDate;
  }

  set testType(TestType newTestType) {
    _testType = newTestType;
  }

  set testDifficulty(TestDifficulty newTestDifficulty) {
    _testDifficulty = newTestDifficulty;
  }

  set currentGrade(int newCurrentGrade) {
    if (newCurrentGrade >= 0 && newCurrentGrade <= 100) {
      _currentGrade = newCurrentGrade;
    }
  }

  set targetGrade(int newTargetGrade) {
    if (newTargetGrade >= 0 && newTargetGrade <= 100) {
      _targetGrade = newTargetGrade;
    }
  }

  /// Serialises the test for local persistence and cloud backup.
  Map<String, dynamic> toJson() => {
        'subject': _subject,
        'testDate': _testDate.toIso8601String(),
        'testType': _testType.name,
        'testDifficulty': _testDifficulty.name,
        'currentGrade': _currentGrade,
        'targetGrade': _targetGrade,
      };

  /// Rebuilds a test from its [toJson] form. Missing or malformed fields fall
  /// back to sensible defaults so a single bad record never breaks a restore.
  factory Test.fromJson(Map<String, dynamic> json) => Test(
        (json['subject'] ?? 'unspecified').toString(),
        DateTime.tryParse(json['testDate']?.toString() ?? '') ??
            DateTime.now(),
        enumByName(TestType.values, json['testType'], TestType.unit),
        enumByName(
            TestDifficulty.values, json['testDifficulty'], TestDifficulty.normal),
        (json['currentGrade'] as num?)?.toInt() ?? 0,
        (json['targetGrade'] as num?)?.toInt() ?? 100,
      );
}

class StudyPlan {
  Test _test;
  Map<DateTime, String> _plan;

  // Constructor
  StudyPlan(this._test, this._plan);

  // Getter methods
  Test get test => _test;
  Map<DateTime, String> get plan => _plan;

  // Setter methods
  set test(Test newTest) {
    _test = newTest;
  }

  set plan(Map<DateTime, String> newPlan) {
    _plan = newPlan;
  }

  // Method to add a new plan entry
  void addPlanEntry(DateTime date, String activity) {
    _plan[date] = activity;
  }

  // Method to remove a plan entry
  void removePlanEntry(DateTime date) {
    _plan.remove(date);
  }
}


class Task {
  String name;
  bool isCompleted;

  Task({required this.name, this.isCompleted = false});

  Map<String, dynamic> toJson() => {
        'name': name,
        'isCompleted': isCompleted,
      };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        name: (json['name'] ?? '').toString(),
        isCompleted: json['isCompleted'] == true,
      );
}

/// Parses a stored `tags` value into a clean, de-duplicated list.
///
/// Accepts the JSON list written by [Flashcard.toJson] / [Deck.toJson], trims
/// whitespace, drops empties, and removes case-insensitive duplicates while
/// preserving the original ordering and casing of the first occurrence. Any
/// non-list value (a missing field on older payloads, or corrupt data) yields
/// an empty list so a restore never crashes.
List<String> parseTags(Object? raw) {
  if (raw is! List) return [];
  final seen = <String>{};
  final tags = <String>[];
  for (final item in raw) {
    final tag = item.toString().trim();
    if (tag.isEmpty) continue;
    if (seen.add(tag.toLowerCase())) tags.add(tag);
  }
  return tags;
}

/// A single question/answer flashcard.
///
/// Fields are mutable so the user can tweak AI-generated cards on the review
/// screen before they are saved into a [Deck], and add free-form [tags] used by
/// the search & filtering screen.
class Flashcard {
  String question;
  String answer;
  List<String> tags;

  Flashcard({
    required this.question,
    required this.answer,
    List<String>? tags,
  }) : tags = tags ?? [];

  /// Builds a card from a single `{"question": ..., "answer": ...}` object as
  /// returned by the AI provider. Missing fields fall back to empty strings so
  /// a malformed entry never crashes the parse. [tags] are optional and absent
  /// on AI output and older payloads.
  factory Flashcard.fromJson(Map<String, dynamic> json) => Flashcard(
        question: (json['question'] ?? json['front'] ?? '').toString().trim(),
        answer: (json['answer'] ?? json['back'] ?? '').toString().trim(),
        tags: parseTags(json['tags']),
      );

  Map<String, dynamic> toJson() => {
        'question': question,
        'answer': answer,
        'tags': tags,
      };
}

/// A named collection of [Flashcard]s. AI-generated cards are reviewed and then
/// appended into either an existing deck or a brand new one. Decks can carry
/// their own [tags] (e.g. "biology", "exam") that the search screen treats as
/// applying to every card inside the deck.
class Deck {
  String name;
  final List<Flashcard> cards;
  List<String> tags;

  Deck({required this.name, List<Flashcard>? cards, List<String>? tags})
      : cards = cards ?? [],
        tags = tags ?? [];

  Map<String, dynamic> toJson() => {
        'name': name,
        'cards': [for (final card in cards) card.toJson()],
        'tags': tags,
      };

  factory Deck.fromJson(Map<String, dynamic> json) => Deck(
        name: (json['name'] ?? 'Untitled').toString(),
        cards: [
          for (final raw in (json['cards'] as List? ?? const []))
            if (raw is Map<String, dynamic>) Flashcard.fromJson(raw),
        ],
        tags: parseTags(json['tags']),
      );
}

/// A single completed study session, used to power the analytics dashboard.
class StudySession {
  /// The day (and time) the session took place.
  final DateTime date;

  /// Subject that was studied during the session.
  final String subject;

  /// How long the session lasted, in minutes.
  final int durationMinutes;

  /// Number of flashcards reviewed during the session.
  final int cardsReviewed;

  /// Of the [cardsReviewed], how many were answered correctly.
  final int correctAnswers;

  const StudySession({
    required this.date,
    required this.subject,
    required this.durationMinutes,
    required this.cardsReviewed,
    required this.correctAnswers,
  });

  /// Fraction of reviewed cards that were correct, in the range 0.0 – 1.0.
  double get accuracy =>
      cardsReviewed == 0 ? 0 : correctAnswers / cardsReviewed;

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'subject': subject,
        'durationMinutes': durationMinutes,
        'cardsReviewed': cardsReviewed,
        'correctAnswers': correctAnswers,
      };

  factory StudySession.fromJson(Map<String, dynamic> json) => StudySession(
        date: DateTime.tryParse(json['date']?.toString() ?? '') ??
            DateTime.now(),
        subject: (json['subject'] ?? 'unspecified').toString(),
        durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
        cardsReviewed: (json['cardsReviewed'] as num?)?.toInt() ?? 0,
        correctAnswers: (json['correctAnswers'] as num?)?.toInt() ?? 0,
      );
}
