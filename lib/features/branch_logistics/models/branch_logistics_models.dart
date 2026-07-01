enum BranchLogisticsPricingMode {
  standard('STANDARD'),
  vip('VIP');

  const BranchLogisticsPricingMode(this.apiValue);

  final String apiValue;

  String get label {
    switch (this) {
      case BranchLogisticsPricingMode.standard:
        return 'Standard Service';
      case BranchLogisticsPricingMode.vip:
        return 'VIP Service';
    }
  }

  String get deliveryCommitment {
    switch (this) {
      case BranchLogisticsPricingMode.standard:
        return 'Delivery within 1-3 days';
      case BranchLogisticsPricingMode.vip:
        return 'Same-day delivery';
    }
  }

  static BranchLogisticsPricingMode fromApi(String? value) {
    return BranchLogisticsPricingMode.values.firstWhere(
      (mode) => mode.apiValue == value,
      orElse: () => BranchLogisticsPricingMode.standard,
    );
  }
}

class BranchLogisticsBranchRef {
  final String id;
  final String name;
  final int? branchNumber;
  final String? code;
  final String? address;
  final String? description;
  final String? ownerName;
  final String? ownerPhone;

  const BranchLogisticsBranchRef({
    required this.id,
    required this.name,
    this.branchNumber,
    this.code,
    this.address,
    this.description,
    this.ownerName,
    this.ownerPhone,
  });

  factory BranchLogisticsBranchRef.fromJson(Map<String, dynamic> json) {
    final owner = json['ownerId'];
    return BranchLogisticsBranchRef(
      id: json['_id'] as String? ?? '',
      name: json['name'] as String? ?? '-',
      branchNumber: json['branchNumber'] as int?,
      code: json['code'] as String?,
      address: json['address'] as String?,
      description: json['description'] as String?,
      ownerName: owner is Map<String, dynamic> ? owner['name'] as String? : null,
      ownerPhone: owner is Map<String, dynamic> ? owner['phone'] as String? : null,
    );
  }

  String get displayName {
    final parts = <String>[name];
    if (branchNumber != null) {
      parts.add('Branch #$branchNumber');
    }
    if (code != null && code!.trim().isNotEmpty) {
      parts.add(code!.trim());
    }
    return parts.join(' | ');
  }

  String get operationLabel {
    final label = address?.trim();
    if (label != null && label.isNotEmpty) {
      return label;
    }
    return displayName;
  }
}

class BranchLogisticsPartyInfo {
  final String name;
  final String phone;

  const BranchLogisticsPartyInfo({
    required this.name,
    required this.phone,
  });

  factory BranchLogisticsPartyInfo.fromJson(Map<String, dynamic> json) {
    return BranchLogisticsPartyInfo(
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
    );
  }
}

class BranchLogisticsAssignedDriverRef {
  final String id;
  final String name;
  final String? phone;
  final String? availabilityStatus;
  final double? maxLoadWeightKg;
  final int? maxPackageCount;

  const BranchLogisticsAssignedDriverRef({
    required this.id,
    required this.name,
    this.phone,
    this.availabilityStatus,
    this.maxLoadWeightKg,
    this.maxPackageCount,
  });

  factory BranchLogisticsAssignedDriverRef.fromJson(Map<String, dynamic> json) {
    double? numberValue(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    return BranchLogisticsAssignedDriverRef(
      id: json['_id'] as String? ?? '',
      name: json['name'] as String? ?? '-',
      phone: json['phone'] as String?,
      availabilityStatus: json['availabilityStatus'] as String?,
      maxLoadWeightKg: numberValue(json['maxLoadWeightKg']),
      maxPackageCount: json['maxPackageCount'] as int?,
    );
  }
}

class BranchLogisticsAssignedVehicleRef {
  final String id;
  final String code;
  final String? plateNumber;
  final String? type;
  final double? maxWeightKg;
  final int? maxPackageCount;
  final String? status;
  final bool isActive;

