import 'package:latlong2/latlong.dart';

enum OrderStatus {
  searching,
  accepted,
  pickedUp,
  delivered,
  canceled,
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
  final double price;
  final String? dropoffContactName;
  final String? dropoffContactNumber;
  final String? noteToDriver;

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
    required this.price,
    this.dropoffContactName,
    this.dropoffContactNumber,
    this.noteToDriver,
  });

  factory CustomerOrder.fromJson(Map<String, dynamic> json) {
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
      serviceType: DeliveryServiceType.express,
      itemHandling: false,
      driverPickup: false,
      status: _parseStatus(json['status']),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      price: ((json['payment'] ?? {})['amount'] ?? json['estimatedPrice'] ?? 0.0).toDouble(),
      dropoffContactName: (json['dropoff'] ?? {})['contactName'],
      dropoffContactNumber: (json['dropoff'] ?? {})['phone'],
      noteToDriver: (json['package'] ?? {})['note'],
    );
  }

  static ItemSize _parseSize(String? size) {
    switch (size) {
      case 'S': return ItemSize.S;
      case 'M': return ItemSize.M;
      case 'L': return ItemSize.L;
      default: return ItemSize.S;
    }
  }

  static ItemType _parseItemType(String? type) {
    switch (type) {
      case 'document': return ItemType.document;
      case 'food': return ItemType.food;
      case 'clothing': return ItemType.clothing;
      case 'electronics': return ItemType.electronics;
      default: return ItemType.others;
    }
  }

  static VehicleType _parseVehicleType(String? vehicle) {
    switch (vehicle) {
      case 'bike': return VehicleType.bike;
      case 'tuktuk': return VehicleType.tuktuk;
      default: return VehicleType.bike;
    }
  }

  static PaymentMethod _parsePaymentMethod(String? payment) {
    switch (payment) {
      case 'cash': return PaymentMethod.cash;
      case 'online': return PaymentMethod.online;
      default: return PaymentMethod.cash;
    }
  }

  static DeliveryServiceType _parseServiceType(String? service) {
    switch (service) {
      case 'express': return DeliveryServiceType.express;
      case 'warehouse': return DeliveryServiceType.warehouse;
      default: return DeliveryServiceType.express;
    }
  }

  static OrderStatus _parseStatus(String? status) {
    switch (status) {
      case 'searching': return OrderStatus.searching;
      case 'accepted': return OrderStatus.accepted;
      case 'pickedUp': return OrderStatus.pickedUp;
      case 'delivered': return OrderStatus.delivered;
      case 'canceled': return OrderStatus.canceled;
      default: return OrderStatus.searching;
    }
  }

  String get statusText {
    if (serviceType == DeliveryServiceType.warehouse) {
      switch (status) {
        case OrderStatus.searching:
          return "Waiting for drop-off at warehouse";
        case OrderStatus.accepted:
          return "Ready for drop-off";
        case OrderStatus.pickedUp:
          return "Item is in transit between warehouses";
        case OrderStatus.delivered:
          return "Ready for pick-up at destination";
        case OrderStatus.canceled:
          return "Order Canceled";
      }
    }
    switch (status) {
      case OrderStatus.searching:
        return "Waiting for delivery man";
      case OrderStatus.accepted:
        return "Driver is coming to pickup";
      case OrderStatus.pickedUp:
        return "On the way to destination";
      case OrderStatus.delivered:
        return "Successfully delivered";
      case OrderStatus.canceled:
        return "Order Canceled";
    }
  }

  String get typeText {
    switch (itemType) {
      case ItemType.document: return "Document";
      case ItemType.food: return "Food";
      case ItemType.clothing: return "Clothing";
      case ItemType.electronics: return "Electronics";
      case ItemType.others: return "Others";
    }
  }

  String get vehicleText {
    switch (vehicleType) {
      case VehicleType.bike: return "Bike (Small Items)";
      case VehicleType.tuktuk: return "Tuktuk (Large Items)";
    }
  }

  String get serviceName {
    switch (serviceType) {
      case DeliveryServiceType.express: return "Chonh Express";
      case DeliveryServiceType.warehouse: return "Warehouse-to-Warehouse";
    }
  }
}
