import 'package:hive/hive.dart';
import '../data/models/member_model.dart';
import '../data/models/subscription_summary.dart';
import '../data/models/coach_model.dart';
import '../data/models/attendance_summary.dart';
import '../data/models/active_membership.dart';

part 'user_model.g.dart';

// UpcomingSubscription class for visitors with upcoming memberships
class UpcomingSubscription {
  final double totalPayable;
  final double totalPaid;
  final double dueAmount;
  final String? subscriptionPlanId;
  final String? membershipType;
  final bool isTrial;

  UpcomingSubscription({
    required this.totalPayable,
    required this.totalPaid,
    required this.dueAmount,
    this.subscriptionPlanId,
    this.membershipType,
    required this.isTrial,
  });

  factory UpcomingSubscription.fromJson(Map<String, dynamic> json) {
    return UpcomingSubscription(
      totalPayable: (json['totalPayable'] as num?)?.toDouble() ?? 0.0,
      totalPaid: (json['totalPaid'] as num?)?.toDouble() ?? 0.0,
      dueAmount: (json['dueAmount'] as num?)?.toDouble() ?? 0.0,
      subscriptionPlanId: json['subscriptionPlanId'] as String?,
      membershipType: json['membershipType'] as String?,
      isTrial: json['isTrial'] as bool? ?? false,
    );
  }
}

@HiveType(typeId: 0)
enum UserType {
  @HiveField(0)
  visitor,
  @HiveField(1)
  trial,
  @HiveField(2)
  member,
}

@HiveType(typeId: 1)
enum ReferralSource {
  @HiveField(0)
  friend,
  @HiveField(1)
  family,
  @HiveField(2)
  google,
  @HiveField(3)
  other,
}

@HiveType(typeId: 3)
enum UserRole {
  @HiveField(0)
  member,
  @HiveField(1)
  coach,
  @HiveField(2)
  seniorCoach,
}