  const BranchLogisticsAssignedVehicleRef({
    required this.id,
    required this.code,
    this.plateNumber,
    this.type,
    this.maxWeightKg,
    this.maxPackageCount,
    this.status,
    required this.isActive,
  });

  factory BranchLogisticsAssignedVehicleRef.fromJson(
    Map<String, dynamic> json,
  ) {
    double? numberValue(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    return BranchLogisticsAssignedVehicleRef(
      id: json['_id'] as String? ?? '',
      code: json['code'] as String? ?? '-',
      plateNumber: json['plateNumber'] as String?,
      type: json['type'] as String?,
      maxWeightKg: numberValue(json['maxWeightKg']),
      maxPackageCount: json['maxPackageCount'] as int?,
      status: json['status'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

class BranchLogisticsPriceQuote {
  final BranchLogisticsPricingMode pricingMode;
  final double volumeM3;
  final double chargeableWeightKg;
  final double unitPrice;
  final double startingFee;
  final double chargeableFee;
  final double routeFee;
  final double serviceFee;
  final double basePrice;
  final double extraFee;
  final double discount;
  final double totalPrice;
  final String currency;

  const BranchLogisticsPriceQuote({
    required this.pricingMode,
    required this.volumeM3,
    required this.chargeableWeightKg,
    required this.unitPrice,
    required this.startingFee,
    required this.chargeableFee,
    required this.routeFee,
    required this.serviceFee,
    required this.basePrice,
    required this.extraFee,
    required this.discount,
    required this.totalPrice,
    required this.currency,
  });

  factory BranchLogisticsPriceQuote.fromJson(Map<String, dynamic> json) {
    double numberValue(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    return BranchLogisticsPriceQuote(
      pricingMode: BranchLogisticsPricingMode.fromApi(
        json['pricingMode'] as String?,
      ),
      volumeM3: numberValue(json['volumeM3']),
      chargeableWeightKg: numberValue(json['chargeableWeightKg']),
      unitPrice: numberValue(json['unitPrice']),
      startingFee: numberValue(json['startingFee']),
      chargeableFee: numberValue(json['chargeableFee']),
      routeFee: numberValue(json['routeFee']),
      serviceFee: numberValue(json['serviceFee']),
      basePrice: numberValue(json['basePrice']),
      extraFee: numberValue(json['extraFee']),
      discount: numberValue(json['discount']),
      totalPrice: numberValue(json['totalPrice']),
      currency: json['currency'] as String? ?? 'USD',
    );
  }
}

class BranchLogisticsShipment {
  final String id;
  final String ticketNumber;
  final String status;
  final BranchLogisticsPricingMode pricingMode;
  final BranchLogisticsPartyInfo sender;
  final BranchLogisticsPartyInfo receiver;
  final String itemDescription;
  final double? weightKg;
  final double? lengthCm;
  final double? widthCm;
  final double? heightCm;
  final double? volumeM3;
  final double? chargeableWeightKg;
  final double? unitPrice;
  final double startingFee;
  final double chargeableFee;
  final double routeFee;
  final double serviceFee;
  final double basePrice;
  final double extraFee;
  final double discount;
  final double totalPrice;
  final String currency;
  final String paymentStatus;
  final double amountPaid;
  final DateTime? paidAt;
  final String? notes;
  final DateTime? createdAt;
  final BranchLogisticsBranchRef? senderBranch;
  final BranchLogisticsBranchRef? receiverBranch;
  final BranchLogisticsAssignedDriverRef? assignedDriver;
  final BranchLogisticsAssignedVehicleRef? assignedVehicle;
  final DateTime? assignedAt;

  const BranchLogisticsShipment({
    required this.id,
    required this.ticketNumber,
    required this.status,
    required this.pricingMode,
    required this.sender,
    required this.receiver,
    required this.itemDescription,
    required this.weightKg,
    required this.lengthCm,
    required this.widthCm,
    required this.heightCm,
    required this.volumeM3,
    required this.chargeableWeightKg,
    required this.unitPrice,
    required this.startingFee,
    required this.chargeableFee,
    required this.routeFee,
    required this.serviceFee,
    required this.basePrice,
    required this.extraFee,
    required this.discount,
    required this.totalPrice,
    required this.currency,
    required this.paymentStatus,
    required this.amountPaid,
    required this.paidAt,
    required this.notes,
    required this.createdAt,
    required this.senderBranch,
    required this.receiverBranch,
    required this.assignedDriver,
    required this.assignedVehicle,
    required this.assignedAt,
  });

  factory BranchLogisticsShipment.fromJson(Map<String, dynamic> json) {
    double? numberValue(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    BranchLogisticsBranchRef? branchRef(dynamic value) {
      if (value is Map<String, dynamic>) {
        return BranchLogisticsBranchRef.fromJson(value);
      }
      return null;
    }

    return BranchLogisticsShipment(
      id: json['_id'] as String? ?? '',
      ticketNumber: json['ticketNumber'] as String? ?? '-',
      status: json['status'] as String? ?? 'CREATED',
      pricingMode: BranchLogisticsPricingMode.fromApi(
        json['pricingMode'] as String?,
      ),
      sender: BranchLogisticsPartyInfo.fromJson(
        (json['sender'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      ),
      receiver: BranchLogisticsPartyInfo.fromJson(
        (json['receiver'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      ),
      itemDescription: json['itemDescription'] as String? ?? '',
      weightKg: numberValue(json['weightKg']),
      lengthCm: numberValue(json['lengthCm']),
      widthCm: numberValue(json['widthCm']),
      heightCm: numberValue(json['heightCm']),
      volumeM3: numberValue(json['volumeM3']),
      chargeableWeightKg: numberValue(json['chargeableWeightKg']),
      unitPrice: numberValue(json['unitPrice']),
      startingFee: numberValue(json['startingFee']) ?? 0,
      chargeableFee: numberValue(json['chargeableFee']) ?? 0,
      routeFee: numberValue(json['routeFee']) ?? 0,
      serviceFee: numberValue(json['serviceFee']) ?? 0,
      basePrice: numberValue(json['basePrice']) ?? 0,
      extraFee: numberValue(json['extraFee']) ?? 0,
      discount: numberValue(json['discount']) ?? 0,
      totalPrice: numberValue(json['totalPrice']) ?? 0,
      currency: json['currency'] as String? ?? 'USD',
      paymentStatus: json['paymentStatus'] as String? ?? 'PAID',
      amountPaid: numberValue(json['amountPaid']) ?? 0,
      paidAt: json['paidAt'] is String
          ? DateTime.tryParse(json['paidAt'] as String)
          : null,
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] is String
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      senderBranch: branchRef(json['senderBranchId']),
      receiverBranch: branchRef(json['receiverBranchId']),
      assignedDriver: json['assignedDriverId'] is Map<String, dynamic>
          ? BranchLogisticsAssignedDriverRef.fromJson(
              json['assignedDriverId'] as Map<String, dynamic>,
            )
          : null,
      assignedVehicle: json['assignedVehicleId'] is Map<String, dynamic>
          ? BranchLogisticsAssignedVehicleRef.fromJson(
              json['assignedVehicleId'] as Map<String, dynamic>,
            )
          : null,
      assignedAt: json['assignedAt'] is String
          ? DateTime.tryParse(json['assignedAt'] as String)
          : null,
    );
  }

  bool belongsToBranch(String branchId) {
    return senderBranch?.id == branchId || receiverBranch?.id == branchId;
  }

  bool isOutboundFor(String branchId) => senderBranch?.id == branchId;

  bool isInboundFor(String branchId) => receiverBranch?.id == branchId;
}
