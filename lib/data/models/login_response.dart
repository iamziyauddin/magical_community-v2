class LoginResponse {
  final bool success;
  final String message;
  final LoginData data;
  final String timestamp;

  LoginResponse({
    required this.success,
    required this.message,
    required this.data,
    required this.timestamp,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: LoginData.fromJson(json['data'] ?? {}),
      timestamp: json['timestamp'] ?? '',
    );
  }
}

class LoginData {
  final User user;
  final String accessToken;
  final Club club;

  LoginData({
    required this.user,
    required this.accessToken,
    required this.club,
  });

  factory LoginData.fromJson(Map<String, dynamic> json) {
    return LoginData(
      user: User.fromJson(json['user'] ?? {}),
      accessToken: json['accessToken'] ?? '',
      club: Club.fromJson(json['club'] ?? {}),
    );
  }
}

class User {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String role;
  final String memberRole;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.role,
    required this.memberRole,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      role: json['role'] ?? '',
      memberRole: json['memberRole'] ?? '',
      isActive: json['isActive'] ?? false,
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }

  String get fullName => '$firstName $lastName';
}

class Club {
  final String id;
  final String name;
  final String code;
  final String location;
  final String phoneNumber;
  final String email;
  final bool isActive;

  Club({
    required this.id,
    required this.name,
    required this.code,
    required this.location,
    required this.phoneNumber,
    required this.email,
    required this.isActive,
  });

  factory Club.fromJson(Map<String, dynamic> json) {
    return Club(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      location: json['location'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      email: json['email'] ?? '',
      isActive: json['isActive'] ?? false,
    );
  }
}
