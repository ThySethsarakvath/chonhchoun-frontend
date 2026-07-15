import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../global/base_url.dart';
import '../../auth/tokens/token_storage.dart';
import '../models/dispatch_receipt_models.dart';

class DispatchReceiptService {
  String get _baseApi => '$baseUrl/dispatch-receipts';

  Future<Map<String, String>> _getHeaders() async {
    final token = await TokenStorage.getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<DispatchReceipt> createReceipt(CreateDispatchReceiptDto dto) async {
    final res = await http.post(
      Uri.parse(_baseApi),
      headers: await _getHeaders(),
      body: json.encode(dto.toJson()),
    );

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return DispatchReceipt.fromJson(json.decode(res.body));
    } else {
      throw Exception('Failed to create dispatch receipt: ${res.body}');
    }
  }

  Future<List<DispatchReceipt>> listOutboundReceipts({
    String? status,
    String? dateFrom,
    String? dateTo,
  }) async {
    final queryParams = <String, String>{};
    if (status != null) queryParams['status'] = status;
    if (dateFrom != null) queryParams['dateFrom'] = dateFrom;
    if (dateTo != null) queryParams['dateTo'] = dateTo;

    final uri = Uri.parse(_baseApi).replace(queryParameters: queryParams);
    final res = await http.get(uri, headers: await _getHeaders());

    if (res.statusCode == 200) {
      final List<dynamic> data = json.decode(res.body);
      return data.map((e) => DispatchReceipt.fromJson(e)).toList();
    } else {
      throw Exception('Failed to fetch outbound receipts: ${res.body}');
    }
  }

  Future<List<DispatchReceipt>> listInboundReceipts({
    String? status,
    String? dateFrom,
    String? dateTo,
  }) async {
    final queryParams = <String, String>{};
    if (status != null) queryParams['status'] = status;
    if (dateFrom != null) queryParams['dateFrom'] = dateFrom;
    if (dateTo != null) queryParams['dateTo'] = dateTo;

    final uri = Uri.parse('$_baseApi/inbound').replace(queryParameters: queryParams);
    final res = await http.get(uri, headers: await _getHeaders());

    if (res.statusCode == 200) {
      final List<dynamic> data = json.decode(res.body);
      return data.map((e) => DispatchReceipt.fromJson(e)).toList();
    } else {
      throw Exception('Failed to fetch inbound receipts: ${res.body}');
    }
  }

  Future<DispatchReceipt> getReceipt(String id) async {
    final res = await http.get(
      Uri.parse('$_baseApi/$id'),
      headers: await _getHeaders(),
    );

    if (res.statusCode == 200) {
      return DispatchReceipt.fromJson(json.decode(res.body));
    } else {
      throw Exception('Failed to get receipt details: ${res.body}');
    }
  }

  Future<DispatchReceipt> departReceipt(String id) async {
    final res = await http.patch(
      Uri.parse('$_baseApi/$id/depart'),
      headers: await _getHeaders(),
    );

    if (res.statusCode == 200) {
      return DispatchReceipt.fromJson(json.decode(res.body));
    } else {
      throw Exception('Failed to depart receipt: ${res.body}');
    }
  }

  Future<DispatchReceipt> cancelReceipt(String id) async {
    final res = await http.patch(
      Uri.parse('$_baseApi/$id/cancel'),
      headers: await _getHeaders(),
    );

    if (res.statusCode == 200) {
      return DispatchReceipt.fromJson(json.decode(res.body));
    } else {
      throw Exception('Failed to cancel receipt: ${res.body}');
    }
  }

  Future<DispatchReceipt> simulateArrival(String id, int stopOrder) async {
    final res = await http.post(
      Uri.parse('$_baseApi/$id/stops/$stopOrder/simulate-arrival'),
      headers: await _getHeaders(),
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      return DispatchReceipt.fromJson(json.decode(res.body));
    } else {
      throw Exception('Failed to simulate arrival: ${res.body}');
    }
  }

  Future<DispatchReceipt> confirmStop(
      String id, int stopOrder, ConfirmStopReceiptDto dto) async {
    final res = await http.patch(
      Uri.parse('$_baseApi/$id/stops/$stopOrder/confirm'),
      headers: await _getHeaders(),
      body: json.encode(dto.toJson()),
    );

    if (res.statusCode == 200) {
      return DispatchReceipt.fromJson(json.decode(res.body));
    } else {
      throw Exception('Failed to confirm stop: ${res.body}');
    }
  }
}
