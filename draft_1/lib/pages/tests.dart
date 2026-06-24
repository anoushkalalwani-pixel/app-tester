import 'package:flutter/material.dart';
import 'package:draft_1/globals.dart' as globals;
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class UserTests extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tests', style: GoogleFonts.nunito(color: Colors.white)),
        backgroundColor: Color.fromARGB(255, 0, 37, 68), // Darker blue for app bar
      ),
      body: Container(
        color: Colors.lightBlue[100], // Light blue background
        child: Center(
          child: ListView.builder(
            itemCount: globals.tests.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text(globals.tests[index].subject, style: GoogleFonts.nunito()),
                          content: Text(
                            'Date: ${DateFormat('yyyy-MM-dd').format(globals.tests[index].testDate)}\n'
                            'Type: ${globals.tests[index].testType.toString().split('.').last}\n'
                            'Difficulty: ${globals.tests[index].testDifficulty.toString().split('.').last}',
                            style: GoogleFonts.nunito(),
                          ),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Text('Back', style: GoogleFonts.nunito()),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color.fromARGB(255, 0, 37, 68), // Dark blue for test boxes
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            globals.tests[index].subject,
                            style: GoogleFonts.nunito(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Date: ${DateFormat('yyyy-MM-dd').format(globals.tests[index].testDate)}',
                            style: GoogleFonts.nunito(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Type: ${globals.tests[index].testType.toString().split('.').last}',
                            style: GoogleFonts.nunito(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Difficulty: ${globals.tests[index].testDifficulty.toString().split('.').last}',
                            style: GoogleFonts.nunito(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
