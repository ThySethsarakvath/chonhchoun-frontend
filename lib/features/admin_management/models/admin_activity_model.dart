class AdminActivity {
  final String id;
  final String action;
  final String actorName;
  final String? targetUserName;
  final String? branchName;
  final int? branchNumber;
  final String? details;
  final DateTime? createdAt;

  const AdminActivity({
    required this.id,
    required this.action,
    required this.actorName,
    this.targetUserName,
    this.branchName,
    this.branchNumber,
    this.details,
    this.createdAt,
  });

  factory AdminActivity.fromJson(Map<String, dynamic> json) {
    return AdminActivity(
      id: json['_id'] as String,
      action: json['action'] as String? ?? '',
      actorName: json['actorName'] as String? ?? 'Admin',
      targetUserName: json['targetUserName'] as String?,
      branchName: json['branchName'] as String?,
      branchNumber: json['branchNumber'] as int?,
      details: json['details'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.tryParse(json['createdAt'] as String),
    );
  }
}
