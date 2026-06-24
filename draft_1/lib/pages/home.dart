/*
import 'dart:convert';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:draft_1/globals.dart' as globals;
import 'package:draft_1/model.dart';
import 'package:draft_1/OpenAIAPI.dart';
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

  TypingText({required this.text, this.speed = const Duration(milliseconds: 150), this.style});

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
      style: widget.style ?? TextStyle(fontSize: 20, color: Colors.blue), // Apply the passed style
    );
  }
}

class _TaskListScreenState extends State<UserHome> {
  bool isLoading = true;
  bool haveTests = false;
  List<dynamic> content = List.empty();
  List<DateTime> dates = List.empty();
  static const apiKey = '';

  Future<Map<String, dynamic>> getAITasks() async {
    final openAIAPI = OpenAIAPI(apiKey);
    DateTime today = DateTime.now();
    String formattedDate = DateFormat('MM/dd/yyyy').format(today);    
    int testCount = globals.tests.length - 1;
    final String testSubject = globals.tests[testCount].subject;
    final String testDate = globals.tests[testCount].testDate.toString();
    final String daysToTest = globals.tests[testCount].testDate.difference(DateTime.now()).inDays.toString();
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

      dates = List.generate(content.length, (index) => DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day).add(Duration(days: index)));

      for (var i = 0; i < content.length; i++) {
        if (globals.tasksByDate[dates[i]] != null) {
          globals.tasksByDate[dates[i]]?.add(Task(name: content[i]["task"], isCompleted: false));
        } else {
          globals.tasksByDate[dates[i]] = [Task(name: content[i]["task"], isCompleted: false)];
        }
      }
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Tasks',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue[800],
      ),
      body: haveTests
          ? isLoading
              ? Center(child: CircularProgressIndicator())
              : _buildCalendar()
          : Center(
              child: TypingText(
                text: 'Hi Anoushka! Let\'s add a test',
                style: GoogleFonts.sourceCodePro(
                  fontSize: 20,
                  color: Color.fromARGB(255, 50, 30, 130),
                ),
              ),
            ),
      backgroundColor: Colors.lightBlue[100], // Light blue background
    );
  }

  Widget _buildCalendar() {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7, // 7 days in a week
        childAspectRatio: 1.0,
      ),
      itemCount: dates.length,
      itemBuilder: (context, index) {
        DateTime date = dates[index];
        return GestureDetector(
          onTap: () => _showTasksForDate(date),
          child: Container(
            margin: EdgeInsets.all(4.0),
            decoration: BoxDecoration(
              color: Colors.blue[700],
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Center(
              child: Text(
                DateFormat('d').format(date),
                style: GoogleFonts.sourceCodePro(
                  fontSize: 20,
                  color: Colors.white, // White text
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showTasksForDate(DateTime date) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            DateFormat('EEE, MMM d').format(date),
            style: GoogleFonts.sourceCodePro(fontSize: 24, color: Colors.blue[800]),
          ),
          content: SingleChildScrollView(
            child: Column(
              children: _buildTaskList(date),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text("Back", style: GoogleFonts.sourceCodePro(color: Colors.blue[800])),
            ),
          ],
        );
      },
    );
  }

  // Build the task list for a specific date
  List<Widget> _buildTaskList(DateTime date) {
    List<Task> tasks = globals.tasksByDate[date] ?? [];
    return tasks.map((task) {
      return CheckboxListTile(
        title: Text(
          task.name,
          style: GoogleFonts.sourceCodePro(color: Colors.black), // Change text color if needed
        ),
        value: task.isCompleted,
        onChanged: (bool? value) {
          setState(() {
            task.isCompleted = value!;
          });
        },
      );
    }).toList();
  }
}
*/
import 'dart:convert';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:draft_1/globals.dart' as globals;
import 'package:draft_1/model.dart';
import 'package:draft_1/OpenAIAPI.dart';
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

  TypingText({required this.text, this.speed = const Duration(milliseconds: 150), this.style});

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
      style: widget.style ?? TextStyle(fontSize: 20, color: Color.fromARGB(255, 0, 37, 68)), // Apply the passed style
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
    final String daysToTest = globals.tests[testCount].testDate.difference(DateTime.now()).inDays.toString();
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
      DateTime firstDayOfMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
      DateTime lastDayOfMonth = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);
      dates = List.generate(content.length, (index) => DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day).add(Duration(days: index)));

      for (var i = 0; i < content.length; i++) {
        if (globals.tasksByDate[dates[i]] != null) {
          globals.tasksByDate[dates[i]]?.add(Task(name: content[i]["task"], isCompleted: false));
        } else {
          globals.tasksByDate[dates[i]] = [Task(name: content[i]["task"], isCompleted: false)];
        }
      }

      print(dates);
      print("*******************");
      print(globals.tasksByDate);
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Tasks',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color.fromARGB(255, 0, 37, 68),
      ),
      body: haveTests
          ? isLoading
              ? Center(child: CircularProgressIndicator())
              : _buildCalendar()
          : Center(
              child: TypingText(
                text: 'Hi Anoushka! Let\'s add a test',
                style: GoogleFonts.nunito(
                  fontSize: 20,
                  color: Color.fromARGB(255, 50, 30, 130),
                ),
              ),
            ),
      backgroundColor: Colors.lightBlue[100], // Light blue background
    );
  }

  Widget _buildCalendar() {
    DateTime firstDayOfMonth = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    int firstWeekday = firstDayOfMonth.weekday; // Day of week for the 1st day of the month
    int totalDays = DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day; // Total days in the month
    int totalCells = (firstWeekday - 1) + totalDays; // Total cells in the grid

    return Column(
      children: [
        // Month header
        Container(
          padding: EdgeInsets.all(16.0),
          alignment: Alignment.center,
          child: Text(
            DateFormat('MMMM yyyy').format(firstDayOfMonth),
            style: GoogleFonts.nunito(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        // Day names
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(7, (index) {
            return Text(
              DateFormat.E().format(DateTime(2021, 1, index + 1)), // Use any year for day names
              style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 0, 37, 68)),
            );
          }),
        ),
        // Calendar grid
        Expanded(
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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
                  DateTime date = DateTime(firstDayOfMonth.year, firstDayOfMonth.month, day);
                  return GestureDetector(
                    onTap: () => _showTasksForDate(date),
                    child: Stack(
                      alignment: Alignment.topLeft,
                      children: [
                        Container(
                          margin: EdgeInsets.all(4.0),
                          decoration: BoxDecoration(
                            color: Color.fromARGB(255, 0, 37, 68),
                            border: Border.all(color: Colors.white, width: 1), // Add border for visual separation
                          ),
                          child: Center(
                            child: Text(
                              day.toString(),
                              style: GoogleFonts.nunito(
                                fontSize: 20,
                                color: Colors.white, // White text for day
                              ),
                            ),
                          ),
                        ),
                        // Show green dot if there are tasks for this day
                        if (globals.tasksByDate[date]?.isNotEmpty ?? false)
                          Positioned(
                            top: 4,
                            left: 4,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
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
              child: Text('Close'),
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
            style: GoogleFonts.nunito(color: Colors.black), // Task name styling
          ),
          value: task.isCompleted,
          onChanged: (bool? value) {
            setState(() {
              if (value != null) {
                task.isCompleted = value;
              }
            });
            // Trigger the outer widget's rebuild as well to ensure everything is consistent
            this.setState(() {});
          },
        );
      },
    );
  }).toList();
}
}