class AttendanceViewUser {
  final String id;
  final String name;
  final String? phoneNumber;

  const AttendanceViewUser({
    required this.id,
    required this.name,
    this.phoneNumber,
  });

  factory AttendanceViewUser.fromJson(Map<String, dynamic> json) {
    try {
      final id = json['id']?.toString() ?? json['_id']?.toString() ?? '';
      // Name might come as firstName/lastName or single "name"
      final first = json['firstName']?.toString();
      final last = json['lastName']?.toString();
      final single = json['name']?.toString();
      final name = ((first ?? '').trim().isEmpty && (last ?? '').trim().isEmpty)
          ? (single ?? '').trim()
          : ([
              first,
              last,
            ].where((e) => (e ?? '').trim().isNotEmpty).join(' ').trim());
      final phone =
          json['phoneNumber']?.toString() ?? json['mobileNumber']?.toString();
      return AttendanceViewUser(
        id: id,
        name: name.isEmpty ? id : name,
        phoneNumber: phone,
      );
    } catch (e) {
      // Return fallback user if parsing fails
      return const AttendanceViewUser(
        id: 'unknown',
        name: 'Unknown User',
        phoneNumber: null,
      );
    }
  }
}

class AttendanceViewRecord {
  final String userId;
  final String status; // 'present' | 'absent'
  final String attendanceDate; // yyyy-MM-dd
  final AttendanceViewUser? user;

  const AttendanceViewRecord({
    required this.userId,
    required this.status,
    required this.attendanceDate,
    this.user,
  });

  factory AttendanceViewRecord.fromJson(Map<String, dynamic> json) {
    try {
      // Try flexible parsing to support multiple API shapes
      final date =
          json['attendanceDate']?.toString() ?? json['date']?.toString() ?? '';

      // Support multiple status shapes
      String status = (json['status']?.toString() ?? '').toLowerCase();
      if (status.isEmpty) {
        status = (json['attendanceStatus']?.toString() ?? '').toLowerCase();
      }
      if (status.isEmpty) {
        status = (json['result']?.toString() ?? '').toLowerCase();
      }
      if (status.isEmpty && json['isPresent'] is bool) {
        status = (json['isPresent'] as bool) ? 'present' : 'absent';
      }
      if (status.isEmpty) {
        status = 'present';
      }
      final userId =
          json['userId']?.toString() ??
          json['memberId']?.toString() ??
          json['user']?['id']?.toString() ??
          json['user']?['_id']?.toString() ??
          '';

      final userData = json['user'];
      AttendanceViewUser? user;

      if (userData != null && userData is Map) {
        try {
          user = AttendanceViewUser.fromJson(userData.cast<String, dynamic>());
        } catch (e) {
          user = null;
        }
      }

      return AttendanceViewRecord(
        userId: userId,
        status: status.isEmpty ? 'present' : status,
        attendanceDate: date,
        user: user,
      );
    } catch (e) {
      // Return fallback record if parsing fails
      return const AttendanceViewRecord(
        userId: 'unknown',
        status: 'unknown',
        attendanceDate: '',
        user: null,
      );
    }
  }
}

class AttendanceViewResponse {
  final bool success;
  final String attendanceDate;
  final List<AttendanceViewRecord> records;
  final String? message;

  const AttendanceViewResponse({
    required this.success,
    required this.attendanceDate,
    required this.records,
    this.message,
  });

  factory AttendanceViewResponse.fromJson(Map<String, dynamic> json) {
    try {
      // Likely shapes:
      // { success, data: { attendanceDate, present: [...users], absent: [...users] } }
      // OR { success, data: { attendanceDate, records: [{ userId, status, user: {...}}] } }
      // OR { success, data: [{ userId, status, user: {...}}] } (if data is directly a list)

      final rawData = json['data'];
      Map<String, dynamic> data;

      // Handle case where data might be a List instead of Map
      if (rawData is List) {
        // If data is directly a list of records
        data = {'records': rawData};
      } else if (rawData is Map<String, dynamic>) {
        data = rawData;
      } else {
        // Fallback to using json directly
        data = json;
      }

      final date = data['attendanceDate']?.toString() ?? '';

      List<AttendanceViewRecord> parseFromBuckets() {
        // Support multiple possible keys from backend variations
        final presentBucket =
            data['present'] ?? data['presentMembers'] ?? data['present_list'];
        final absentBucket =
            data['absent'] ?? data['absentMembers'] ?? data['absent_list'];

        final p = AttendanceViewResponse._parseBucketList(
          presentBucket,
          'present',
          date,
        );
        final a = AttendanceViewResponse._parseBucketList(
          absentBucket,
          'absent',
          date,
        );
        return [...p, ...a];
      }

      List<AttendanceViewRecord> parseFromRecords() {
        final list = (data['records'] as List?) ?? const [];
        return list
            .map((e) {
              if (e == null) return null;
              try {
                final m = (e is Map)
                    ? e.cast<String, dynamic>()
                    : <String, dynamic>{};
                return AttendanceViewRecord.fromJson(m);
              } catch (ex) {
                return null;
              }
            })
            .where((e) => e != null)
            .cast<AttendanceViewRecord>()
            .toList();
      }

      List<AttendanceViewRecord> records;
      if (data.containsKey('records')) {
        records = parseFromRecords();
      } else if (data.containsKey('results') && data['results'] is List) {
        // Some APIs may return 'results' instead of 'records'
        final list = (data['results'] as List);
        records = list
            .map((e) {
              if (e == null) return null;
              try {
                final m = (e is Map)
                    ? e.cast<String, dynamic>()
                    : <String, dynamic>{};
                return AttendanceViewRecord.fromJson(m);
              } catch (ex) {
                return null;
              }
            })
            .where((e) => e != null)
            .cast<AttendanceViewRecord>()
            .toList();
      } else {
        records = parseFromBuckets();
      }

      return AttendanceViewResponse(
        success: json['success'] == true || data['success'] == true,
        attendanceDate: date,
        records: records,
        message: json['message']?.toString() ?? data['message']?.toString(),
      );
    } catch (e) {
      // Return empty response with error message in case of parsing failure
      return AttendanceViewResponse(
        success: false,
        attendanceDate: '',
        records: const [],
        message: 'Failed to parse attendance data: ${e.toString()}',
      );
    }
  }

  // Updated bucket parser to support alternative keys like 'presentMembers'/'absentMembers'
  static List<AttendanceViewRecord> _parseBucketList(
    dynamic bucket,
    String status,
    String date,
  ) {
    final list = (bucket is List) ? bucket : const [];
    return list
        .map((e) {
          if (e == null) return null;
          try {
            final m = (e is Map)
                ? e.cast<String, dynamic>()
                : <String, dynamic>{};
            return AttendanceViewRecord(
              userId: m['id']?.toString() ?? m['_id']?.toString() ?? '',
              status: status,
              attendanceDate: date,
              user: AttendanceViewUser.fromJson(m),
            );
          } catch (_) {
            return null;
          }
        })
        .where((e) => e != null)
        .cast<AttendanceViewRecord>()
        .toList();
  }
}
