import 'dart:convert';
import 'package:frontend/core/network/app_api_base_url.dart';
import 'package:http/http.dart' as http;
import '../models/onboarding_model.dart';


class OnboardingService {
  String get _url => appApiBaseUrl;

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