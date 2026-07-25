import 'package:latlong2/latlong.dart';

enum OrderStatus {
  searching,
  accepted,
  arrivedAtPickup,
  inTransit,
  arrivedAtDropoff,
  delivered,
  canceled,
  failed,
}

enum ItemSize { S, M, L }

enum ItemType { document, food, clothing, electronics, others }

enum VehicleType { bike, tuktuk }

enum PaymentMethod { cash, online }

enum DeliveryServiceType { express, warehouse }

class CustomerOrder {
  final String id;
  final LatLng pickup;
  final LatLng dropoff;
  final String pickupAddress;
  final String dropoffAddress;
  final String itemName;
  final String? itemDescription;
  final ItemSize size;
  final double weight;
  final ItemType itemType;
  final VehicleType vehicleType;
  final PaymentMethod paymentMethod;
  final DeliveryServiceType serviceType;
  final bool itemHandling;
  final bool driverPickup;
  OrderStatus status; // Now mutable for cancellation
  final DateTime createdAt;
  final DateTime? updatedAt;
  final double price;
  final String? dropoffContactName;
  final String? dropoffContactNumber;
  final String? noteToDriver;
  final String? driverName;
  final String? driverPhone;
  final bool? driverOnline;
  final int quantity;
  final List<LatLng> pickupRoutePoints;
  final List<LatLng> deliveryRoutePoints;
  final LatLng? driverStartLocation;
  final double simulationProgress;
  final int simulationDurationSeconds;
  final DateTime? simulationPhaseStartedAt;
  final String? pickupQrToken;
  final String? recipientTrackingToken;

  CustomerOrder({
    required this.id,
    required this.pickup,
    required this.dropoff,
    this.pickupAddress = "Current Location",
    this.dropoffAddress = "Destination",
    required this.itemName,
    this.itemDescription,
    this.size = ItemSize.S,
    this.weight = 0.0,
    this.itemType = ItemType.others,
    this.vehicleType = VehicleType.bike,
    this.paymentMethod = PaymentMethod.cash,
    this.serviceType = DeliveryServiceType.express,
    this.itemHandling = false,
    this.driverPickup = false,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    required this.price,
    this.dropoffContactName,
    this.dropoffContactNumber,
    this.noteToDriver,
    this.driverName,
    this.driverPhone,
    this.driverOnline,
    this.quantity = 1,
    this.pickupRoutePoints = const [],
    this.deliveryRoutePoints = const [],
    this.driverStartLocation,
    this.simulationProgress = 0,
    this.simulationDurationSeconds = 30,
    this.simulationPhaseStartedAt,
    this.pickupQrToken,
    this.recipientTrackingToken,
  });

