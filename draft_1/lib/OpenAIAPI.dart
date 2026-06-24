import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
}