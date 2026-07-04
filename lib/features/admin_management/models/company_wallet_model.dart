class CompanyWalletSummary {
  final String walletKey;
  final double availableBalance;
  final double pendingBalance;
  final double totalCredited;
  final double totalDebited;
  final double netBalance;
  final String currency;

  const CompanyWalletSummary({
    required this.walletKey,
    required this.availableBalance,
    required this.pendingBalance,
    required this.totalCredited,
    required this.totalDebited,
    required this.netBalance,
    required this.currency,
  });

  factory CompanyWalletSummary.fromJson(Map<String, dynamic> json) {
    double numberValue(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    return CompanyWalletSummary(
      walletKey: json['walletKey'] as String? ?? '',
      availableBalance: numberValue(json['availableBalance']),
      pendingBalance: numberValue(json['pendingBalance']),
      totalCredited: numberValue(json['totalCredited']),
      totalDebited: numberValue(json['totalDebited']),
      netBalance: numberValue(json['netBalance']),
      currency: json['currency'] as String? ?? 'USD',
    );
  }
}

class CompanyWalletTransaction {
  final String id;
  final String type;
  final String status;
  final String source;
  final double amount;
  final String description;
  final String? ticketNumber;
  final String? revenueShareRole;
  final int? revenueSharePercent;
  final double? totalPrice;
  final String? senderName;
  final String? senderPhone;
  final String? receiverName;
  final String? receiverPhone;
  final DateTime? createdAt;

  const CompanyWalletTransaction({
    required this.id,
    required this.type,
    required this.status,
    required this.source,
    required this.amount,
    required this.description,
    required this.ticketNumber,
    required this.revenueShareRole,
    required this.revenueSharePercent,
    required this.totalPrice,
    required this.senderName,
    required this.senderPhone,
    required this.receiverName,
    required this.receiverPhone,
    required this.createdAt,
  });

  factory CompanyWalletTransaction.fromJson(Map<String, dynamic> json) {
    double numberValue(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    final metadata = json['metadata'] as Map<String, dynamic>?;
    final senderUser = metadata?['senderUser'] as Map<String, dynamic>?;
    final receiverUser = metadata?['receiverUser'] as Map<String, dynamic>?;

    return CompanyWalletTransaction(
      id: json['_id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      status: json['status'] as String? ?? '',
      source: json['source'] as String? ?? '',
      amount: numberValue(json['amount']),
      description: json['description'] as String? ?? '',
      ticketNumber: json['ticketNumber'] as String?,
      revenueShareRole: metadata?['revenueShareRole'] as String?,
      revenueSharePercent: metadata?['revenueSharePercent'] as int?,
      totalPrice: metadata?['totalPrice'] is num
          ? (metadata!['totalPrice'] as num).toDouble()
          : double.tryParse(metadata?['totalPrice']?.toString() ?? ''),
      senderName: senderUser?['name'] as String?,
      senderPhone: senderUser?['phone'] as String?,
      receiverName: receiverUser?['name'] as String?,
      receiverPhone: receiverUser?['phone'] as String?,
      createdAt: json['createdAt'] is String
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }
}
