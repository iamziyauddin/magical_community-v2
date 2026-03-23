import 'subscription_summary.dart';
import 'attendance_summary.dart';
import 'active_membership.dart';
import '../../models/user_model.dart'; // For UpcomingSubscription class

class Member {
  final String userId;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String role;
  final String memberRole;
  final bool isActive;
  final String membershipStatus; // new from trial API
  final DateTime membershipStartDate;
  final DateTime membershipEndDate;
  final double totalPayable;
  final double totalPaid;
  final double dueAmount;
  final String membershipType;
  final String? address;
  final String? disease;
  final SubscriptionSummary? subscription; // present for visitors if subscribed
  final UpcomingSubscription?
  upcomingSubscription; // present for visitors with upcoming membership
  final AttendanceSummary? attendanceSummary; // present in updated response
  final String? referredByName; // full name from referBy object when present
  final String? referredById; // referralId from referBy object when present
  final ActiveMembership? activeMembership; // new active membership snapshot
  // Shakes counters (available from /club/users/filter)
  final int totalDueShake;
  final int totalConsumedShake;
  final String?
  membershipHistoryId; // membership history ID for shake consumption tracking

  Member({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.role,
    required this.memberRole,
    required this.isActive,
    required this.membershipStatus,
    required this.membershipStartDate,
    required this.membershipEndDate,
    required this.totalPayable,
    required this.totalPaid,
    required this.dueAmount,
    required this.membershipType,
    this.address,
    this.disease,
    this.subscription,
    this.upcomingSubscription,
    this.attendanceSummary,
    this.referredByName,
    this.referredById,
    this.activeMembership,
    this.totalDueShake = 0,
    this.totalConsumedShake = 0,
    this.membershipHistoryId,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    // Safely parse dates with fallbacks to support visitors payloads
    DateTime _parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      final s = v.toString();
      return DateTime.tryParse(s) ?? DateTime.now();
    }

    final start =
        json['membershipStartDate'] ??
        json['visitStartDate'] ??
        json['visitDate'] ??
        json['createdAt'];
    final end = json['membershipEndDate'] ?? json['visitEndDate'] ?? start;

    // Numbers may arrive as String or num
    double _toDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    // Parse referBy object when provided (name and id)
    String? _parseReferBy(Map<String, dynamic>? rb) {
      if (rb == null) return null;
      final fn = (rb['firstName'] ?? '').toString().trim();
      final ln = (rb['lastName'] ?? '').toString().trim();
      final full = ('$fn $ln').trim();
      return full.isEmpty ? null : full;
    }

    String? _parseReferById(Map<String, dynamic>? rb) {
      if (rb == null) return null;
      final id = (rb['referralId'] ?? '').toString().trim();
      return id.isEmpty ? null : id;
    }

    // Active membership (new in trial API response)
    ActiveMembership? activeMembership;
    if (json['activeMembership'] is Map) {
      activeMembership = ActiveMembership.fromJson(
        (json['activeMembership'] as Map).cast<String, dynamic>(),
      );
    }

    // Shake counters may come from top-level OR activeMembership fallback
    int totalDueShake = (json['totalDueShake'] is num)
        ? (json['totalDueShake'] as num).toInt()
        : int.tryParse('${json['totalDueShake'] ?? ''}') ??
              (activeMembership?.totalDueShake ?? 0);
    int totalConsumedShake = (json['totalConsumedShake'] is num)
        ? (json['totalConsumedShake'] as num).toInt()
        : int.tryParse('${json['totalConsumedShake'] ?? ''}') ??
              (activeMembership?.totalConsumedShake ?? 0);

    return Member(
      userId: (json['userId'] ?? json['id'] ?? '').toString(),
      firstName: (json['firstName'] ?? '').toString(),
      lastName: (json['lastName'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phoneNumber: (json['phoneNumber'] ?? json['mobileNumber'] ?? '')
          .toString(),
      role: (json['role'] ?? '').toString(),
      memberRole: (json['memberRole'] ?? '').toString(),
      isActive: (json['isActive'] is bool) ? json['isActive'] as bool : true,
      membershipStatus: (json['membershipStatus'] ?? '').toString(),
      membershipStartDate: _parseDate(start),
      membershipEndDate: _parseDate(end),
      totalPayable: _toDouble(json['totalPayable']),
      totalPaid: _toDouble(json['totalPaid']),
      dueAmount: _toDouble(json['dueAmount']),
      membershipType: (json['membershipType'] ?? 'visitor').toString(),
      address: json['address']?.toString(),
      disease: json['disease']?.toString(),
      subscription: json['subscription'] == null
          ? null
          : SubscriptionSummary.fromJson(
              (json['subscription'] as Map).cast<String, dynamic>(),
            ),
      upcomingSubscription: json['upcomingSubscription'] == null
          ? null
          : UpcomingSubscription.fromJson(
              (json['upcomingSubscription'] as Map).cast<String, dynamic>(),
            ),
      attendanceSummary: json['attendanceSummary'] == null
          ? null
          : AttendanceSummary.fromJson(
              (json['attendanceSummary'] as Map).cast<String, dynamic>(),
            ),
      referredByName: _parseReferBy(
        (json['referBy'] is Map)
            ? (json['referBy'] as Map).cast<String, dynamic>()
            : null,
      ),
      referredById: _parseReferById(
        (json['referBy'] is Map)
            ? (json['referBy'] as Map).cast<String, dynamic>()
            : null,
      ),
      activeMembership: activeMembership,
      totalDueShake: totalDueShake,
      totalConsumedShake: totalConsumedShake,
      membershipHistoryId: json['membershipHistoryId']?.toString(),
    );
  }

  String get fullName => '$firstName $lastName';

  bool get hasDues => dueAmount > 0;

  bool get isCoach => memberRole == 'coach';

  bool get isMember => memberRole == 'member';

  bool get isVisitor => membershipType == 'visitor';

  bool get isMembership => membershipType == 'membership';

  bool get isExpired => DateTime.now().isAfter(membershipEndDate);

  int get daysRemaining {
    final now = DateTime.now();
    if (now.isAfter(membershipEndDate)) return 0;
    // Normalize to dates (drop time) to avoid partial-day rounding issues
    final today = DateTime(now.year, now.month, now.day);
    final endDate = DateTime(
      membershipEndDate.year,
      membershipEndDate.month,
      membershipEndDate.day,
    );
    // We want to count FULL days starting from tomorrow until the end date (inclusive)
    final raw = endDate.difference(today).inDays - 1; // subtract current day
    return raw < 0 ? 0 : raw;
  }
}

class MembersMeta {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  MembersMeta({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory MembersMeta.fromJson(Map<String, dynamic> json) {
    return MembersMeta(
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
      total: json['total'] ?? 0,
      totalPages: json['totalPages'] ?? 1,
    );
  }
}

class MembersData {
  final List<Member> data;
  final MembersMeta meta;

  MembersData({required this.data, required this.meta});

  factory MembersData.fromJson(Map<String, dynamic> json) {
    // print(
    //   'DEBUG: MembersData.fromJson called with keys: ${json.keys.toList()}',
    // );

    // Support multiple possible list keys: 'data', 'members', or 'visitors'
    final listKeyCandidates = ['data', 'members', 'visitors'];
    List<dynamic>? rawList;
    for (final key in listKeyCandidates) {
      final value = json[key];
      // print(
      //   'DEBUG: MembersData.fromJson checking key: $key, value type: ${value.runtimeType}',
      // );
      if (value is List) {
        rawList = value;
        // print(
        //   'DEBUG: MembersData.fromJson found list with key: $key, length: ${value.length}',
        // );
        break;
      }
    }

    // print(
    //   'DEBUG: MembersData.fromJson final rawList length: ${rawList?.length ?? 0}',
    // );

    final members = (rawList ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map((item) => Member.fromJson(item))
        .toList();

    // print('DEBUG: MembersData.fromJson parsed ${members.length} members');

    return MembersData(
      data: members,
      meta: MembersMeta.fromJson(json['meta'] ?? {}),
    );
  }
}

class MembersResponse {
  final bool success;
  final String message;
  final MembersData data;
  final String timestamp;

  MembersResponse({
    required this.success,
    required this.message,
    required this.data,
    required this.timestamp,
  });

  factory MembersResponse.fromJson(Map<String, dynamic> json) {
    return MembersResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: MembersData.fromJson(json['data'] ?? {}),
      timestamp: json['timestamp'] ?? '',
    );
  }
}
