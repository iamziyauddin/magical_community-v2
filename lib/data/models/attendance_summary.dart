class AttendanceSummary {
  final int present;
  final int absent;
  final int total;

  const AttendanceSummary({
    required this.present,
    required this.absent,
    required this.total,
  });

  double get rate => total > 0 ? present / total : 0.0;

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) {
    int _toInt(dynamic v) {
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    return AttendanceSummary(
      present: _toInt(json['present']),
      absent: _toInt(json['absent']),
      total: _toInt(json['total']),
    );
  }
}
