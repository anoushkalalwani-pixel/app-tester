import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:draft_1/model.dart';

class OpenAIAPI {
  final String apiUrl = 'https://api.openai.com/v1/chat/completions';

  String get apiKey {
    final key = dotenv.env['OPENAI_API_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception("OPENAI_API_KEY is missing in .env file");
    }
    return key;
  }

  Future<Map<String, dynamic>> generateCompletion(
      String prompt, int maxTokens) async {

    const String jformat = '''{
      "study_plan": [
        {
          "date": "2020-01-01",
          "task": "This is the task"
        }
      ]
    }''';

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };

    final body = jsonEncode({
      'model': 'gpt-4o-mini',
      'response_format': {'type': 'json_object'},
      'messages': [
        {
          'role': 'system',
          'content': 'Provide output in valid JSON using this format $jformat'
        },
        {'role': 'user', 'content': prompt}
      ],
      'max_tokens': maxTokens,
    });

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: headers,
      body: body,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
        "Request failed with status: ${response.statusCode}\n${response.body}",
      );
    }
  }

  /// Turns a block of free-form [notes] into study flashcards using the AI
  /// provider. Asks for up to [count] question/answer pairs and returns them
  /// parsed into [Flashcard]s, ready to be reviewed before saving.
  ///
  /// Throws if the key is missing, the request fails, or the response can't be
  /// parsed — callers should surface the error to the user.
  Future<List<Flashcard>> generateFlashcards(
    String notes, {
    int count = 10,
  }) async {
    const String jformat = '''{
      "flashcards": [
        {
          "question": "A concise question that tests one concept",
          "answer": "A short, direct answer"
        }
      ]
    }''';

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };

    final body = jsonEncode({
      'model': 'gpt-4o-mini',
      'response_format': {'type': 'json_object'},
      'messages': [
        {
          'role': 'system',
          'content':
              'You are a study assistant that turns a student\'s notes into '
                  'flashcards. Create at most $count flashcards. Each should '
                  'test a single concept with a concise question and a short '
                  'answer. Do not invent facts that are not supported by the '
                  'notes. Respond with valid JSON using this format: $jformat'
        },
        {'role': 'user', 'content': notes}
      ],
      'max_tokens': 1500,
    });

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: headers,
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception(
        "Request failed with status: ${response.statusCode}\n${response.body}",
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final content =
        data['choices']?[0]?['message']?['content'] as String? ?? '';
    final parsed = jsonDecode(content) as Map<String, dynamic>;
    final rawCards = (parsed['flashcards'] as List?) ?? const [];

    return rawCards
        .whereType<Map<String, dynamic>>()
        .map(Flashcard.fromJson)
        .where((card) => card.question.isNotEmpty && card.answer.isNotEmpty)
        .toList();
  }
}