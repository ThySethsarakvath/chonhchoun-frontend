import 'package:flutter/material.dart';

class DriverDayEarning {
  const DriverDayEarning({
    required this.label,
    required this.amount,
    required this.deliveries,
  });

  final String label;
  final double amount;
  final int deliveries;

  factory DriverDayEarning.fromJson(Map<String, dynamic> json) {
    return DriverDayEarning(
      label: (json['day'] ?? json['label'] ?? '').toString(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      deliveries: (json['deliveries'] as num?)?.toInt() ?? 0,
    );
  }
}

class DriverTransaction {
  const DriverTransaction({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.time,
    required this.icon,
    required this.isPayout,
  });

  final String title;
  final String subtitle;
  final double amount;
  final String time;
  final IconData icon;
  final bool isPayout;

  factory DriverTransaction.fromJson(Map<String, dynamic> json) {
    final kind = (json['kind'] ?? '').toString();
    final isPayout = json['isPayout'] == true || kind == 'payout';
    return DriverTransaction(
      title: (json['title'] ?? '').toString(),
      subtitle: (json['subtitle'] ?? '').toString(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      time: (json['time'] ?? '').toString(),
      icon: _iconForKind(kind, isPayout),
      isPayout: isPayout,
    );
  }

  static IconData _iconForKind(String kind, bool isPayout) {
    if (isPayout) return Icons.account_balance_wallet_rounded;
    switch (kind) {
      case 'bonus':
        return Icons.bolt_rounded;
      case 'delivery':
      default:
        return Icons.local_shipping_rounded;
    }
  }
}

class DriverEarningsSummary {
  const DriverEarningsSummary({
    required this.availableBalance,
    required this.totalEarnings,
    required this.completedDeliveries,
    required this.rating,
    required this.onlineSeconds,
    required this.activeAssigned,
    required this.weekly,
    required this.transactions,
  });

  final double availableBalance;
  final double totalEarnings;
  final int completedDeliveries;
  final double rating;
  final int onlineSeconds;
  final int activeAssigned;
  final List<DriverDayEarning> weekly;
  final List<DriverTransaction> transactions;

  String get onlineLabel {
    final hours = onlineSeconds ~/ 3600;
    final minutes = (onlineSeconds % 3600) ~/ 60;
    return '${hours}h ${minutes}m';
  }

  factory DriverEarningsSummary.fromJson(Map<String, dynamic> json) {
    final weekly = (json['weekly'] as List<dynamic>? ?? [])
        .map((e) => DriverDayEarning.fromJson(e as Map<String, dynamic>))
        .toList();
    final transactions = (json['transactions'] as List<dynamic>? ?? [])
        .map((e) => DriverTransaction.fromJson(e as Map<String, dynamic>))
        .toList();
    return DriverEarningsSummary(
      availableBalance: (json['availableBalance'] as num?)?.toDouble() ?? 0,
      totalEarnings: (json['totalEarnings'] as num?)?.toDouble() ?? 0,
      completedDeliveries: (json['completedDeliveries'] as num?)?.toInt() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      onlineSeconds: (json['onlineSeconds'] as num?)?.toInt() ?? 0,
      activeAssigned: (json['activeAssigned'] as num?)?.toInt() ?? 0,
      weekly: weekly,
      transactions: transactions,
    );
  }
}

enum DriverEarningsRange { week, month, all }

extension DriverEarningsRangeLabel on DriverEarningsRange {
  String get label {
    switch (this) {
      case DriverEarningsRange.week:
        return 'This week';
      case DriverEarningsRange.month:
        return 'This month';
      case DriverEarningsRange.all:
        return 'All time';
    }
  }
}
