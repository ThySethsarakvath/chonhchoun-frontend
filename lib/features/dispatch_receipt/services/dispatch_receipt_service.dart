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

  Future<AutoPlanDispatchResult> autoPlan({
    int simulationDurationSeconds = 120,
    int timeLimitSeconds = 30,
    String? notes,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseApi/auto-plan'),
      headers: await _getHeaders(),
      body: json.encode({
        'simulationDurationSeconds': simulationDurationSeconds,
        'timeLimitSeconds': timeLimitSeconds,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      }),
    );

    final body = json.decode(res.body);
    if (res.statusCode >= 200 &&
        res.statusCode < 300 &&
        body is Map<String, dynamic>) {
      return AutoPlanDispatchResult.fromJson(body);
    }
    throw Exception(_message(body, 'Failed to optimize dispatch receipts'));
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

    final uri = Uri.parse(
      '$_baseApi/inbound',
    ).replace(queryParameters: queryParams);
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

  Future<DispatchReceipt> startSimulation(String id) async {
    final res = await http.post(
      Uri.parse('$_baseApi/$id/simulation/start'),
      headers: await _getHeaders(),
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      return DispatchReceipt.fromJson(json.decode(res.body));
    }
    throw Exception(
      _message(json.decode(res.body), 'Failed to start route simulation'),
    );
  }

  Future<DispatchReceipt> syncSimulation(String id) async {
    final res = await http.post(
      Uri.parse('$_baseApi/$id/simulation/sync'),
      headers: await _getHeaders(),
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      return DispatchReceipt.fromJson(json.decode(res.body));
    }
    throw Exception(
      _message(json.decode(res.body), 'Failed to synchronize simulation'),
    );
  }

  Future<DispatchReceipt> confirmStop(
    String id,
    int stopOrder,
    ConfirmStopReceiptDto dto,
  ) async {
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

  String _message(dynamic body, String fallback) {
    if (body is Map<String, dynamic>) {
      final message = body['message'];
      if (message is List) return message.join(', ');
      if (message is String) return message;
    }
    return fallback;
  }
}
