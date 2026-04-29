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
  final bool itemHandling;
  OrderStatus status; // Now mutable for cancellation
  final DateTime createdAt;
  final double price;

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
    this.itemHandling = false,
    required this.status,
    required this.createdAt,
    required this.price,
  });

  String get statusText {
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
}
