class DashboardStats {
  final int todayTrialCount;
  final int todayCoachCount;
  final int todaySeniorCoachCount;
  final int todayMemberCount;
  final int todayVisitorCount;
  final int todayNewMemberCount;
  final int todayPresentCount;
  final int todayAbsentCount;
  final int todayTotalTrackedMembers;
  final int todayTrialShakeCount;
  final int todayMemberShakeCount;
  final int todayTotalShakeCount;
  final int
  totalUMS; // Total UMS (Members + Coaches + Senior Coaches) provided directly by API
  final DateTime? date;

  DashboardStats({
    required this.todayTrialCount,
    required this.todayCoachCount,
    required this.todaySeniorCoachCount,
    required this.todayMemberCount,
    required this.todayVisitorCount,
    required this.todayNewMemberCount,
    required this.todayPresentCount,
    required this.todayAbsentCount,
    required this.todayTotalTrackedMembers,
    required this.todayTrialShakeCount,
    required this.todayMemberShakeCount,
    required this.todayTotalShakeCount,
    required this.totalUMS,
    required this.date,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    final dateStr = json['date']?.toString();
    if (dateStr != null && dateStr.isNotEmpty) {
      parsedDate = DateTime.tryParse(dateStr);
    }
    int _toInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    return DashboardStats(
      todayTrialCount: _toInt(json['todayTrialCount']),
      todayCoachCount: _toInt(json['todayCoachCount']),
      todaySeniorCoachCount: _toInt(json['todaySeniorCoachCount']),
      todayMemberCount: _toInt(json['todayMemberCount']),
      todayVisitorCount: _toInt(json['todayVisitorCount']),
      todayNewMemberCount: _toInt(json['todayNewMemberCount']),
      todayPresentCount: _toInt(json['todayPresentCount']),
      todayAbsentCount: _toInt(json['todayAbsentCount']),
      todayTotalTrackedMembers: _toInt(json['todayTotalTrackedMembers']),
      todayTrialShakeCount: _toInt(json['todayTrialShakeCount']),
      todayMemberShakeCount: _toInt(json['todayMemberShakeCount']),
      todayTotalShakeCount: _toInt(json['todayTotalShakeCount']),
      totalUMS: _toInt(json['totalUMS']),
      date: parsedDate,
    );
  }
}
