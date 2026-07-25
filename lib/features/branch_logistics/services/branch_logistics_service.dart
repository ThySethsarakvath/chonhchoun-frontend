import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../global/base_url.dart';
import '../../auth/models/user_model.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/tokens/token_storage.dart';
import '../models/branch_logistics_models.dart';

class BranchLogisticsService {
  String get _baseApi => '$baseUrl/branch-logistics';

  Future<Map<String, String>> _getHeaders() async {
    final token = await TokenStorage.getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<BranchLogisticsPriceQuote> calculatePrice({
    required String receiverBranchId,
    required String senderName,
    required String senderPhone,
    required String receiverName,
    required String receiverPhone,
    required String itemDescription,
    required BranchLogisticsPricingMode pricingMode,
    String? senderUserId,
    String? receiverUserId,
    double? weightKg,
    double? lengthCm,
    double? widthCm,
    double? heightCm,
    double? extraFee,
    double? discount,
    String? notes,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseApi/shipments/calculate-price'),
      headers: await _getHeaders(),
      body: json.encode(_buildPayload(
        receiverBranchId: receiverBranchId,
        senderName: senderName,
        senderPhone: senderPhone,
        receiverName: receiverName,
        receiverPhone: receiverPhone,
        itemDescription: itemDescription,
        pricingMode: pricingMode,
        senderUserId: senderUserId,
        receiverUserId: receiverUserId,
        weightKg: weightKg,
        lengthCm: lengthCm,
        widthCm: widthCm,
        heightCm: heightCm,
        extraFee: extraFee,
        discount: discount,
        notes: notes,
      )),
    );

    final body = json.decode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 201 || res.statusCode == 200) {
      return BranchLogisticsPriceQuote.fromJson(body);
    }

    throw ApiException(_messageFromBody(body, 'Failed to calculate price'), res.statusCode);
  }

  Future<BranchLogisticsShipment> createShipment({
    required String receiverBranchId,
    required String senderName,
    required String senderPhone,
    required String receiverName,
    required String receiverPhone,
    required String itemDescription,
    required BranchLogisticsPricingMode pricingMode,
    String? senderUserId,
    String? receiverUserId,
    double? weightKg,
    double? lengthCm,
    double? widthCm,
    double? heightCm,
    double? extraFee,
    double? discount,
    String? notes,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseApi/shipments'),
      headers: await _getHeaders(),
      body: json.encode(_buildPayload(
        receiverBranchId: receiverBranchId,
        senderName: senderName,
        senderPhone: senderPhone,
        receiverName: receiverName,
        receiverPhone: receiverPhone,
        itemDescription: itemDescription,
        pricingMode: pricingMode,
        senderUserId: senderUserId,
        receiverUserId: receiverUserId,
        weightKg: weightKg,
        lengthCm: lengthCm,
        widthCm: widthCm,
        heightCm: heightCm,
        extraFee: extraFee,
        discount: discount,
        notes: notes,
      )),
    );

    final body = json.decode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 201 || res.statusCode == 200) {
      return BranchLogisticsShipment.fromJson(body);
    }

