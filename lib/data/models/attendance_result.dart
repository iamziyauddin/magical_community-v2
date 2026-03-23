class AttendanceRecordResult {
  final String userId;
  final String status; // 'success' | 'failed'
  final String? error;

  const AttendanceRecordResult({
    required this.userId,
    required this.status,
    this.error,
  });

  bool get isSuccess => status.toLowerCase() == 'success';

  factory AttendanceRecordResult.fromJson(Map<String, dynamic> json) {
    return AttendanceRecordResult(
      userId: json['userId']?.toString() ?? '',
      status: json['status']?.toString() ?? 'failed',
      error: json['error']?.toString(),
    );
  }
}

class AttendanceSubmitResult {
  final String attendanceDate; // yyyy-MM-dd
  final int totalRecords;
  final int successfulRecords;
  final int failedRecords;
  final List<AttendanceRecordResult> results;
  final String? message;

  const AttendanceSubmitResult({
    required this.attendanceDate,
    required this.totalRecords,
    required this.successfulRecords,
    required this.failedRecords,
    required this.results,
    this.message,
  });

  factory AttendanceSubmitResult.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map<String, dynamic>?) ?? json;
    return AttendanceSubmitResult(
      attendanceDate: data['attendanceDate']?.toString() ?? '',
      totalRecords: (data['totalRecords'] as num?)?.toInt() ?? 0,
      successfulRecords: (data['successfulRecords'] as num?)?.toInt() ?? 0,
      failedRecords: (data['failedRecords'] as num?)?.toInt() ?? 0,
      results: (data['results'] as List? ?? [])
          .map(
            (e) => AttendanceRecordResult.fromJson(
              (e as Map<String, dynamic>?) ?? const {},
            ),
          )
          .toList(),
      message: json['message']?.toString() ?? data['message']?.toString(),
    );
  }
}
