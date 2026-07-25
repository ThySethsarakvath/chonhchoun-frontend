import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/onboarding_model.dart';
import '../../global/base_url.dart';

class OnboardingService {
  String get _url => baseUrl;

  /// GET /api/v1/onboarding
  /// Returns only active slides, sorted by order.
  Future<List<OnboardingSlide>> fetchSlides() async {
    final uri = Uri.parse('$_url/onboarding');
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