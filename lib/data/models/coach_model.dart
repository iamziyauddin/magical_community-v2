import 'attendance_summary.dart';

class Coach {
  final String userId;
  final String firstName;
  final String lastName;
  final String? email;
  final String? phoneNumber;
  final String? address;
  final String? disease;
  final String role;
  final String memberRole;
  final bool isActive;
  final String? membershipStatus;
  final DateTime? membershipStartDate;
  final DateTime? membershipEndDate;
  final double totalPayable;
  final double totalPaid;
  final double dueAmount;
  final String membershipType;
  final AttendanceSummary? attendanceSummary;

  Coach({
    required this.userId,
    required this.firstName,
    required this.lastName,
    this.email,
    this.phoneNumber,
    this.address,
    this.disease,
    required this.role,
    required this.memberRole,
    required this.isActive,
    this.membershipStatus,
    this.membershipStartDate,
    this.membershipEndDate,
    this.totalPayable = 0.0,
    this.totalPaid = 0.0,
    this.dueAmount = 0.0,
    this.membershipType = 'membership',
    this.attendanceSummary,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory Coach.fromJson(Map<String, dynamic> json) {
    DateTime? _parseDate(dynamic v) {
      if (v == null) return null;
      return DateTime.tryParse(v.toString());
    }

    double _toDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    return Coach(
      userId: (json['userId'] ?? json['id'] ?? '').toString(),
      firstName: (json['firstName'] ?? '').toString(),
      lastName: (json['lastName'] ?? '').toString(),
      email: json['email']?.toString(),
      phoneNumber: (json['phoneNumber'] ?? json['mobileNumber'])?.toString(),
      address: json['address']?.toString(),
      disease: json['disease']?.toString(),
      role: (json['role'] ?? 'member').toString(),
      memberRole: (json['memberRole'] ?? '').toString(),
      isActive: (json['isActive'] is bool) ? json['isActive'] as bool : true,
      membershipStatus: json['membershipStatus']?.toString(),
      membershipStartDate: _parseDate(json['membershipStartDate']),
      membershipEndDate: _parseDate(json['membershipEndDate']),
      totalPayable: _toDouble(json['totalPayable']),
      totalPaid: _toDouble(json['totalPaid']),
      dueAmount: _toDouble(json['dueAmount']),
      membershipType: (json['membershipType'] ?? 'membership').toString(),
      attendanceSummary: json['attendanceSummary'] is Map
          ? AttendanceSummary.fromJson(
              (json['attendanceSummary'] as Map).cast<String, dynamic>(),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phoneNumber': phoneNumber,
      'address': address,
      'disease': disease,
      'role': role,
      'memberRole': memberRole,
      'isActive': isActive,
      'membershipStatus': membershipStatus,
      'membershipStartDate': membershipStartDate?.toIso8601String(),
      'membershipEndDate': membershipEndDate?.toIso8601String(),
      'totalPayable': totalPayable,
      'totalPaid': totalPaid,
      'dueAmount': dueAmount,
      'membershipType': membershipType,
      if (attendanceSummary != null)
        'attendanceSummary': {
          'present': attendanceSummary!.present,
          'absent': attendanceSummary!.absent,
          'total': attendanceSummary!.total,
        },
    };
  }

  // Computed properties for UI
  bool get hasDues => dueAmount > 0;
  bool get isSenior =>
      memberRole == 'seniorCoach' || memberRole == 'senior_coach';
}

class CoachesMeta {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  CoachesMeta({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory CoachesMeta.fromJson(Map<String, dynamic> json) {
    return CoachesMeta(
      page: json['meta']?['page'] ?? json['page'] ?? 1,
      limit: json['meta']?['limit'] ?? json['limit'] ?? 20,
      total: json['meta']?['total'] ?? json['total'] ?? 0,
      totalPages: json['meta']?['totalPages'] ?? json['totalPages'] ?? 1,
    );
  }
}

class CoachesData {
  final List<Coach> coaches;
  final CoachesMeta? meta;

  CoachesData({required this.coaches, this.meta});

  factory CoachesData.fromJson(Map<String, dynamic> json) {
    return CoachesData(
      coaches:
          (json['data'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map((item) => Coach.fromJson(item))
              .toList() ??
          [],
      meta: json['meta'] != null
          ? CoachesMeta.fromJson({'meta': json['meta']})
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'coaches': coaches.map((coach) => coach.toJson()).toList(),
      if (meta != null)
        'meta': {
          'page': meta!.page,
          'limit': meta!.limit,
          'total': meta!.total,
          'totalPages': meta!.totalPages,
        },
    };
  }
}

class CoachesResponse {
  final bool success;
  final String message;
  final CoachesData data;
  final String timestamp;

  CoachesResponse({
    required this.success,
    required this.message,
    required this.data,
    required this.timestamp,
  });

  factory CoachesResponse.fromJson(Map<String, dynamic> json) {
    return CoachesResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: CoachesData.fromJson(json['data'] ?? {}),
      timestamp: json['timestamp'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data.toJson(),
      'timestamp': timestamp,
    };
  }
}
