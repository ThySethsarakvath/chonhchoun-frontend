class DriverPackage {
  const DriverPackage({
    required this.id,
    required this.trackingNumber,
    required this.status,
    required this.itemName,
    required this.recipient,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.paymentMethod,
    required this.amount,
    required this.vehicleType,
  });

  final String id;
  final String trackingNumber;
  final String status;
  final String itemName;
  final String recipient;
  final String? pickupAddress;
  final String? dropoffAddress;
  final String? paymentMethod;
  final num? amount;
  final String? vehicleType;

  bool get isActive => !const {
        'DELIVERED',
        'delivered',
        'CANCELLED',
        'canceled',
        'FAILED',
      }.contains(status);

  String get statusLabel => status
      .replaceAll('_', ' ')
      .split(' ')
      .where((w) => w.isNotEmpty)
      .map((w) => '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
      .join(' ');

  factory DriverPackage.fromJson(Map<String, dynamic> json) {
    final package = json['package'] as Map<String, dynamic>?;
    final pickup = json['pickup'] as Map<String, dynamic>?;
    final dropoff = json['dropoff'] as Map<String, dynamic>?;
    final payment = json['payment'] as Map<String, dynamic>?;
    final customer = json['customerId'] is Map<String, dynamic>
        ? json['customerId'] as Map<String, dynamic>
        : null;

    return DriverPackage(
      id: (json['_id'] ?? '').toString(),
      trackingNumber: (json['trackingNumber'] ?? '').toString(),
      status: (json['status'] ?? 'unknown').toString(),
      itemName: (package?['name'] ?? 'Package').toString(),
      recipient: (dropoff?['contactName'] ?? customer?['name'] ?? 'Recipient')
          .toString(),
      pickupAddress: pickup?['address']?.toString(),
      dropoffAddress: dropoff?['address']?.toString(),
      paymentMethod: payment?['method']?.toString(),
      amount: payment?['amount'] as num? ?? json['estimatedPrice'] as num?,
      vehicleType: json['vehicleType']?.toString(),
    );
  }
}
