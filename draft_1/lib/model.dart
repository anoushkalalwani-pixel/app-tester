

enum TestType { unit, quiz, finals }
enum TestDifficulty { veryeasy, easy, normal, hard, veryhard }

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
}
