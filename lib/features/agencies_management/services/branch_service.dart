import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../global/base_url.dart';
import '../../auth/services/auth_service.dart'; 
import '../../auth/tokens/token_storage.dart';
import '../models/branch_model.dart';

class BranchService {
  String get _url => '$baseUrl/agencies-management/branches';

  Future<Map<String, String>> _getHeaders() async {
    final token = await TokenStorage.getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<Branch>> getAllBranches() async {
    final res = await http.get(Uri.parse(_url), headers: await _getHeaders());
    if (res.statusCode == 200) {
      final List data = json.decode(res.body);
      return data.map((json) => Branch.fromJson(json)).toList();
    }
    throw ApiException('មិនអាចទាញយកទិន្នន័យសាខាបានទេ', res.statusCode);
  }

  Future<Branch> createBranch(Map<String, dynamic> payload) async {
    final res = await http.post(
      Uri.parse(_url),
      headers: await _getHeaders(),
      body: json.encode(payload),
    );
    if (res.statusCode == 201) {
      return Branch.fromJson(json.decode(res.body));
    }
    throw ApiException('ការបង្កើតសាខាមិនបានជោគជ័យ', res.statusCode);
  }
}