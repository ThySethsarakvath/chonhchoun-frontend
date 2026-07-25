class RevenueSharingConfig {
  final String id;
  final int version;
  final int senderBranchPercent;
  final int receiverBranchPercent;
  final int companyPercent;
  final bool isActive;
  final String? note;
  final DateTime? createdAt;

  const RevenueSharingConfig({
    required this.id,
    required this.version,
    required this.senderBranchPercent,
    required this.receiverBranchPercent,
    required this.companyPercent,
    required this.isActive,
    this.note,
    this.createdAt,
  });

  factory RevenueSharingConfig.fromJson(Map<String, dynamic> json) {
    return RevenueSharingConfig(
      id: json['_id'] as String? ?? '',
      version: json['version'] as int? ?? 1,
      senderBranchPercent: json['senderBranchPercent'] as int? ?? 0,
      receiverBranchPercent: json['receiverBranchPercent'] as int? ?? 0,
      companyPercent: json['companyPercent'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? false,
      note: json['note'] as String?,
      createdAt: json['createdAt'] is String
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }
}
