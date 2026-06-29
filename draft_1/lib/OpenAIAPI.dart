import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:draft_1/model.dart';
import 'package:draft_1/study_coach.dart';

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

  /// Asks the AI provider which subjects the user should review next, given a
  /// per-subject summary of their study history and upcoming tests.
  ///
  /// Each returned [Recommendation] is grounded in the supplied [insights]:
  /// recommendations naming a subject not present in the input are dropped so a
  /// hallucinated subject never reaches the UI. The model is told to weigh weak
  /// performance, infrequent/stale review, and imminent tests.
  ///
  /// Returns an empty list if there is nothing to analyse. Throws if the key is
  /// missing, the request fails, or the response can't be parsed — callers
  /// should catch and fall back to [StudyCoach.localRecommendations].
  Future<List<Recommendation>> generateStudyRecommendations(
    List<SubjectInsight> insights,
  ) async {
    if (insights.isEmpty) return const [];

    const String jformat = '''{
      "recommendations": [
        {
          "subject": "An exact subject name from the input data",
          "priority": "high | medium | low",
          "reason": "One sentence, grounded in the data, on why to review it now",
          "action": "One concrete, specific next study action"
        }
      ]
    }''';

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };

    final subjects = jsonEncode({
      'subjects': [for (final insight in insights) insight.toJson()],
    });

    final body = jsonEncode({
      'model': 'gpt-4o-mini',
      'response_format': {'type': 'json_object'},
      'messages': [
        {
          'role': 'system',
          'content':
              'You are a personalized study coach. You receive a JSON list of '
                  'the student\'s subjects. For each subject: "sessions" (logged '
                  'study sessions), "totalMinutes", "cardsReviewed", '
                  '"accuracyPercent" (null if never studied), '
                  '"daysSinceLastStudied" (null if never studied; larger means '
                  'more neglected) and "daysUntilNextTest" (null if none; '
                  'smaller means more urgent). Recommend which subjects to '
                  'review next, ordered most-urgent first. Weigh three factors: '
                  'weak performance (low accuracy), infrequent or stale review '
                  '(large daysSinceLastStudied, or never studied) and imminent '
                  'tests (small daysUntilNextTest). Only reference subjects '
                  'present in the input — never invent subjects. Give each a '
                  'priority of high, medium or low, a one-sentence reason '
                  'grounded in the data, and one concrete next action. Respond '
                  'with valid JSON using this format: $jformat'
        },
        {'role': 'user', 'content': subjects}
      ],
      'max_tokens': 800,
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
    final rawRecs = (parsed['recommendations'] as List?) ?? const [];

    // Only surface subjects we actually have insights for, mapping back to the
    // canonical display spelling.
    final known = {
      for (final insight in insights) insight.subject.toLowerCase(): insight.subject,
    };

    final recommendations = <Recommendation>[];
    for (final item in rawRecs.whereType<Map<String, dynamic>>()) {
      final rawSubject = (item['subject'] ?? '').toString().trim();
      final subject = known[rawSubject.toLowerCase()];
      if (subject == null) continue;

      final reason = (item['reason'] ?? '').toString().trim();
      final action = (item['action'] ?? '').toString().trim();
      recommendations.add(Recommendation(
        subject: subject,
        priority: Recommendation.priorityFromString(item['priority']?.toString()),
        reason: reason.isEmpty ? 'Recommended for review.' : reason,
        suggestedAction:
            action.isEmpty ? 'Schedule a focused review session.' : action,
        aiGenerated: true,
      ));
    }
    return recommendations;
  }
}