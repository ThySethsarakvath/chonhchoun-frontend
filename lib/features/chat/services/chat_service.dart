import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../global/base_url.dart';
import '../models/chat_message.dart';

/// REST calls for delivery chat (history). Live messages go over the socket.
class ChatService {
  Future<List<ChatMessage>> getHistory(String packageId, String token) async {
    final res = await http.get(
      Uri.parse('$baseUrl/chat/$packageId/messages'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode == 200) {
      final list = json.decode(res.body) as List<dynamic>;
      return list
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('មិនអាចផ្ទុកប្រវត្តិសន្ទនាបានទេ (${res.statusCode})');
  }
}
