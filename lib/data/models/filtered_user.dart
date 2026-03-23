class FilteredUser {
  final String userId;
  final String firstName;
  final String lastName;
  final String membershipType; // membership or trial
  final String membershipStatus; // active/inactive
  final String? phoneNumber; // optional if API provides

  const FilteredUser({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.membershipType,
    required this.membershipStatus,
    this.phoneNumber,
  });

  String get name =>
      [firstName, lastName].where((s) => s.trim().isNotEmpty).join(' ').trim();

  factory FilteredUser.fromJson(Map<String, dynamic> json) {
    return FilteredUser(
      userId: json['userId']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      membershipType: json['membershipType']?.toString() ?? '',
      membershipStatus: json['membershipStatus']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString(),
    );
  }
}

class FilteredUsersPageMeta {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const FilteredUsersPageMeta({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory FilteredUsersPageMeta.fromJson(Map<String, dynamic> json) {
    return FilteredUsersPageMeta(
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
      total: (json['total'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
    );
  }
}

class FilteredUsersPage {
  final List<FilteredUser> data;
  final FilteredUsersPageMeta meta;

  const FilteredUsersPage({required this.data, required this.meta});

  factory FilteredUsersPage.fromJson(Map<String, dynamic> json) {
    final dataNode = (json['data'] as Map<String, dynamic>?) ?? {};
    final list = (dataNode['data'] as List? ?? [])
        .map((e) => FilteredUser.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = FilteredUsersPageMeta.fromJson(
      (dataNode['meta'] as Map<String, dynamic>? ?? const {}),
    );
    return FilteredUsersPage(data: list, meta: meta);
  }
}
