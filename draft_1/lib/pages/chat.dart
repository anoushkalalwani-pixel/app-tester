import 'package:flutter/material.dart';
import 'dart:async';
import 'package:draft_1/theme/app_theme.dart';

class UserChat extends StatefulWidget {
  const UserChat({super.key});

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
    final colors = context.colors;
    return Scaffold(
      appBar: AppBar(title: const Text('AI Chat')),
      body: Container(
        color: colors.background,
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
            const Divider(height: 1.0),
            _buildTextComposer(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextComposer() {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                boxShadow: [
                  BoxShadow(
                    offset: const Offset(0, 3),
                    blurRadius: 5,
                    color: colors.neutral.withValues(alpha: 0.3),
                  )
                ],
              ),
              child: Row(
                children: [
                  const HGap(AppSpacing.xl),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      onSubmitted: _handleSubmitted,
                      style: context.text.bodyLarge
                          ?.copyWith(color: colors.onSurface),
                      decoration: InputDecoration(
                        hintText: "Send a message",
                        hintStyle: TextStyle(color: colors.onSurface),
                        filled: false,
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send, color: colors.onSurface),
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

  const ChatMessage({super.key, required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) const CircleAvatar(child: Text('AI')),
          Container(
            decoration: BoxDecoration(
              color: isUser ? colors.surface : colors.neutral,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text(
              text,
              style: context.text.bodyLarge?.copyWith(color: colors.onSurface),
            ),
          ),
          if (isUser) const CircleAvatar(child: Text('You')),
        ],
      ),
    );
  }
}
