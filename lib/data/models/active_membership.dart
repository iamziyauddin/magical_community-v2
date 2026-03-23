class ActiveMembership {
  final DateTime startDate;
  final DateTime endDate;
  final double totalPayable;
  final double totalPaid;
  final double dueAmount;
  final String membershipType; // e.g. membership / trial / visitor
  final String status; // e.g. active / expired
  final String?
  subscriptionPlanId; // newly captured from API (activeMembership.subscriptionPlanId)
  // New shake-related fields coming from API (optional -> default to 0 when absent)
  final int? totalShake;
  final int? totalDueShake;
  final int? totalConsumedShake;

  ActiveMembership({
    required this.startDate,
    required this.endDate,
    required this.totalPayable,
    required this.totalPaid,
    required this.dueAmount,
    required this.membershipType,
    required this.status,
    this.subscriptionPlanId,
    this.totalShake,
    this.totalDueShake,
    this.totalConsumedShake,
  });

  factory ActiveMembership.fromJson(Map<String, dynamic> json) {
    DateTime _parseDate(dynamic v) =>
        DateTime.tryParse(v.toString()) ?? DateTime.now();
    double _toDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    int? _toIntNullable(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String && v.trim().isNotEmpty) {
        return int.tryParse(v.trim());
      }
      return null;
    }

    // Parse raw values (nullable) then keep nulls or values; UI/model layer will fallback to 0
    final totalShake = _toIntNullable(json['totalShake']);
    final totalDueShake = _toIntNullable(json['totalDueShake']);
    final totalConsumedShake = _toIntNullable(json['totalConsumedShake']);

    return ActiveMembership(
      startDate: _parseDate(
        json['membershipStartDate'] ?? json['startDate'] ?? '',
      ),
      endDate: _parseDate(json['membershipEndDate'] ?? json['endDate'] ?? ''),
      totalPayable: _toDouble(json['totalPayable']),
      totalPaid: _toDouble(json['totalPaid']),
      dueAmount: _toDouble(json['dueAmount']),
      membershipType: (json['membershipType'] ?? '').toString(),
      status: (json['membershipStatus'] ?? json['status'] ?? '').toString(),
      subscriptionPlanId: (json['subscriptionPlanId'] ?? '').toString().isEmpty
          ? null
          : json['subscriptionPlanId'].toString(),
      totalShake: totalShake,
      totalDueShake: totalDueShake,
      totalConsumedShake: totalConsumedShake,
    );
  }
}