    throw ApiException(_messageFromBody(body, 'Failed to create shipment'), res.statusCode);
  }

  Future<List<BranchLogisticsShipment>> assignTripToDriver({
    required List<String> shipmentIds,
    required String driverId,
    String? notes,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseApi/shipments/assign-trip'),
      headers: await _getHeaders(),
      body: json.encode({
        'shipmentIds': shipmentIds,
        'driverId': driverId,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      }),
    );

    final body = json.decode(res.body);
    if ((res.statusCode == 201 || res.statusCode == 200) && body is List) {
      return body
          .map(
            (item) => BranchLogisticsShipment.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList();
    }

    throw ApiException(
      body is Map<String, dynamic>
          ? _messageFromBody(body, 'Failed to assign trip')
          : 'Failed to assign trip',
      res.statusCode,
    );
  }

  Future<List<BranchLogisticsShipment>> listShipments({
    String direction = 'all',
    String? status,
    String? ticketNumber,
  }) async {
    final query = <String, String>{'direction': direction};
    if (status != null && status.trim().isNotEmpty) {
      query['status'] = status.trim();
    }
    if (ticketNumber != null && ticketNumber.trim().isNotEmpty) {
      query['ticketNumber'] = ticketNumber.trim();
    }

    final uri = Uri.parse('$_baseApi/shipments').replace(queryParameters: query);
    final res = await http.get(uri, headers: await _getHeaders());
    final body = json.decode(res.body);

    if (res.statusCode == 200 && body is List) {
      return body
          .map((item) => BranchLogisticsShipment.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    throw ApiException('Failed to load shipments', res.statusCode);
  }

  Future<List<BranchLogisticsShipment>> listCustomerShipments() async {
    final res = await http.get(
      Uri.parse('$_baseApi/customer/shipments'),
      headers: await _getHeaders(),
    );
    final body = json.decode(res.body);

    if (res.statusCode == 200 && body is List) {
      return body
          .map(
            (item) => BranchLogisticsShipment.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList();
    }

    throw ApiException('Failed to load customer shipments', res.statusCode);
  }

  Future<List<BranchLogisticsShipment>> listDriverAssignedShipments() async {
    final res = await http.get(
      Uri.parse('$_baseApi/driver/assigned-shipments'),
      headers: await _getHeaders(),
    );
    final body = json.decode(res.body);

    if (res.statusCode == 200 && body is List) {
      return body
          .map(
            (item) => BranchLogisticsShipment.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList();
    }

    throw ApiException(
      'Failed to load assigned driver shipments',
      res.statusCode,
    );
  }

  Future<List<UserProfile>> listTicketUsers({String? search}) async {
    final query = <String, String>{};
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }

    final uri = Uri.parse('$_baseApi/ticket-users').replace(
      queryParameters: query.isEmpty ? null : query,
    );
    final res = await http.get(uri, headers: await _getHeaders());
    final body = json.decode(res.body);

    if (res.statusCode == 200 && body is List) {
      return body
          .map((item) => UserProfile.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    throw ApiException('Failed to load ticket users', res.statusCode);
  }

  Future<BranchLogisticsShipment> updateShipmentStatus({
    required String shipmentId,
    required String action,
    String? notes,
  }) async {
    final res = await http.patch(
      Uri.parse('$_baseApi/shipments/$shipmentId/$action'),
      headers: await _getHeaders(),
      body: json.encode({
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      }),
    );

    final body = json.decode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 200) {
      final shipmentJson = body['shipment'] is Map<String, dynamic>
          ? body['shipment'] as Map<String, dynamic>
          : body;
      return BranchLogisticsShipment.fromJson(shipmentJson);
    }

    throw ApiException(
      _messageFromBody(body, 'Failed to update shipment status'),
      res.statusCode,
    );
  }

  Future<BranchLogisticsShipment> updateDriverShipmentStatus({
    required String shipmentId,
    required String action,
    String? notes,
  }) async {
    final res = await http.patch(
      Uri.parse('$_baseApi/driver/shipments/$shipmentId/$action'),
      headers: await _getHeaders(),
      body: json.encode({
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      }),
    );

    final body = json.decode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 200) {
      final shipmentJson = body['shipment'] is Map<String, dynamic>
          ? body['shipment'] as Map<String, dynamic>
          : body;
      return BranchLogisticsShipment.fromJson(shipmentJson);
    }

    throw ApiException(
      _messageFromBody(body, 'Failed to update driver shipment status'),
      res.statusCode,
    );
  }

  Map<String, dynamic> _buildPayload({
    required String receiverBranchId,
    required String senderName,
    required String senderPhone,
    required String receiverName,
    required String receiverPhone,
    required String itemDescription,
    required BranchLogisticsPricingMode pricingMode,
    String? senderUserId,
    String? receiverUserId,
    double? weightKg,
    double? lengthCm,
    double? widthCm,
    double? heightCm,
    double? extraFee,
    double? discount,
    String? notes,
  }) {
    return {
      'receiverBranchId': receiverBranchId,
      'senderName': senderName.trim(),
      'senderPhone': senderPhone.trim(),
      'receiverName': receiverName.trim(),
      'receiverPhone': receiverPhone.trim(),
      'itemDescription': itemDescription.trim(),
      'pricingMode': pricingMode.apiValue,
      if (senderUserId != null && senderUserId.trim().isNotEmpty)
        'senderUserId': senderUserId.trim(),
      if (receiverUserId != null && receiverUserId.trim().isNotEmpty)
        'receiverUserId': receiverUserId.trim(),
      if (weightKg != null) 'weightKg': weightKg,
      if (lengthCm != null) 'lengthCm': lengthCm,
      if (widthCm != null) 'widthCm': widthCm,
      if (heightCm != null) 'heightCm': heightCm,
      if (extraFee != null) 'extraFee': extraFee,
      if (discount != null) 'discount': discount,
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
    };
  }

  String _messageFromBody(Map<String, dynamic> body, String fallback) {
    final message = body['message'];
    if (message is List) return message.join(', ');
    return message as String? ?? fallback;
  }
}
