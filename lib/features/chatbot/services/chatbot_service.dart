import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../global/base_url.dart';

class ChatbotService {
  String get _url => chatbotBaseUrl;

  static const _headers = {'Content-Type': 'application/json'};

  Future<String> ask(
    String question, {
    String? userId,
    String? sessionId,
  }) async {
    final res = await http
        .post(
          Uri.parse('$_url/ask'),
          headers: _headers,
          body: json.encode({
            'question': question,
            if (userId != null && userId.isNotEmpty) 'user_id': userId,
            if (sessionId != null && sessionId.isNotEmpty)
              'session_id': sessionId,
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

  Future<void> resetSession(String sessionId) async {
    if (sessionId.isEmpty) return;
    try {
      await http
          .post(
            Uri.parse('$_url/session/reset'),
            headers: _headers,
            body: json.encode({'session_id': sessionId}),
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {}
  }
}
