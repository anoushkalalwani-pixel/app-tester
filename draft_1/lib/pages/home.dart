import 'dart:convert';
import 'dart:async';
import 'package:draft_1/globals.dart' as globals;
import 'package:draft_1/model.dart';
import 'package:draft_1/OpenAIAPI.dart';
import 'package:draft_1/sync/sync_service.dart';
import 'package:draft_1/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UserHome extends StatefulWidget {
  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class TypingText extends StatefulWidget {
  final String text;
  final Duration speed;
  final TextStyle? style; // Optional style parameter for text customization

  TypingText(
      {required this.text,
      this.speed = const Duration(milliseconds: 150),
      this.style});

  @override
  _TypingTextState createState() => _TypingTextState();
}

class _TypingTextState extends State<TypingText> {
  String _displayText = '';
  int _currentIndex = 0;
  Timer? _timer;
  bool _showCursor = true;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  void _startTyping() {
    _timer = Timer.periodic(widget.speed, (timer) {
      if (_currentIndex < widget.text.length) {
        setState(() {
          _displayText = widget.text.substring(0, _currentIndex + 1);
          _currentIndex++;
        });
      } else {
        _timer?.cancel();
        _blinkCursor();
      }
    });
  }

  void _blinkCursor() {
    _timer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      setState(() {
        _showCursor = !_showCursor;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      '$_displayText${_showCursor ? "|" : ""}',
      style: widget.style ??
          context.text.titleLarge?.copyWith(color: context.colors.bodyText),
    );
  }
}

class _TaskListScreenState extends State<UserHome> {
  bool isLoading = true;
  bool haveTests = false;
  List<dynamic> content = List.empty();
  List<DateTime> dates = List.empty();

  Future<Map<String, dynamic>> getAITasks() async {
    final openAIAPI = OpenAIAPI();
    DateTime today = DateTime.now();
    String formattedDate = DateFormat('MM/dd/yyyy').format(today);
    int testCount = globals.tests.length - 1;
    final String testSubject = globals.tests[testCount].subject;
    final String testDate = globals.tests[testCount].testDate.toString();
    final String daysToTest = globals.tests[testCount].testDate
        .difference(DateTime.now())
        .inDays
        .toString();
    final response = await openAIAPI.generateCompletion(
      'create a plan to study for a $testSubject unit test for 10th grade, the test is $daysToTest days in the future from $testDate.  please give me a task for every day starting $formattedDate.',
      300,
    );

    return response;
  }

  Future<void> populateTasks() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await getAITasks();
      content = response['choices'];
      String a = content[0]['message']['content'];
      Map<String, dynamic> jsonData = jsonDecode(a);
      content = jsonData['study_plan'];

      // Generate dates for the current month
      dates = List.generate(
          content.length,
          (index) => DateTime(
                  DateTime.now().year, DateTime.now().month, DateTime.now().day)
              .add(Duration(days: index)));