  factory CustomerOrder.fromJson(Map<String, dynamic> json) {
    final created = json['createdAt'] != null
        ? DateTime.parse(json['createdAt'])
        : DateTime.now();
    return CustomerOrder(
      id: json['_id'] ?? json['id'] ?? '',
      pickup: LatLng(
        ((json['pickup'] ?? {})['latitude'] ?? 0.0).toDouble(),
        ((json['pickup'] ?? {})['longitude'] ?? 0.0).toDouble(),
      ),
      dropoff: LatLng(
        ((json['dropoff'] ?? {})['latitude'] ?? 0.0).toDouble(),
        ((json['dropoff'] ?? {})['longitude'] ?? 0.0).toDouble(),
      ),
      pickupAddress: (json['pickup'] ?? {})['address'] ?? '',
      dropoffAddress: (json['dropoff'] ?? {})['address'] ?? '',
      itemName: (json['package'] ?? {})['name'] ?? '',
      itemDescription: (json['package'] ?? {})['note'],
      size: ItemSize.S,
      weight: ((json['package'] ?? {})['weightKg'] ?? 0.0).toDouble(),
      itemType: _parseItemType((json['package'] ?? {})['type']),
      vehicleType: _parseVehicleType(json['vehicleType']),
      paymentMethod: _parsePaymentMethod((json['payment'] ?? {})['method']),
      serviceType: json['serviceType']?.toString().toUpperCase() == 'WAREHOUSE'
          ? DeliveryServiceType.warehouse
          : DeliveryServiceType.express,
      itemHandling: false,
      driverPickup: false,
      status: _parseStatus(json['status']),
      createdAt: created,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : created,
      price:
          ((json['payment'] ?? {})['amount'] ?? json['estimatedPrice'] ?? 0.0)
              .toDouble(),
      dropoffContactName: (json['dropoff'] ?? {})['contactName'],
      dropoffContactNumber: (json['dropoff'] ?? {})['phone'],
      noteToDriver: (json['package'] ?? {})['note'],
      driverName: (json['driverId'] ?? {})['name'],
      driverPhone: (json['driverId'] ?? {})['phone'],
      driverOnline:
          ((json['driverId'] ?? {})['driverProfile'] ?? {})['isOnline'],
      quantity: ((json['package'] ?? {})['quantity'] as num?)?.toInt() ?? 1,
      pickupRoutePoints: _parseRoutePoints(json['pickupRoutePoints']),
      deliveryRoutePoints: _parseRoutePoints(json['deliveryRoutePoints']),
      driverStartLocation: _parsePoint(json['driverStartLocation']),
      simulationProgress: (json['simulationProgress'] as num?)?.toDouble() ?? 0,
      simulationDurationSeconds:
          (json['simulationDurationSeconds'] as num?)?.toInt() ?? 30,
      simulationPhaseStartedAt: json['simulationPhaseStartedAt'] != null
          ? DateTime.tryParse(json['simulationPhaseStartedAt'].toString())
          : null,
      pickupQrToken: json['pickupQrToken']?.toString(),
      recipientTrackingToken: json['recipientTrackingToken']?.toString(),
    );
  }

  static ItemType _parseItemType(String? type) {
    switch (type?.toUpperCase()) {
      case 'DOCUMENT':
        return ItemType.document;
      case 'FOOD':
        return ItemType.food;
      case 'CLOTHING':
        return ItemType.clothing;
      case 'ELECTRONICS':
        return ItemType.electronics;
      default:
        return ItemType.others;
    }
  }

  static VehicleType _parseVehicleType(String? vehicle) {
    switch (vehicle?.toUpperCase()) {
      case 'RICKSHAW':
      case 'CAR':
      case 'TUKTUK':
        return VehicleType.tuktuk;
      default:
        return VehicleType.bike;
    }
  }

  static PaymentMethod _parsePaymentMethod(String? payment) {
    switch (payment?.toUpperCase()) {
      case 'ABA_QR':
      case 'ONLINE':
        return PaymentMethod.online;
      default:
        return PaymentMethod.cash;
    }
  }

  static OrderStatus _parseStatus(String? status) {
    if (status == null) return OrderStatus.searching;
    switch (status.toUpperCase()) {
      case 'PENDING':
      case 'SEARCHING':
        return OrderStatus.searching;
      case 'ACCEPTED':
        return OrderStatus.accepted;
      case 'ARRIVED_AT_PICKUP':
        return OrderStatus.arrivedAtPickup;
      case 'PICKED_UP':
      case 'IN_TRANSIT':
        return OrderStatus.inTransit;
      case 'ARRIVED_AT_DROPOFF':
        return OrderStatus.arrivedAtDropoff;
      case 'DELIVERED':
        return OrderStatus.delivered;
      case 'CANCELLED':
      case 'CANCELED':
        return OrderStatus.canceled;
      case 'FAILED':
        return OrderStatus.failed;
      default:
        return OrderStatus.searching;
    }
  }