@HiveType(typeId: 2)
class UserModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(29)
  String? membershipId; // API-provided membership ID for visitors/members

  @HiveField(1)
  String name;

  @HiveField(2)
  String mobileNumber;

  @HiveField(3)
  String address;

  @HiveField(4)
  ReferralSource referredBy;

  @HiveField(5)
  DateTime visitDate;

  @HiveField(6)
  UserType userType;

  @HiveField(7)
  DateTime? trialStartDate;

  @HiveField(8)
  DateTime? trialEndDate;

  @HiveField(9)
  DateTime? membershipStartDate;

  @HiveField(10)
  DateTime? membershipEndDate;

  @HiveField(11)
  double totalPaid;

  @HiveField(12)
  double pendingDues;

  @HiveField(13)
  bool isActive;

  @HiveField(14)
  String? notes;

  @HiveField(15)
  DateTime createdAt;

  @HiveField(16)
  DateTime updatedAt;

  @HiveField(17)
  UserRole role;

  @HiveField(18)
  String? email;

  @HiveField(19)
  String? firstName;

  @HiveField(20)
  String? lastName;

  @HiveField(21)
  double totalPayable;

  @HiveField(22)
  double dueAmount;

  @HiveField(23)
  String? membershipType;

  @HiveField(24)
  String? disease;

  // New: membership status string from API (e.g., active, expired)
  @HiveField(28)
  String? membershipStatus;

  @HiveField(25)
  SubscriptionSummary? subscription; // present for visitors already subscribed

  // Non-persisted: upcoming subscription for visitors who have purchased but not started yet
  UpcomingSubscription? upcomingSubscription;

  // Not persisted in Hive currently; optional display name for referrer
  @HiveField(26)
  String? referredByName;

  // Not persisted in Hive currently; optional referral ID from referBy object
  @HiveField(27)
  String? referredById;

  // Member role string (coach, seniorCoach, etc.) for finer role control
  @HiveField(30)
  String? memberRole;

  // Non-persisted: attendance summary (not annotated for Hive for now)
  AttendanceSummary? attendanceSummary;

  // Non-persisted: active membership snapshot from list/filter APIs
  ActiveMembership? activeMembership;

  // Flattened shake counters (from filter/list APIs or activeMembership fallback)
  int totalDueShake;
  int totalConsumedShake;

  UserModel({
    required this.id,
    this.membershipId,
    required this.name,
    required this.mobileNumber,
    required this.address,
    required this.referredBy,
    required this.visitDate,
    required this.userType,
    this.trialStartDate,
    this.trialEndDate,
    this.membershipStartDate,
    this.membershipEndDate,
    this.totalPaid = 0.0,
    this.pendingDues = 0.0,
    this.isActive = true,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.role = UserRole.member,
    this.email,
    this.firstName,
    this.lastName,
    this.totalPayable = 0.0,
    this.dueAmount = 0.0,
    this.membershipType,
    this.disease,
    this.membershipStatus,
    this.subscription,
    this.upcomingSubscription,
    this.referredByName,
    this.referredById,
    this.memberRole,
    this.attendanceSummary,
    this.activeMembership,
    this.totalDueShake = 0,
    this.totalConsumedShake = 0,
  });

  // Helper methods
  bool get isTrialExpired {
    if (trialEndDate == null) return false;
    return DateTime.now().isAfter(trialEndDate!);
  }

  bool get isMembershipExpired {
    if (membershipEndDate == null) return false;
    return DateTime.now().isAfter(membershipEndDate!);
  }

  bool get hasSubscription => subscription != null;

  bool get hasUpcomingSubscription => upcomingSubscription != null;

  bool get isMembershipExpiringInWeek {
    if (membershipEndDate == null) return false;
    final now = DateTime.now();
    final weekFromNow = now.add(const Duration(days: 7));
    return membershipEndDate!.isBefore(weekFromNow) &&
        membershipEndDate!.isAfter(now);
  }

  int get daysUntilMembershipExpiry {
    if (membershipEndDate == null) return 0;
    return membershipEndDate!.difference(DateTime.now()).inDays;
  }

  String get statusText {
    switch (userType) {
      case UserType.visitor:
        return 'Visitor';
      case UserType.trial:
        if (isTrialExpired) return 'Trial Expired';
        return 'Trial Active';
      case UserType.member:
        if (isMembershipExpired) return 'Membership Expired';
        if (isMembershipExpiringInWeek) return 'Expiring Soon';
        return 'Active Member';
    }
  }

  UserModel copyWith({
    String? id,
    String? membershipId,
    String? name,
    String? mobileNumber,
    String? address,
    ReferralSource? referredBy,
    DateTime? visitDate,
    UserType? userType,
    DateTime? trialStartDate,
    DateTime? trialEndDate,
    DateTime? membershipStartDate,
    DateTime? membershipEndDate,
    double? totalPaid,
    double? pendingDues,
    bool? isActive,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    UserRole? role,
    String? email,
    String? firstName,
    String? lastName,
    double? totalPayable,
    double? dueAmount,
    String? membershipType,
    String? disease,
    SubscriptionSummary? subscription,
    UpcomingSubscription? upcomingSubscription,
    String? referredByName,
    String? referredById,
    AttendanceSummary? attendanceSummary,
    ActiveMembership? activeMembership,
    int? totalDueShake,
    int? totalConsumedShake,
    String? membershipStatus,
  }) {
    return UserModel(
      id: id ?? this.id,
      membershipId: membershipId ?? this.membershipId,
      name: name ?? this.name,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      address: address ?? this.address,
      referredBy: referredBy ?? this.referredBy,
      visitDate: visitDate ?? this.visitDate,
      userType: userType ?? this.userType,
      trialStartDate: trialStartDate ?? this.trialStartDate,
      trialEndDate: trialEndDate ?? this.trialEndDate,
      membershipStartDate: membershipStartDate ?? this.membershipStartDate,
      membershipEndDate: membershipEndDate ?? this.membershipEndDate,
      totalPaid: totalPaid ?? this.totalPaid,
      pendingDues: pendingDues ?? this.pendingDues,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      role: role ?? this.role,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      totalPayable: totalPayable ?? this.totalPayable,
      dueAmount: dueAmount ?? this.dueAmount,
      membershipType: membershipType ?? this.membershipType,
      disease: disease ?? this.disease,
      membershipStatus: membershipStatus ?? this.membershipStatus,
      subscription: subscription ?? this.subscription,
      upcomingSubscription: upcomingSubscription ?? this.upcomingSubscription,
      referredByName: referredByName ?? this.referredByName,
      referredById: referredById ?? this.referredById,
      attendanceSummary: attendanceSummary ?? this.attendanceSummary,
      activeMembership: activeMembership ?? this.activeMembership,
      totalDueShake: totalDueShake ?? this.totalDueShake,
      totalConsumedShake: totalConsumedShake ?? this.totalConsumedShake,
    );
  }

  // Role management methods
  String get roleDisplayName {
    switch (role) {
      case UserRole.member:
        return 'UMS';
      case UserRole.coach:
        return 'Coach';
      case UserRole.seniorCoach:
        return 'Senior Coach';
    }
  }

  bool get isCoach => role == UserRole.coach;
  bool get isSeniorCoach => role == UserRole.seniorCoach;
  bool get isStaff => role == UserRole.coach || role == UserRole.seniorCoach;

  // Additional helper methods for unified access
  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return name;
  }

  String get phoneNumber => mobileNumber;

  // Financial helper methods
  bool get hasDues => pendingDues > 0;

  // Date helper methods
  int get daysRemaining {
    if (membershipEndDate == null) return 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endDate = DateTime(
      membershipEndDate!.year,
      membershipEndDate!.month,
      membershipEndDate!.day,
    );
    final raw = endDate.difference(today).inDays - 1; // exclude today
    return raw < 0 ? 0 : raw;
  }

  bool get isExpired {
    if (membershipEndDate == null) return false;
    return DateTime.now().isAfter(membershipEndDate!);
  }

  // Factory methods for creating UserModel from different API responses
  factory UserModel.fromMember(Member member) {
    final memberRole = member.memberRole;
    UserRole role = UserRole.member;
    UserType userType = UserType.member;

    // Determine role from memberRole
    if (memberRole == 'coach') {
      role = UserRole.coach;
    } else if (memberRole == 'seniorCoach') {
      role = UserRole.seniorCoach;
    }

    // Determine user type from membershipType
    final membershipType = member.membershipType;
    if (membershipType == 'visitor') {
      userType = UserType.visitor;
    } else if (membershipType == 'trial') {
      userType = UserType.trial;
    } else if (membershipType == 'membership') {
      // Check if it's a trial based on duration
      final duration = member.membershipEndDate
          .difference(member.membershipStartDate)
          .inDays;
      if (duration <= 10) {
        userType = UserType.trial;
      } else {
        userType = UserType.member;
      }
    }

    final int dueShake = member.totalDueShake != 0
        ? member.totalDueShake
        : (member.activeMembership?.totalDueShake ?? 0);
    final int consumedShake = member.totalConsumedShake != 0
        ? member.totalConsumedShake
        : (member.activeMembership?.totalConsumedShake ?? 0);

    return UserModel(
      id: member.userId,
      name: '${member.firstName} ${member.lastName}'.trim(),
      mobileNumber: member.phoneNumber,
      address: member.address ?? '',
      referredBy: ReferralSource.other, // Default value
      visitDate: member.membershipStartDate,
      userType: userType,
      membershipStartDate: member.membershipStartDate,
      membershipEndDate: member.membershipEndDate,
      totalPaid: member.totalPaid,
      pendingDues: member.dueAmount,
      isActive: member.isActive,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      role: role,
      email: member.email,
      firstName: member.firstName,
      lastName: member.lastName,
      totalPayable: member.totalPayable,
      dueAmount: member.dueAmount,
      membershipType: member.membershipType,
      disease: member.disease,
      membershipStatus: member.membershipStatus,
      subscription: member.subscription,
      upcomingSubscription: member.upcomingSubscription,
      referredByName: member.referredByName,
      referredById: member.referredById,
      memberRole: member.memberRole,
      attendanceSummary: member.attendanceSummary,
      activeMembership: member.activeMembership,
      totalDueShake: dueShake,
      totalConsumedShake: consumedShake,
    );
  }

  factory UserModel.fromMemberJson(Map<String, dynamic> json) {
    print(
      'DEBUG: UserModel.fromMemberJson called with keys: ${json.keys.toList()}',
    );
    print('DEBUG: UserModel.fromMemberJson - referBy: ${json['referBy']}');
    print(
      'DEBUG: UserModel.fromMemberJson - membershipType: ${json['membershipType']}',
    );
    print('DEBUG: UserModel.fromMemberJson - userId: ${json['userId']}');

    final memberRole = (json['memberRole'] ?? '').toString();
    UserRole role = UserRole.member;
    UserType userType = UserType.member;

    // Determine role from memberRole (support both seniorCoach and senior_coach)
    if (memberRole == 'coach') {
      role = UserRole.coach;
    } else if (memberRole == 'seniorCoach' || memberRole == 'senior_coach') {
      role = UserRole.seniorCoach;
    }

    // Pull dates safely; visitors may use visitStartDate/visitEndDate
    final startStr = json['membershipStartDate']?.toString();
    final endStr = json['membershipEndDate']?.toString();
    final visitStartStr = json['visitStartDate']?.toString();
    final visitEndStr = json['visitEndDate']?.toString();

    DateTime? startDate = (startStr != null && startStr.isNotEmpty)
        ? DateTime.tryParse(startStr)
        : null;
    DateTime? endDate = (endStr != null && endStr.isNotEmpty)
        ? DateTime.tryParse(endStr)
        : null;

    // For visitors, prefer visitStartDate/visitEndDate if membershipStartDate/End are not available
    startDate ??= (visitStartStr != null && visitStartStr.isNotEmpty)
        ? DateTime.tryParse(visitStartStr)
        : null;
    endDate ??= (visitEndStr != null && visitEndStr.isNotEmpty)
        ? DateTime.tryParse(visitEndStr)
        : null;

    // Fallback to general visitDate if available
    startDate ??= DateTime.tryParse((json['visitDate'] ?? '').toString());
    endDate ??= DateTime.tryParse((json['visitDate'] ?? '').toString());

    // Determine user type from membershipType when possible
    final membershipType = (json['membershipType'] ?? '').toString();
    print(
      'DEBUG: UserModel.fromMemberJson - processing membershipType: "$membershipType"',
    );
    if (membershipType == 'visitor') {
      userType = UserType.visitor;
      print('DEBUG: UserModel.fromMemberJson - set userType to visitor');
    } else if (membershipType == 'trial') {
      userType = UserType.trial;
      print('DEBUG: UserModel.fromMemberJson - set userType to trial');
    } else if (membershipType == 'membership') {
      if (startDate != null && endDate != null) {
        final duration = endDate.difference(startDate).inDays;
        userType = duration <= 10 ? UserType.trial : UserType.member;
        print(
          'DEBUG: UserModel.fromMemberJson - set userType based on duration: $duration days -> ${userType.name}',
        );
      } else {
        // Default to member if type says membership but dates are missing
        userType = UserType.member;
        print(
          'DEBUG: UserModel.fromMemberJson - set userType to member (membership with missing dates)',
        );
      }
    } else {
      print(
        'DEBUG: UserModel.fromMemberJson - unknown membershipType, keeping default member',
      );
    }

    // Robust numeric parsing
    double _toDouble(dynamic v, [double fallback = 0.0]) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? fallback;
      return fallback;
    }

    // Map optional subscription object if present (visitors subscribed)
    SubscriptionSummary? subscription;
    final subRaw = json['subscription'];
    if (subRaw is Map) {
      subscription = SubscriptionSummary.fromJson(
        subRaw.cast<String, dynamic>(),
      );
    }

    // Map optional upcomingSubscription object if present (visitors with upcoming membership)
    UpcomingSubscription? upcomingSubscription;
    final upcomingSubRaw = json['upcomingSubscription'];
    if (upcomingSubRaw is Map) {
      upcomingSubscription = UpcomingSubscription.fromJson(
        upcomingSubRaw.cast<String, dynamic>(),
      );
    }

    AttendanceSummary? attendanceSummary;
    ActiveMembership? activeMembership;
    final attRaw = json['attendanceSummary'];
    if (attRaw is Map) {
      attendanceSummary = AttendanceSummary.fromJson(
        attRaw.cast<String, dynamic>(),
      );
    }

    final activeRaw = json['activeMembership'];
    if (activeRaw is Map) {
      activeMembership = ActiveMembership.fromJson(
        activeRaw.cast<String, dynamic>(),
      );
    }

    // Always use activeMembership for shake data since API doesn't provide top-level shake fields
    final dueShake = activeMembership?.totalDueShake ?? 0;
    final consumedShake = activeMembership?.totalConsumedShake ?? 0;

    // Parse referBy object for a friendly display name if present
    String? _parseReferBy(Map<String, dynamic>? rb) {
      if (rb == null) return null;
      final fn = (rb['firstName'] ?? '').toString().trim();
      final ln = (rb['lastName'] ?? '').toString().trim();
      final full = ('$fn $ln').trim();
      return full.isEmpty ? null : full;
    }

    // Parse referBy object for referral ID if present
    String? _parseReferById(Map<String, dynamic>? rb) {
      if (rb == null) return null;
      return (rb['referralId'] ?? '').toString().trim().isEmpty
          ? null
          : (rb['referralId'] ?? '').toString().trim();
    }

    final referByObj = (json['referBy'] is Map)
        ? (json['referBy'] as Map).cast<String, dynamic>()
        : null;

    return UserModel(
      id: (json['userId'] ?? json['id'] ?? '').toString(),
      membershipId: json['membershipId']?.toString(),
      name: '${json['firstName'] ?? ''} ${json['lastName'] ?? ''}'.trim(),
      mobileNumber: (json['phoneNumber'] ?? json['mobileNumber'] ?? '')
          .toString(),
      address: (json['address'] ?? '').toString(),
      referredBy: ReferralSource.other, // Default value
      visitDate: startDate ?? DateTime.now(),
      userType: userType,
      membershipStartDate: startDate,
      membershipEndDate: endDate,
      totalPaid: _toDouble(json['totalPaid']),
      pendingDues: _toDouble(json['dueAmount']),
      isActive: (json['isActive'] is bool) ? json['isActive'] as bool : true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      role: role,
      email: json['email']?.toString(),
      firstName: json['firstName']?.toString(),
      lastName: json['lastName']?.toString(),
      totalPayable: _toDouble(json['totalPayable']),
      dueAmount: _toDouble(json['dueAmount']),
      membershipType: membershipType.isEmpty ? null : membershipType,
      disease: json['disease']?.toString(),
      membershipStatus: json['membershipStatus']?.toString(),
      subscription: subscription,
      upcomingSubscription: upcomingSubscription,
      referredByName: _parseReferBy(referByObj),
      referredById: _parseReferById(referByObj),
      memberRole: memberRole,
      attendanceSummary: attendanceSummary,
      activeMembership: activeMembership,
      totalDueShake: dueShake,
      totalConsumedShake: consumedShake,
    );
  }

  factory UserModel.fromCoach(Coach coach) {
    final memberRole = coach.memberRole;
    UserRole role = UserRole.coach;
    if (memberRole == 'seniorCoach' || memberRole == 'senior_coach') {
      role = UserRole.seniorCoach;
    }

    return UserModel(
      id: coach.userId,
      name: coach.fullName,
      mobileNumber: coach.phoneNumber ?? '',
      address: coach.address ?? '',
      referredBy: ReferralSource.other, // Default value
      visitDate: coach.membershipStartDate ?? DateTime.now(),
      userType: UserType.member, // Coaches are typically members
      membershipStatus: coach.membershipType == 'membership' ? 'active' : null,
      membershipStartDate: coach.membershipStartDate,
      membershipEndDate: coach.membershipEndDate,
      totalPaid: coach.totalPaid,
      pendingDues: coach.dueAmount,
      isActive: coach.isActive,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      role: role,
      email: coach.email,
      firstName: coach.firstName,
      lastName: coach.lastName,
      totalPayable: coach.totalPayable,
      dueAmount: coach.dueAmount,
      membershipType: coach.membershipType,
      disease: coach.disease,
      memberRole: coach.memberRole,
      attendanceSummary: coach.attendanceSummary,
      totalDueShake: 0,
      totalConsumedShake: 0,
    );
  }

  factory UserModel.fromCoachJson(Map<String, dynamic> json) {
    final memberRole = json['memberRole']?.toString() ?? '';
    UserRole role = UserRole.coach;
    if (memberRole == 'seniorCoach' || memberRole == 'senior_coach') {
      role = UserRole.seniorCoach;
    }

    DateTime? _parseDate(dynamic v) {
      if (v == null) return null;
      return DateTime.tryParse(v.toString());
    }

    double _toDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    // Optional attendance summary
    AttendanceSummary? attendanceSummary;
    ActiveMembership? activeMembership;
    final attRaw = json['attendanceSummary'];
    if (attRaw is Map) {
      attendanceSummary = AttendanceSummary.fromJson(
        attRaw.cast<String, dynamic>(),
      );
    }

    final activeRaw = json['activeMembership'];
    if (activeRaw is Map) {
      activeMembership = ActiveMembership.fromJson(
        activeRaw.cast<String, dynamic>(),
      );
    }

    // Always use activeMembership for shake data since API doesn't provide top-level shake fields
    final dueShake = activeMembership?.totalDueShake ?? 0;
    final consumedShake = activeMembership?.totalConsumedShake ?? 0;

    // Parse referBy object for referral information (same as in fromMemberJson)
    String? _parseReferBy(Map<String, dynamic>? rb) {
      if (rb == null) return null;
      final fn = (rb['firstName'] ?? '').toString().trim();
      final ln = (rb['lastName'] ?? '').toString().trim();
      final full = ('$fn $ln').trim();
      return full.isEmpty ? null : full;
    }

    String? _parseReferById(Map<String, dynamic>? rb) {
      if (rb == null) return null;
      return (rb['referralId'] ?? '').toString().trim().isEmpty
          ? null
          : (rb['referralId'] ?? '').toString().trim();
    }

    final referByObj = (json['referBy'] is Map)
        ? (json['referBy'] as Map).cast<String, dynamic>()
        : null;

    return UserModel(
      id: (json['userId'] ?? json['id'] ?? '').toString(),
      name: '${json['firstName'] ?? ''} ${json['lastName'] ?? ''}'
          .toString()
          .trim(),
      mobileNumber: (json['phoneNumber'] ?? json['mobileNumber'] ?? '')
          .toString(),
      address: (json['address'] ?? '').toString(),
      referredBy: ReferralSource.other, // Default value
      visitDate: _parseDate(json['membershipStartDate']) ?? DateTime.now(),
      userType: UserType.member,
      membershipStartDate: _parseDate(json['membershipStartDate']),
      membershipEndDate: _parseDate(json['membershipEndDate']),
      totalPaid: _toDouble(json['totalPaid']),
      pendingDues: _toDouble(json['dueAmount']),
      isActive: (json['isActive'] is bool) ? json['isActive'] as bool : true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      role: role,
      email: json['email']?.toString(),
      firstName: json['firstName']?.toString(),
      lastName: json['lastName']?.toString(),
      totalPayable: _toDouble(json['totalPayable']),
      dueAmount: _toDouble(json['dueAmount']),
      membershipType: (json['membershipType'] ?? 'membership').toString(),
      disease: json['disease']?.toString(),
      membershipStatus: json['membershipStatus']?.toString(),
      memberRole: memberRole,
      attendanceSummary: attendanceSummary,
      activeMembership: activeMembership,
      referredByName: _parseReferBy(referByObj),
      referredById: _parseReferById(referByObj),
      totalDueShake: dueShake,
      totalConsumedShake: consumedShake,
    );
  }
}
