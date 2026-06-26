//import 'dart:js_interop';

//import 'dart:js_interop';

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:draft_1/model.dart'; // Assuming this is where your models are
import 'package:draft_1/homepage.dart';
import 'package:draft_1/theme/app_theme.dart';
import '../globals.dart' as globals;

class UserNew extends StatefulWidget {
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
  int _totalSteps = 5;  // Total number of questions/steps

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
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          '${_currentStep + 1} of $_totalSteps',
          style: GoogleFonts.nunito(color: colors.onSurface, fontSize: 18),

        ),
        backgroundColor: colors.surface,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(30.0),
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 20.0),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / _totalSteps,
              color: colors.positive,
              backgroundColor: Colors.white,
            ),
          ),
        ),
      ),
      body: Center(
        child: ListView(
          padding: const EdgeInsets.all(15.0),
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              child: Text(
                _questionText,
                style: GoogleFonts.nunito(fontSize: 24, color: colors.accentText),
                textAlign: TextAlign.center,
              ),
            ),
            _buildStepContainer(
              child: _buildStepInput(),
            ),
            SizedBox(height: 20),
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
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomePage()));
                    },
                    child: Text('Save'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.positive,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                      textStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
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

  Widget _buildStepContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: context.colors.surface, // Dark blue background
        borderRadius: BorderRadius.circular(15.0), // Rounded corners
      ),
      child: Center(child: child),
    );
  }

  Widget _buildStepInput() {
    final colors = context.colors;
    switch (_currentStep) {
      case 0:
        return TextField(
          controller: _subjectController,
          decoration: InputDecoration(
            hintText: 'Subject: ',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white),
          ),
          style: GoogleFonts.nunito(color: Colors.white, fontSize: 18),
        );
      case 1:
        return DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedTestType,
            dropdownColor: colors.surface, // Dark blue dropdown
            style: TextStyle(color: Colors.white),
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
                decoration: InputDecoration(
                  hintText: 'MM',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white),
                ),
                keyboardType: TextInputType.number,
                style: GoogleFonts.nunito(color: Colors.white),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _dayController,
                decoration: InputDecoration(
                  hintText: 'DD',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white),
                ),
                keyboardType: TextInputType.number,
                style: GoogleFonts.nunito(color: Colors.white),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _yearController,
                decoration: InputDecoration(
                  hintText: 'YYYY',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white),
                ),
                keyboardType: TextInputType.number,
                style: GoogleFonts.nunito(color: Colors.white),
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
              activeColor: Color.fromARGB(255, 0, 208, 90), // Change active color to red
              inactiveColor: Colors.white, // Change inactive color to white
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
                Text('Very Easy', style: GoogleFonts.nunito(color: Colors.white, fontSize: 18)),
                Text('Very Hard', style: GoogleFonts.nunito(color: Colors.white, fontSize: 18)),
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
                decoration: InputDecoration(
                  hintText: 'Current Grade (%)',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white),
                ),
                keyboardType: TextInputType.number,
                style: GoogleFonts.nunito(color: Colors.white),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _targetGradeController,
                decoration: InputDecoration(
                  hintText: 'Target Grade (%)',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white),
                ),
                keyboardType: TextInputType.number,
                style: GoogleFonts.nunito(color: Colors.white),
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
        break; // Missing break to prevent fall-through
      case 'quiz':
        type = TestType.quiz;
        break; // Missing break to prevent fall-through
      case 'final':
        type = TestType.finals;
        break; // Missing break to prevent fall-through
    }

    TestDifficulty difficulty = TestDifficulty.normal;
    switch (_difficulty.toInt()) {
      case 0:
        difficulty = TestDifficulty.veryeasy;
        break; // Missing break to prevent fall-through
      case 1:
        difficulty = TestDifficulty.easy;
        break; // Missing break to prevent fall-through
      case 2:
        difficulty = TestDifficulty.normal;
        break; // Missing break to prevent fall-through
      case 3:
        difficulty = TestDifficulty.hard;
        break; // Missing break to prevent fall-through
      case 4:
        difficulty = TestDifficulty.veryhard;
        break; // Missing break to prevent fall-through
    }

    Test test = Test(
      _subjectController.text,
      DateTime(int.parse(_yearController.text), int.parse(_monthController.text), int.parse(_dayController.text)),
      type,
      difficulty,
      int.parse(_currentGradeController.text),
      int.parse(_targetGradeController.text),
    );

    globals.tests.add(test);
  }
}