      for (var i = 0; i < content.length; i++) {
        if (globals.tasksByDate[dates[i]] != null) {
          globals.tasksByDate[dates[i]]
              ?.add(Task(name: content[i]["task"], isCompleted: false));
        } else {
          globals.tasksByDate[dates[i]] = [
            Task(name: content[i]["task"], isCompleted: false)
          ];
        }
      }
      // Persist the freshly generated plan and queue a backup.
      SyncService.instance.markDirty();
    } catch (e) {
      print("Error: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    try {
      if (globals.tests.isNotEmpty) {
        populateTasks();
        setState(() {
          haveTests = true;
        });
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      appBar: AppBar(title: const Text('Tasks')),
      body: haveTests
          ? isLoading
              ? const _CalendarSkeleton()
              : _buildCalendar()
          : Center(
              child: TypingText(
                text: 'Hi Anoushka! Let\'s add a test',
                style:
                    context.text.titleLarge?.copyWith(color: colors.accentText),
              ),
            ),
    );
  }

  Widget _buildCalendar() {
    final colors = context.colors;
    DateTime firstDayOfMonth =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    int firstWeekday =
        firstDayOfMonth.weekday; // Day of week for the 1st day of the month
    int totalDays = DateTime(DateTime.now().year, DateTime.now().month + 1, 0)
        .day; // Total days in the month
    int totalCells = (firstWeekday - 1) + totalDays; // Total cells in the grid

    return Column(
      children: [
        // Month header
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          alignment: Alignment.center,
          child: Text(
            DateFormat('MMMM yyyy').format(firstDayOfMonth),
            style:
                context.text.headlineMedium?.copyWith(color: colors.bodyText),
          ),
        ),
        // Day names
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(7, (index) {
            return Text(
              DateFormat.E().format(
                  DateTime(2021, 1, index + 1)), // Use any year for day names
              style: context.text.bodyLarge?.copyWith(
                color: colors.bodyText,
                fontWeight: FontWeight.bold,
              ),
            );
          }),
        ),
        // Calendar grid
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7, // 7 days in a week
              childAspectRatio: 1.0,
            ),
            itemCount: totalCells,
            itemBuilder: (context, index) {
              if (index < firstWeekday - 1) {
                // Empty space before the first day of the month
                return Container();
              } else {
                int day = index - (firstWeekday - 1) + 1;
                if (day <= totalDays) {
                  DateTime date = DateTime(
                      firstDayOfMonth.year, firstDayOfMonth.month, day);
                  return Stack(
                    alignment: Alignment.topLeft,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.xs),
                        child: Material(
                          color: colors.surface,
                          child: InkWell(
                            onTap: () {
                              AppHaptics.selection();
                              _showTasksForDate(date);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: colors.onSurface,
                                    width: 1), // visual separation
                              ),
                              child: Center(
                                child: Text(
                                  day.toString(),
                                  style: context.text.titleLarge
                                      ?.copyWith(color: colors.onSurface),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Show dot if there are tasks for this day
                      if (globals.tasksByDate[date]?.isNotEmpty ?? false)
                        Positioned(
                          top: 4,
                          left: 4,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: colors.positive,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  );
                } else {
                  // Empty space after the last day of the month
                  return Container();
                }
              }
            },
          ),
        ),
      ],
    );
  }

  void _showTasksForDate(DateTime date) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(DateFormat('MMMM d, yyyy').format(date)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _buildTaskList(date),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // Inside _buildTaskList method
  List<Widget> _buildTaskList(DateTime date) {
    List<Task> tasks = globals.tasksByDate[date] ?? [];
    return tasks.map((task) {
      return StatefulBuilder(
        builder: (context, setState) {
          return CheckboxListTile(
            title: Text(
              task.name,
              style: context.text.bodyLarge
                  ?.copyWith(color: context.colors.bodyText),
            ),
            value: task.isCompleted,
            onChanged: (bool? value) {
              setState(() {
                if (value != null) {
                  task.isCompleted = value;
                }
              });
              // Persist the completion change and queue a backup.
              SyncService.instance.markDirty();
              // Trigger the outer widget's rebuild as well to ensure everything is consistent
              this.setState(() {});
            },
          );
        },
      );
    }).toList();
  }
}

/// Placeholder shown while the AI study plan is being generated: a month-shaped
/// grid of shimmering tiles so the screen keeps its layout instead of showing a
/// bare spinner.
class _CalendarSkeleton extends StatelessWidget {
  const _CalendarSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const VGap(AppSpacing.sm),
          const Center(child: Skeleton(width: 160, height: 24)),
          const VGap(AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              7,
              (_) => const Skeleton(width: 18, height: 14),
            ),
          ),
          const VGap(AppSpacing.md),
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1.0,
              ),
              itemCount: 35,
              itemBuilder: (context, _) => const Padding(
                padding: EdgeInsets.all(AppSpacing.xs),
                child: Skeleton(height: double.infinity, radius: AppRadius.sm),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
