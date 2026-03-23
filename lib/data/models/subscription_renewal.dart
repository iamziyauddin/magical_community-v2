class SubscriptionRenewal {
  final String id;
  final String userId;
  final String clubId;
  final String subscriptionType;
  final double amount;
  final double totalPaid;
  final double dueAmount;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SubscriptionUser? user;
  final SubscriptionClub? club;

  const SubscriptionRenewal({
    required this.id,
    required this.userId,
    required this.clubId,
    required this.subscriptionType,
    required this.amount,
    required this.totalPaid,
    required this.dueAmount,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.user,
    this.club,
  });

  factory SubscriptionRenewal.fromJson(Map<String, dynamic> json) {
    return SubscriptionRenewal(
      id: json['id'] as String,
      userId: json['userId'] as String,
      clubId: json['clubId'] as String,
      subscriptionType: json['subscriptionType'] as String,
      amount: (json['amount'] as num).toDouble(),
      totalPaid: (json['totalPaid'] as num).toDouble(),
      dueAmount: (json['dueAmount'] as num).toDouble(),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      isActive: json['isActive'] as bool,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      user: json['user'] != null
          ? SubscriptionUser.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      club: json['club'] != null
          ? SubscriptionClub.fromJson(json['club'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'clubId': clubId,
      'subscriptionType': subscriptionType,
      'amount': amount,
      'totalPaid': totalPaid,
      'dueAmount': dueAmount,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isActive': isActive,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (user != null) 'user': user!.toJson(),
      if (club != null) 'club': club!.toJson(),
    };
  }
}

class SubscriptionUser {
  final String id;
  final String firstName;
  final String lastName;
  final String? email;

  const SubscriptionUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.email,
  });

  factory SubscriptionUser.fromJson(Map<String, dynamic> json) {
    return SubscriptionUser(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      email: json['email'] == null ? null : (json['email'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      if (email != null) 'email': email,
    };
  }

  String get fullName => '$firstName $lastName';
}

class SubscriptionClub {
  final String id;
  final String name;
  final String code;

  const SubscriptionClub({
    required this.id,
    required this.name,
    required this.code,
  });

  factory SubscriptionClub.fromJson(Map<String, dynamic> json) {
    return SubscriptionClub(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'code': code};
  }
}

class SubscriptionRenewalResponse {
  final bool success;
  final String message;
  final SubscriptionRenewalData data;
  final String timestamp;

  const SubscriptionRenewalResponse({
    required this.success,
    required this.message,
    required this.data,
    required this.timestamp,
  });

  factory SubscriptionRenewalResponse.fromJson(Map<String, dynamic> json) {
    return SubscriptionRenewalResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      data: SubscriptionRenewalData.fromJson(
        json['data'] as Map<String, dynamic>,
      ),
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

class SubscriptionRenewalData {
  final SubscriptionRenewal subscription;

  const SubscriptionRenewalData({required this.subscription});

  factory SubscriptionRenewalData.fromJson(Map<String, dynamic> json) {
    return SubscriptionRenewalData(
      subscription: SubscriptionRenewal.fromJson(
        json['subscription'] as Map<String, dynamic>,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {'subscription': subscription.toJson()};
  }
}
