class SubscriptionSummary {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? planName;
  final double totalPayable;
  final double totalPaid;
  final double dueAmount;
  final String membershipType; // e.g., 'membership' or 'trial'
  final String? subscriptionPlanId; // New field for upcoming subscriptions
  final bool? isTrial; // New field for upcoming subscriptions

  SubscriptionSummary({
    this.startDate,
    this.endDate,
    this.planName,
    required this.totalPayable,
    required this.totalPaid,
    required this.dueAmount,
    required this.membershipType,
    this.subscriptionPlanId,
    this.isTrial,
  });

  factory SubscriptionSummary.fromJson(Map<String, dynamic> json) {
    DateTime? _parseDate(dynamic v) {
      if (v == null) return null;
      return DateTime.tryParse(v.toString());
    }

    double _toDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    return SubscriptionSummary(
      startDate: _parseDate(json['startDate']),
      endDate: _parseDate(json['endDate']),
      planName: json['planName']?.toString(),
      totalPayable: _toDouble(json['totalPayable']),
      totalPaid: _toDouble(json['totalPaid']),
      dueAmount: _toDouble(json['dueAmount']),
      membershipType: (json['membershipType'] ?? '').toString(),
      subscriptionPlanId: json['subscriptionPlanId']?.toString(),
      isTrial: json['isTrial'] as bool?,
    );
  }
}
