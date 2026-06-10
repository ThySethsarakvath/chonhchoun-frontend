import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../global/base_url.dart';

/// Talks to the standalone FastAPI RAG chatbot (`POST /ask`).
class ChatbotService {
  String get _url => chatbotBaseUrl;

  static const _headers = {'Content-Type': 'application/json'};

  /// Sends [question] (optionally scoped to [userId]) and returns the answer.
  Future<String> ask(String question, {String? userId}) async {
    final res = await http
        .post(
          Uri.parse('$_url/ask'),
          headers: _headers,
          body: json.encode({
            'question': question,
            if (userId != null && userId.isNotEmpty) 'user_id': userId,
          }),
        )
        .timeout(const Duration(seconds: 60));

    if (res.statusCode == 200) {
      final data = json.decode(res.body) as Map<String, dynamic>;
      return (data['answer'] as String?)?.trim().isNotEmpty == true
          ? (data['answer'] as String).trim()
          : 'Sorry, I don\'t have an answer for that.';
    }

    throw Exception('Chatbot error (${res.statusCode})');
  }
}