  String get statusText {
    if (serviceType == DeliveryServiceType.warehouse) {
      switch (status) {
        case OrderStatus.searching:
          return "Waiting for drop-off at warehouse";
        case OrderStatus.accepted:
          return "Ready for drop-off";
        case OrderStatus.arrivedAtPickup:
          return "Driver is waiting for package handoff";
        case OrderStatus.inTransit:
          return "Item is in transit between warehouses";
        case OrderStatus.arrivedAtDropoff:
          return "Waiting for recipient confirmation";
        case OrderStatus.delivered:
          return "Ready for pick-up at destination";
        case OrderStatus.canceled:
          return "Order Canceled";
        case OrderStatus.failed:
          return "Delivery Failed";
      }
    }
    switch (status) {
      case OrderStatus.searching:
        return "Waiting for delivery man";
      case OrderStatus.accepted:
        return "Driver is coming to pickup";
      case OrderStatus.arrivedAtPickup:
        return "Driver arrived — show the pickup QR";
      case OrderStatus.inTransit:
        return "On the way to destination";
      case OrderStatus.arrivedAtDropoff:
        return "Driver arrived — recipient confirmation needed";
      case OrderStatus.delivered:
        return "Successfully delivered";
      case OrderStatus.canceled:
        return "Order Canceled";
      case OrderStatus.failed:
        return "Delivery Failed";
    }
  }

  String get typeText {
    switch (itemType) {
      case ItemType.document:
        return "Document";
      case ItemType.food:
        return "Food";
      case ItemType.clothing:
        return "Clothing";
      case ItemType.electronics:
        return "Electronics";
      case ItemType.others:
        return "Others";
    }
  }

  String get vehicleText {
    switch (vehicleType) {
      case VehicleType.bike:
        return "Bike (Small Items)";
      case VehicleType.tuktuk:
        return "Tuktuk (Large Items)";
    }
  }

  String get serviceName {
    switch (serviceType) {
      case DeliveryServiceType.express:
        return "Chonh Express";
      case DeliveryServiceType.warehouse:
        return "Warehouse-to-Warehouse";
    }
  }

  List<LatLng> get activeRoutePoints {
    switch (status) {
      case OrderStatus.accepted:
      case OrderStatus.arrivedAtPickup:
        return pickupRoutePoints;
      case OrderStatus.inTransit:
      case OrderStatus.arrivedAtDropoff:
      case OrderStatus.delivered:
        return deliveryRoutePoints;
      default:
        return deliveryRoutePoints;
    }
  }

  double get effectiveSimulationProgress {
    if (status == OrderStatus.arrivedAtPickup ||
        status == OrderStatus.arrivedAtDropoff ||
        status == OrderStatus.delivered) {
      return 1;
    }
    final startedAt = simulationPhaseStartedAt;
    if (startedAt == null ||
        (status != OrderStatus.accepted && status != OrderStatus.inTransit)) {
      return simulationProgress.clamp(0, 1);
    }
    final elapsed = DateTime.now().difference(startedAt).inMilliseconds / 1000;
    return (elapsed / simulationDurationSeconds)
        .clamp(simulationProgress, 1)
        .toDouble();
  }

  LatLng? get simulatedDriverLocation {
    final points = activeRoutePoints;
    if (points.isEmpty) return driverStartLocation;
    if (points.length == 1) return points.first;
    final progress = effectiveSimulationProgress;
    final scaled = progress * (points.length - 1);
    final lower = scaled.floor().clamp(0, points.length - 1);
    final upper = (lower + 1).clamp(0, points.length - 1);
    final fraction = scaled - lower;
    return LatLng(
      points[lower].latitude +
          (points[upper].latitude - points[lower].latitude) * fraction,
      points[lower].longitude +
          (points[upper].longitude - points[lower].longitude) * fraction,
    );
  }

  static List<LatLng> _parseRoutePoints(dynamic raw) {
    if (raw is! List) return const [];
    return raw.map(_parsePoint).whereType<LatLng>().toList();
  }

  static LatLng? _parsePoint(dynamic raw) {
    if (raw is! Map) return null;
    final latitude = raw['latitude'] as num?;
    final longitude = raw['longitude'] as num?;
    if (latitude == null || longitude == null) return null;
    return LatLng(latitude.toDouble(), longitude.toDouble());
  }
}
