import 'dart:async';
import 'package:flutter/material.dart';
import 'package:draft_1/model.dart'; // Assuming this is where your models are
import 'package:draft_1/homepage.dart';
import 'package:draft_1/theme/app_theme.dart';
import 'package:draft_1/sync/sync_service.dart';
import '../globals.dart' as globals;

class UserNew extends StatefulWidget {
  const UserNew({super.key});

  @override
  _UserNewState createState() => _UserNewState();
}

class _UserNewState extends State<UserNew> {
  final _subjectController = TextEditingController();
  String _selectedTestType = 'unit';
  final _monthController = TextEditingController();
  final _dayController = TextEditingController();
  final _yearController = TextEditingController();
  double _difficulty = 2;
  final _currentGradeController = TextEditingController();
  final _targetGradeController = TextEditingController();

  int _currentStep = 0; // Step tracker
  final int _totalSteps = 5; // Total number of questions/steps

  // Typewriter animation variables
  String _questionText = "";
  final List<String> _questions = [
    "Enter your subjects name",
    "Enter the type of test",
    "Enter the date of your test in MM/DD/YYYY",
    "Select the difficulty of your test",
    "Enter your current and target grade",
  ];

  @override
  void initState() {
    super.initState();
    _animateQuestion(); // Start animation on init
  }

  void _animateQuestion() {
    _questionText = "";
    int charIndex = 0;
    const duration = Duration(milliseconds: 100); // Speed of typing

    Timer.periodic(duration, (timer) {
      if (charIndex < _questions[_currentStep].length) {
        setState(() {
          _questionText += _questions[_currentStep][charIndex];
          charIndex++;
        });
      } else {
        _questionText += '|'; // Add cursor at the end
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${_currentStep + 1} of $_totalSteps',
          style: context.text.titleMedium?.copyWith(color: colors.onSurface),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(30.0),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / _totalSteps,
              color: colors.positive,
              backgroundColor: colors.onSurface,
            ),
          ),
        ),
      ),
      body: Center(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.xl),
              child: Text(
                _questionText,
                style:
                    context.text.headlineMedium?.copyWith(color: colors.accentText),
                textAlign: TextAlign.center,
              ),
            ),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.xl),
              radius: AppRadius.lg,
              child: Center(child: _buildStepInput()),
            ),
            const VGap(AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back button
                if (_currentStep > 0)
                  _buildCircularButton(Icons.arrow_back, () {
                    setState(() {
                      _currentStep--;
                      _animateQuestion(); // Restart animation
                    });
                  }),

                // Next button or Save button
                if (_currentStep < _totalSteps - 1)
                  _buildCircularButton(Icons.arrow_forward, () {
                    setState(() {
                      _currentStep++;
                      _animateQuestion(); // Restart animation
                    });
                  })
                else
                  ElevatedButton(
                    onPressed: () {
                      createTest();
                      Navigator.pushReplacement(context,
                          MaterialPageRoute(builder: (context) => HomePage()));
                    },
                    style: AppButtons.positive(context),
                    child: const Text('Save'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularButton(IconData icon, VoidCallback onPressed) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.surface,
      ),
      child: IconButton(
        icon: Icon(icon, color: colors.onSurface),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildStepInput() {
    final colors = context.colors;
    final fieldStyle = context.text.bodyLarge?.copyWith(color: colors.onSurface);
    switch (_currentStep) {
      case 0:
        return TextField(
          controller: _subjectController,
          decoration: AppInputs.onCard(context, hint: 'Subject: '),
          style: fieldStyle,
        );
      case 1:
        return DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedTestType,
            dropdownColor: colors.surface,
            style: fieldStyle,
            onChanged: (String? newValue) {
              setState(() {
                _selectedTestType = newValue!;
              });
            },
            items: <String>['unit', 'quiz', 'final']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
        );
      case 2:
        return Row(
          children: [
            Expanded(
              child: TextField(
                controller: _monthController,
                decoration: AppInputs.onCard(context, hint: 'MM'),
                keyboardType: TextInputType.number,
                style: fieldStyle,
              ),
            ),
            const HGap(AppSpacing.md),
            Expanded(
              child: TextField(
                controller: _dayController,
                decoration: AppInputs.onCard(context, hint: 'DD'),
                keyboardType: TextInputType.number,
                style: fieldStyle,
              ),
            ),
            const HGap(AppSpacing.md),
            Expanded(
              child: TextField(
                controller: _yearController,
                decoration: AppInputs.onCard(context, hint: 'YYYY'),
                keyboardType: TextInputType.number,
                style: fieldStyle,
              ),
            ),
          ],
        );
      case 3:
        return Column(
          children: [
            Slider(
              value: _difficulty,
              min: 0,
              max: 4,
              divisions: 4,
              onChanged: (double value) {
                setState(() {
                  _difficulty = value;
                });
              },
              label: _getDifficultyLabel(_difficulty),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Very Easy', style: fieldStyle),
                Text('Very Hard', style: fieldStyle),
              ],
            ),
          ],
        );
      case 4:
        return Row(
          children: [
            Expanded(
              child: TextField(
                controller: _currentGradeController,
                decoration: AppInputs.onCard(context, hint: 'Current Grade (%)'),
                keyboardType: TextInputType.number,
                style: fieldStyle,
              ),
            ),
            const HGap(AppSpacing.md),
            Expanded(
              child: TextField(
                controller: _targetGradeController,
                decoration: AppInputs.onCard(context, hint: 'Target Grade (%)'),
                keyboardType: TextInputType.number,
                style: fieldStyle,
              ),
            ),
          ],
        );
      default:
        return Container(); // Fallback case
    }
  }

  String _getDifficultyLabel(double value) {
    switch (value.toInt()) {
      case 0:
        return 'Very Easy';
      case 1:
        return 'Easy';
      case 2:
        return 'Normal';
      case 3:
        return 'Hard';
      case 4:
        return 'Very Hard';
      default:
        return '';
    }
  }

  void createTest() {
    TestType type = TestType.unit;
    switch (_selectedTestType) {
      case 'unit':
        type = TestType.unit;
        break;
      case 'quiz':
        type = TestType.quiz;
        break;
      case 'final':
        type = TestType.finals;
        break;
    }

    TestDifficulty difficulty = TestDifficulty.normal;
    switch (_difficulty.toInt()) {
      case 0:
        difficulty = TestDifficulty.veryeasy;
        break;
      case 1:
        difficulty = TestDifficulty.easy;
        break;
      case 2:
        difficulty = TestDifficulty.normal;
        break;
      case 3:
        difficulty = TestDifficulty.hard;
        break;
      case 4:
        difficulty = TestDifficulty.veryhard;
        break;
    }

    Test test = Test(
      _subjectController.text,
      DateTime(int.parse(_yearController.text),
          int.parse(_monthController.text), int.parse(_dayController.text)),
      type,
      difficulty,
      int.parse(_currentGradeController.text),
      int.parse(_targetGradeController.text),
    );

    globals.tests.add(test);
    // Persist locally and queue a cloud backup (if sync is enabled).
    SyncService.instance.markDirty();
  }
}
