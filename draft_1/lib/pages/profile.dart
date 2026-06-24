import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // for Google Fonts
import 'package:flutter/cupertino.dart'; // for Cupertino Icons
import 'package:draft_1/homepage.dart'; // assuming homepage is imported

class UserProfile extends StatefulWidget {
  @override
  _UserProfileFormState createState() => _UserProfileFormState();
}

class _UserProfileFormState extends State<UserProfile> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _gradeController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue[100], // light blue background
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 0, 37, 68), // dark blue app bar
        title: Text(
          'User Profile',
          style: GoogleFonts.nunito( // Source Code Pro font for title
            color: Colors.white,
            fontSize: 24.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(CupertinoIcons.pencil, color: Colors.white), // Pencil icon
            onPressed: () {
              // Handle edit logic
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildTextField('First Name', _firstNameController),
              SizedBox(height: 16),
              _buildTextField('Last Name', _lastNameController),
              SizedBox(height: 16),
              _buildTextField('Grade', _gradeController, isNumeric: true),
              SizedBox(height: 16),
              _buildTextField('Email', _emailController, isEmail: true),
              SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                        context, MaterialPageRoute(builder: (context) => HomePage()));
                  },
                  child: Text('Save'),
                  style: ElevatedButton.styleFrom(
                    textStyle: GoogleFonts.nunito( // Source Code Pro font for button
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool isNumeric = false, bool isEmail = false}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.nunito(color: Colors.white), // white label text
        filled: true,
        fillColor: Color.fromARGB(255, 0, 37, 68), // dark blue background for the text field
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), // rounded corners
        ),
        suffixIcon: IconButton(
          icon: Icon(CupertinoIcons.pencil, color: Colors.white), // white pencil icon
          onPressed: () {
            // handle edit
          },
        ),
      ),
      style: GoogleFonts.nunito(color: Colors.white), // white input text
      keyboardType: isNumeric ? TextInputType.number : (isEmail ? TextInputType.emailAddress : TextInputType.text),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your $label';
        }
        if (isNumeric && int.tryParse(value) == null) {
          return 'Please enter a valid number';
        }
        if (isEmail &&
            !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return 'Please enter a valid email address';
        }
        return null;
      },
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _gradeController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
