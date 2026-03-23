class AddUserRequest {
  final String firstName;
  final String lastName;
  final String? email;
  final String phoneNumber;
  final String address;
  final String disease;
  final String? referralName;
  final String? referralId;
  final String? subscriptionPlanId;
  final double amount;
  final DateTime visitDate;

  const AddUserRequest({
    required this.firstName,
    required this.lastName,
    this.email,
    required this.phoneNumber,
    required this.address,
    required this.disease,
    this.referralName,
    this.referralId,
    this.subscriptionPlanId,
    required this.amount,
    required this.visitDate,
  });

  factory AddUserRequest.fromJson(Map<String, dynamic> json) {
    DateTime _parseVisitDate(dynamic v) {
      if (v is String) {
        return DateTime.tryParse(v) ?? DateTime.now();
      }
      return DateTime.now();
    }

    return AddUserRequest(
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      email: json['email'] as String?,
      phoneNumber: json['phoneNumber'] as String,
      address: json['address'] as String,
      disease: json['disease'] as String,
      referralName: json['referralName'] as String?,
      referralId: json['referralId'] as String?,
      subscriptionPlanId: json['subscriptionPlanId'] as String?,
      amount: (json['amount'] as num).toDouble(),
      visitDate: _parseVisitDate(json['visit_date'] ?? json['visitDate']),
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'address': address,
      'disease': disease,
      'amount': amount,
      // API expects visit_date as YYYY-MM-DD
      'visit_date':
          '${visitDate.year.toString().padLeft(4, '0')}-${visitDate.month.toString().padLeft(2, '0')}-${visitDate.day.toString().padLeft(2, '0')}',
    };

    if (email != null && email!.isNotEmpty) {
      data['email'] = email!;
    }

    // Only include optional fields if they are not null
    if (referralName != null) {
      data['referralName'] = referralName!;
    }
    if (referralId != null) {
      data['referralId'] = referralId!;
    }
    if (subscriptionPlanId != null) {
      data['subscriptionPlanId'] = subscriptionPlanId!;
    }

    return data;
  }
}

class AddUserResponseData {
  final AddUserUser user;

  const AddUserResponseData({required this.user});

  factory AddUserResponseData.fromJson(Map<String, dynamic> json) {
    return AddUserResponseData(
      user: AddUserUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {'user': user.toJson()};
  }
}

class AddUserUser {
  final String userId;
  final String firstName;
  final String lastName;
  final String? email;
  final String phoneNumber;
  final String? address;
  final String? disease;
  final String role;
  final String memberRole;
  final bool isActive;
  final Map<String, dynamic>? referBy;
  final String? membershipStatus;
  final String? membershipStartDate;
  final String? membershipEndDate;
  final double? totalPayable;
  final double? totalPaid;
  final double? dueAmount;
  final String? membershipType;
  final Map<String, dynamic>? attendanceSummary;
  final Map<String, dynamic>? activeMembership;

  const AddUserUser({
    required this.userId,
    required this.firstName,
    required this.lastName,
    this.email,
    required this.phoneNumber,
    this.address,
    this.disease,
    required this.role,
    required this.memberRole,
    required this.isActive,
    this.referBy,
    this.membershipStatus,
    this.membershipStartDate,
    this.membershipEndDate,
    this.totalPayable,
    this.totalPaid,
    this.dueAmount,
    this.membershipType,
    this.attendanceSummary,
    this.activeMembership,
  });

  factory AddUserUser.fromJson(Map<String, dynamic> json) {
    return AddUserUser(
      userId: json['userId'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      email: json['email'] as String?,
      phoneNumber: json['phoneNumber'] as String,
      address: json['address'] as String?,
      disease: json['disease'] as String?,
      role: json['role'] as String,
      memberRole: json['memberRole'] as String,
      isActive: json['isActive'] as bool,
      referBy: json['referBy'] as Map<String, dynamic>?,
      membershipStatus: json['membershipStatus'] as String?,
      membershipStartDate: json['membershipStartDate'] as String?,
      membershipEndDate: json['membershipEndDate'] as String?,
      totalPayable: (json['totalPayable'] as num?)?.toDouble(),
      totalPaid: (json['totalPaid'] as num?)?.toDouble(),
      dueAmount: (json['dueAmount'] as num?)?.toDouble(),
      membershipType: json['membershipType'] as String?,
      attendanceSummary: json['attendanceSummary'] as Map<String, dynamic>?,
      activeMembership: json['activeMembership'] as Map<String, dynamic>?,
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
      'referBy': referBy,
      'membershipStatus': membershipStatus,
      'membershipStartDate': membershipStartDate,
      'membershipEndDate': membershipEndDate,
      'totalPayable': totalPayable,
      'totalPaid': totalPaid,
      'dueAmount': dueAmount,
      'membershipType': membershipType,
      'attendanceSummary': attendanceSummary,
      'activeMembership': activeMembership,
    };
  }

  String get fullName => '$firstName $lastName';
}

class AddUserResponse {
  final bool success;
  final String message;
  final AddUserResponseData data;
  final String timestamp;

  const AddUserResponse({
    required this.success,
    required this.message,
    required this.data,
    required this.timestamp,
  });

  factory AddUserResponse.fromJson(Map<String, dynamic> json) {
    return AddUserResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      data: AddUserResponseData.fromJson(json['data'] as Map<String, dynamic>),
      timestamp: json['timestamp'] as String,
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
