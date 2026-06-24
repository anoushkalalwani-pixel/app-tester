import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart'; // for Google Fonts

class UserChat extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<UserChat> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _responseTimer; // Timer reference to cancel later

  void _handleSubmitted(String text) {
    if (text.isEmpty) return; // Prevent sending empty messages
    _textController.clear();
    ChatMessage message = ChatMessage(
      text: text,
      isUser: true,
    );
    setState(() {
      _messages.insert(0, message);
    });
    _scrollToBottom();
    _simulateResponse();
  }

  void _simulateResponse() {
    _responseTimer = Timer(Duration(seconds: 2), () {
      if (mounted) { // Check if the widget is still mounted before calling setState
        ChatMessage aiMessage = ChatMessage(
          text: "What is the atomic number of chlorine (Cl)?",
          isUser: false,
        );
        setState(() {
          _messages.insert(0, aiMessage);
        });
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.minScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _responseTimer?.cancel(); // Cancel the timer if it's running
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'AI Chat',
          style: GoogleFonts.nunito(color: Colors.white), // white text
        ),
        backgroundColor: Color.fromARGB(255, 0, 37, 68), // dark blue app bar
      ),
      body: Container(
        color: Colors.lightBlue[100], // light blue background
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                reverse: true,
                controller: _scrollController,
                itemCount: _messages.length,
                itemBuilder: (context, index) => _messages[index],
              ),
            ),
            Divider(height: 1.0),
            Container(
              decoration: BoxDecoration(color: Theme.of(context).cardColor),
              child: _buildTextComposer(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextComposer() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30.0),
                boxShadow: [
                  BoxShadow(
                    offset: Offset(0, 3),
                    blurRadius: 5,
                    color: const Color.fromARGB(255, 93, 93, 93).withOpacity(0.3),
                  )
                ],
              ),
              child: Row(
                children: [
                  SizedBox(width: 20),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      onSubmitted: _handleSubmitted,
                      decoration: InputDecoration(
                        hintText: "Send a message",
                        hintStyle: TextStyle(color: Color.fromARGB(255, 93, 93, 93)), // hint color
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send),
                    onPressed: () => _handleSubmitted(_textController.text),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser)
            CircleAvatar(child: Text('AI')),
          Container(
            decoration: BoxDecoration(
              color: isUser ? Color.fromARGB(255, 0, 37, 68) : Color.fromARGB(255, 93, 93, 93), // dark blue for user messages
              borderRadius: BorderRadius.circular(20.0), // more curved boxes
            ),
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            margin: EdgeInsets.only(left: 8.0, right: 8.0),
            child: Text(
              text,
              style: GoogleFonts.nunito(color: Colors.white), // white text
            ),
          ),
          if (isUser)
            CircleAvatar(child: Text('You')),
        ],
      ),
    );
  }
}
