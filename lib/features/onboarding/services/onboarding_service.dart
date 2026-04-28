import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/onboarding_model.dart';

class OnboardingService {
  static const String _baseUrl = 'http://192.168.204.194:3000/api/v1';

  /// GET /api/v1/onboarding
  /// Returns only active slides, sorted by order.
  Future<List<OnboardingSlide>> fetchSlides() async {
    final uri = Uri.parse('$_baseUrl/onboarding');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body) as List<dynamic>;
      return data
          .map((e) => OnboardingSlide.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw Exception('Failed to load onboarding slides (${response.statusCode})');
  }
}