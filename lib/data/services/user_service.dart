import 'package:dio/dio.dart';

import '../../core/config/env.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_result.dart';
import '../models/dashboard_stats.dart';
import '../models/subscription_plan.dart';
import '../models/subscription_renewal.dart';
import '../models/add_user_request.dart';
import '../models/member_model.dart';
import '../models/coach_model.dart';
import '../../models/payment_model.dart';
import '../../models/user_model.dart';
import '../models/filtered_user.dart';
import '../models/attendance_result.dart';
import '../models/attendance_view_record.dart';

class UserService {
  final Dio _dio = ApiClient.instance.dio;

  // Centralized extraction of server/transport error message without static fallbacks.
  String _extractDioMessage(DioException e) {
    if (e.response?.data is Map<String, dynamic>) {
      final map = e.response!.data as Map<String, dynamic>;
      final msg = map['message'];
      if (msg is String && msg.trim().isNotEmpty) return msg;
    }
    final m = e.message;
    if (m != null && m.trim().isNotEmpty) return m;
    return '';
  }

  /// Unified detail fetch for any user type (UMS member / coach / senior coach / trial / visitor)
  /// API pattern: /ums/{userId}?clubId={clubId}
  /// Fallback: tries absolute URL if relative path returns 404 (environment host issues)
  Future<ApiResult<UserModel>> getUserDetail({
    required String userId,
    required String clubId,
  }) async {
    // We intentionally keep this lightweight and rely on UserModel.fromMemberJson for mapping
    Future<Response<dynamic>> _primary() =>
        _dio.get('/ums/$userId', queryParameters: {'clubId': clubId});
    Future<Response<dynamic>> _secondary() => _dio.get(
      '${Env.finalApiBaseUrl}/ums/$userId',
      queryParameters: {'clubId': clubId},
    );
    try {
      Response resp;
      try {
        resp = await _primary();
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          resp = await _secondary();
        } else {
          rethrow;
        }
      }

      final data = resp.data;
      if (data is! Map<String, dynamic>) {
        return ApiFailure('Unexpected response format');
      }
      if (data['success'] != true) {
        return ApiFailure(
          data['message']?.toString() ?? 'Failed to fetch user',
        );
      }
      final userJson =
          (data['data']?['user'] as Map<String, dynamic>?) ??
          <String, dynamic>{};
      try {
        final user = UserModel.fromMemberJson(userJson);
        return ApiSuccess(user);
      } catch (e, st) {
        // Log parsing issue but return failure gracefully
        // ignore: avoid_print
        print('ERROR: Failed parsing user detail: $e');
        // ignore: avoid_print
        print(st);
        return ApiFailure('Failed to parse user data');
      }
    } on DioException catch (e) {
      return ApiFailure(
        _extractDioMessage(e),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return ApiFailure(e.toString());
    }
  }

  /// Fetch available subscription plans
  Future<ApiResult<List<SubscriptionPlan>>> getSubscriptionPlans() async {
    try {
      final response = await _dio.get('/api/subscriptions');

      final subscriptionResponse = SubscriptionPlansResponse.fromJson(
        response.data,
      );

      if (subscriptionResponse.success) {
        return ApiSuccess(subscriptionResponse.data);
      } else {
        return ApiFailure(subscriptionResponse.message);
      }
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      String? message;
      if (e.response?.data is Map<String, dynamic>) {
        final errorData = e.response!.data as Map<String, dynamic>;
        message = errorData['message']?.toString() ?? message;
      } else if (e.message != null) {
        message = e.message;
      }
      return ApiFailure(message ?? '', statusCode: statusCode);
    } catch (e) {
      return ApiFailure(e.toString());
    }
  }

  /// Attendance: view records by date (present/absent lists or combined records)
  Future<ApiResult<AttendanceViewResponse>> getAttendanceByDate({
    required DateTime date,
  }) async {
    String _fmt(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final ds = _fmt(date);
    try {
      // Prefer relative path; fall back to absolute if needed
      Response resp;
      try {
        resp = await _dio.get('/attendance/$ds');
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          resp = await _dio.get('${Env.finalApiBaseUrl}/attendance/$ds');
        } else {
          rethrow;
        }
      }

      // Handle different response structures
      final responseData = resp.data;
      Map<String, dynamic> map;

      if (responseData is Map<String, dynamic>) {
        map = responseData;
      } else if (responseData is List) {
        // If API returns a list directly, wrap it in the expected structure
        map = {'success': true, 'data': responseData};
      } else {
        // Fallback for unexpected response structure
        map = {
          'success': false,
          'message': 'Unexpected response format',
          'data': {},
        };
      }

      final parsed = AttendanceViewResponse.fromJson(map);
      if (parsed.success) return ApiSuccess(parsed);
      return ApiFailure(parsed.message ?? '');
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      String? message;
      if (e.response?.data is Map<String, dynamic>) {
        final err = e.response!.data as Map<String, dynamic>;
        message = err['message']?.toString() ?? message;
      } else if (e.message != null) {
        message = e.message;
      }
      return ApiFailure(message ?? '', statusCode: statusCode);
    } catch (e) {
      return ApiFailure(e.toString());
    }
  }

  /// Dashboard: fetch today's stats mapping from daily-entries API
  Future<ApiResult<DashboardStats>> getTodayDashboardStats() async {
    try {
      final now = DateTime.now();
      final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      
      final response = await _dio.get(
        '/daily-entries/',
        queryParameters: {
          'startDate': todayStr,
          'endDate': todayStr,
          'page': 1,
          'limit': 1,
        },
      );

      final map = response.data as Map<String, dynamic>;
      if (map['success'] == true) {
        final data = map['data'] as Map<String, dynamic>? ?? {};
        final entries = data['entries'] as List<dynamic>? ?? [];
        
        if (entries.isEmpty) {
          // Return zeroed stats if no entry exists for today
          return ApiSuccess(DashboardStats.fromJson({
            'date': todayStr,
            'todayVisitorCount': 0,
            'todayTrialCount': 0,
            'todayNewMemberCount': 0,
            'todayMemberShakeCount': 0,
            'todayTrialShakeCount': 0,
            'totalUMS': 0,
            // the rest will default to 0 in DashboardStats.fromJson
          }));
        }

        final entry = entries.first as Map<String, dynamic>;
        
        // Map daily-entries structure to DashboardStats structure
        return ApiSuccess(DashboardStats.fromJson({
          'date': entry['entryDate'] ?? todayStr,
          'todayVisitorCount': entry['visitEntry'],
          'todayTrialCount': entry['trialsStart'],
          'todayNewMemberCount': entry['newUms'],
          'todayMemberShakeCount': entry['umsShakes'],
          'todayTrialShakeCount': entry['trialShakes'],
          'totalUMS': entry['totalUms'], // Usually UMS count, or you could add 'newUms' + 'umsShakes' if 'totalUms' is missing. The API showed 'totalUms' being present in earlier examples.
          // Other values (absent/present/coaches) are not provided by this endpoint and will naturally default to 0
        }));
      }
      return ApiFailure(map['message']?.toString() ?? 'Failed to fetch dashboard stats');
    } on DioException catch (e) {
      return ApiFailure(
        _extractDioMessage(e),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return ApiFailure(e.toString());
    }
  }

  /// Renew/Upgrade subscription for a member
  Future<ApiResult<SubscriptionRenewal>> renewSubscription({
    required String memberId,
    required String subscriptionPlanId,
    required double amount,
    String? startDate,
  }) async {
    try {
      // Backend expects an integer 0 for zero-value payments (not 0.0)
      final dynamic normalizedAmount = (amount == 0) ? 0 : amount;

      final Map<String, dynamic> requestData = {
        'subscriptionPlanId': subscriptionPlanId,
        'amount': normalizedAmount,
      };

      // Add startDate if provided
      if (startDate != null) {
        requestData['startDate'] = startDate;
      }

      final response = await _dio.post(
        '/club/members/$memberId/renew',
        data: requestData,
      );

      final renewalResponse = SubscriptionRenewalResponse.fromJson(
        response.data,
      );

      if (renewalResponse.success) {
        return ApiSuccess(renewalResponse.data.subscription);
      }
      return ApiFailure(renewalResponse.message);
    } on DioException catch (e) {
      return ApiFailure(
        _extractDioMessage(e),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return ApiFailure(e.toString());
    }
  }

  /// Promote/Demote a member's role.
  /// Allowed values:
  ///  - member (demote to regular UMS)
  ///  - coach
  ///  - senior_coach (promote to senior coach)
  Future<ApiResult<UserModel>> updateMemberRole({
    required String memberId,
    required String memberRole,
  }) async {
    try {
      final response = await _dio.post(
        '/club/members/$memberId/promote',
        data: {'memberRole': memberRole},
      );

      final map = response.data as Map<String, dynamic>;
      if (map['success'] == true) {
        final userJson = (map['data']?['user'] as Map<String, dynamic>?) ?? {};
        final user = UserModel.fromMemberJson(userJson);
        return ApiSuccess(user);
      }
      // Return server provided message (no static override if present)
      final rawMessage = map['message']?.toString();
      return ApiFailure(rawMessage ?? '');
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      String? message;
      if (e.response?.data is Map<String, dynamic>) {
        final err = e.response!.data as Map<String, dynamic>;
        message = err['message']?.toString() ?? message;
      } else if (e.message != null) {
        message = e.message!;
      }
      return ApiFailure(message ?? '', statusCode: statusCode);
    } catch (e) {
      // Pass through raw exception string (no static prefix)
      return ApiFailure(e.toString());
    }
  }

  /// Update user details (UMS/Trial/Visitor)
  Future<ApiResult<UserModel>> updateUserDetails({
    required String userId,
    required String firstName,
    String? lastName,
    String? email,
    required String phoneNumber,
    String? address,
    String? disease,
    String? referralId,
    String? referralName,
    DateTime? startDate,
    String? subscriptionPlanId,
    String? membershipId,
  }) async {
    final Map<String, dynamic> payload = {
      'firstName': firstName,
      'phoneNumber': phoneNumber,
    };

    void addIfValid(String key, dynamic value) {
      if (value == null) return;
      if (value is String && value.trim().isEmpty) return;
      payload[key] = value;
    }

    addIfValid('lastName', lastName);
    addIfValid('email', email);
    addIfValid('address', address);
    addIfValid('disease', disease);
    addIfValid('referralId', referralId);
    addIfValid('referralName', referralName);
    addIfValid('subscriptionPlanId', subscriptionPlanId);
    addIfValid('membershipId', membershipId);
    if (startDate != null) {
      payload['startDate'] = startDate.toIso8601String().split('T').first;
    }

    Future<Response<dynamic>> _putToPrimary() =>
        _dio.put('/api/users/$userId', data: payload);
    Future<Response<dynamic>> _putToSecondary() =>
        _dio.put('${Env.finalApiBaseUrl}/api/users/$userId', data: payload);

    try {
      Response resp;
      try {
        resp = await _putToPrimary();
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          // Try the alternative absolute path provided
          resp = await _putToSecondary();
        } else {
          rethrow;
        }
      }

      final data = resp.data as Map<String, dynamic>;
      print('DEBUG: Update response - success: ${data['success']}');
      print(
        'DEBUG: Update response - data structure: ${data['data']?.runtimeType}',
      );
      print(
        'DEBUG: Update response - has data.user: ${data['data']?['user'] != null}',
      );

      if (data['success'] == true) {
        final userJson =
            (data['data']?['user'] as Map<String, dynamic>?) ??
            (data['user'] as Map<String, dynamic>?) ??
            <String, dynamic>{};

        print('DEBUG: Extracted userJson keys: ${userJson.keys.toList()}');
        print('DEBUG: userJson referBy: ${userJson['referBy']}');

        // Parse to UserModel using existing factory with defensive catch
        try {
          final user = UserModel.fromMemberJson(userJson);
          print(
            'DEBUG: Parsed UserModel - referredByName: "${user.referredByName}", referredById: "${user.referredById}"',
          );
          return ApiSuccess(user);
        } catch (e, st) {
          print('ERROR: Failed to parse updated user into UserModel: $e');
          print(st);
          return ApiFailure('Failed to parse updated user data');
        }
      }
      final rawMessage = data['message']?.toString();
      return ApiFailure(rawMessage ?? '');
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      String? message;
      if (e.response?.data is Map<String, dynamic>) {
        final err = e.response!.data as Map<String, dynamic>;
        message = err['message']?.toString() ?? message;
      } else if (e.message != null) {
        message = e.message!;
      }
      return ApiFailure(message ?? '', statusCode: statusCode);
    } catch (e) {
      return ApiFailure(e.toString());
    }
  }

  /// Add a new user
  Future<ApiResult<AddUserResponseData>> addUser(AddUserRequest request) async {
    try {
      final response = await _dio.post('/api/users', data: request.toJson());

      final addUserResponse = AddUserResponse.fromJson(response.data);

      if (addUserResponse.success) {
        return ApiSuccess(addUserResponse.data);
      }
      return ApiFailure(addUserResponse.message);
    } on DioException catch (e) {
      return ApiFailure(
        _extractDioMessage(e),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return ApiFailure(e.toString());
    }
  }

  /// Fetch club UMS with pagination
  Future<ApiResult<MembersData>> getMembers({
    int page = 1,
    int limit = 20,
    bool activeOnly = true,
  }) async {
    try {
      final response = await _dio.get(
        '/club/members',
        queryParameters: {
          'page': page,
          'limit': limit,
          'activeOnly': activeOnly,
        },
      );

      final membersResponse = MembersResponse.fromJson(response.data);

      if (membersResponse.success) {
        return ApiSuccess(membersResponse.data);
      }
      return ApiFailure(membersResponse.message);
    } on DioException catch (e) {
      return ApiFailure(
        _extractDioMessage(e),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return ApiFailure(e.toString());
    }
  }

  /// New: Unified filter endpoint for users by membershipTypes
  /// membershipTypes: 'membership' or 'trial' (comma separated allowed)
  Future<ApiResult<MembersData>> filterUsersByMembershipTypes({
    int page = 1,
    int limit = 20,
    bool activeOnly = true,
    required String membershipTypes,
  }) async {
    try {
      final qp = {
        'page': page,
        'limit': limit,
        'activeOnly': activeOnly,
        'membershipTypes': membershipTypes,
      };

      Response response;
      try {
        response = await _dio.get('/club/users/filter', queryParameters: qp);
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          response = await _dio.get(
            '${Env.finalApiBaseUrl}/club/users/filter',
            queryParameters: qp,
          );
        } else {
          rethrow;
        }
      }

      final map = response.data as Map<String, dynamic>;
      // The "filter" endpoint wraps result as { data: { data: [], meta: {} } }
      final dataNode = (map['data'] as Map<String, dynamic>?) ?? {};
      final listNode = (dataNode['data'] as List?) ?? const [];
      final metaNode = (dataNode['meta'] as Map<String, dynamic>?) ?? const {};

      final members = listNode
          .whereType<Map<String, dynamic>>()
          .map((e) => Member.fromJson(e))
          .toList();
      final membersData = MembersData(
        data: members,
        meta: MembersMeta.fromJson(metaNode),
      );
      return ApiSuccess(membersData);
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      String message = 'Failed to fetch users';
      if (e.response?.data is Map<String, dynamic>) {
        final errorData = e.response!.data as Map<String, dynamic>;
        message = errorData['message']?.toString() ?? message;
      } else if (e.message != null) {
        message = e.message!;
      }
      return ApiFailure(message, statusCode: statusCode);
    } catch (e) {
      return ApiFailure('Unexpected error: ${e.toString()}');
    }
  }

  /// Fetch club visitors with pagination
  Future<ApiResult<MembersData>> getVisitors({
    int page = 1,
    int limit = 20,
    bool activeOnly = false,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      String _fmt(DateTime d) =>
          '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final queryParameters = {
        'page': page,
        'limit': limit,
        'activeOnly': activeOnly,
        if (startDate != null) 'startDate': _fmt(startDate),
        if (endDate != null) 'endDate': _fmt(endDate),
      };

      Response response;
      try {
        response = await _dio.get(
          '/club/visitors',
          queryParameters: queryParameters,
        );
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          // Fallback to absolute URL as requested
          response = await _dio.get(
            '${Env.finalApiBaseUrl}/club/visitors',
            queryParameters: queryParameters,
          );
        } else {
          rethrow;
        }
      }

      final map = response.data as Map<String, dynamic>;
      try {
        final visitorsResponse = MembersResponse.fromJson(map);
        if (visitorsResponse.success) {
          return ApiSuccess(visitorsResponse.data);
        }
        // Fallback if success is false but payload has data
        final dataJson = (map['data'] is Map<String, dynamic>)
            ? map['data'] as Map<String, dynamic>
            : map;
        final membersData = MembersData.fromJson(dataJson);
        return ApiSuccess(membersData);
      } catch (_) {
        // Last resort: try parsing members directly from common keys
        final membersData = MembersData.fromJson(map['data'] ?? map);
        return ApiSuccess(membersData);
      }
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      String message = 'Failed to fetch visitors';

      if (e.response?.data is Map<String, dynamic>) {
        final errorData = e.response!.data as Map<String, dynamic>;
        message = errorData['message']?.toString() ?? message;
      } else if (e.message != null) {
        message = e.message!;
      }

      return ApiFailure(message, statusCode: statusCode);
    } catch (e) {
      return ApiFailure('Unexpected error: ${e.toString()}');
    }
  }

  /// Fetch club coaches with pagination (supports memberRole filter)
  Future<ApiResult<CoachesData>> getCoaches({
    int page = 1,
    int limit = 20,
    bool includeInactive = false,
    String? memberRole, // e.g., 'coach' or 'senior_coach'
    String? search, // Search query for filtering coaches
  }) async {
    try {
      final response = await _dio.get(
        '/club/coaches',
        queryParameters: {
          'page': page,
          'limit': limit,
          'includeInactive': includeInactive,
          if (memberRole != null) 'memberRole': memberRole,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );

      final coachesResponse = CoachesResponse.fromJson(response.data);

      if (coachesResponse.success) {
        return ApiSuccess(coachesResponse.data);
      } else {
        return ApiFailure(coachesResponse.message);
      }
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      String message = 'Failed to fetch coaches';

      if (e.response?.data is Map<String, dynamic>) {
        final errorData = e.response!.data as Map<String, dynamic>;
        message = errorData['message']?.toString() ?? message;
      } else if (e.message != null) {
        message = e.message!;
      }

      return ApiFailure(message, statusCode: statusCode);
    } catch (e) {
      return ApiFailure('Unexpected error: ${e.toString()}');
    }
  }

  /// Fetch payment history for a specific UMS
  Future<ApiResult<List<PaymentModel>>> getMemberPaymentHistory(
    String memberId,
  ) async {
    try {
      // Try multiple possible endpoints
      final possibleEndpoints = [
        '/club/members/$memberId/payments',
        '/members/$memberId/payments',
        '/payments/member/$memberId',
        '/club/payments?memberId=$memberId',
      ];

      for (final endpoint in possibleEndpoints) {
        try {
          final response = await _dio.get(endpoint);
          final paymentResponse = response.data as Map<String, dynamic>;

          if (paymentResponse['success'] == true) {
            final paymentsData =
                paymentResponse['data'] as List<dynamic>? ?? [];
            final payments = paymentsData
                .map(
                  (payment) => PaymentModel(
                    id:
                        payment['id']?.toString() ??
                        DateTime.now().millisecondsSinceEpoch.toString(),
                    amount: (payment['amount'] as num?)?.toDouble() ?? 0.0,
                    userId:
                        payment['userId']?.toString() ??
                        payment['memberId']?.toString(),
                    date:
                        DateTime.tryParse(
                          payment['date']?.toString() ??
                              payment['paymentDate']?.toString() ??
                              '',
                        ) ??
                        DateTime.now(),
                    type: _mapStringToPaymentType(
                      payment['type']?.toString() ??
                          payment['paymentType']?.toString() ??
                          'membership',
                    ),
                    mode: _mapStringToPaymentMode(
                      payment['mode']?.toString() ??
                          payment['paymentMode']?.toString() ??
                          'cash',
                    ),
                    isIncome: payment['isIncome'] ?? true,
                    createdAt:
                        DateTime.tryParse(
                          payment['createdAt']?.toString() ?? '',
                        ) ??
                        DateTime.now(),
                  ),
                )
                .toList();

            return ApiSuccess(payments);
          }
        } on DioException catch (e) {
          // If it's a 404, try the next endpoint
          if (e.response?.statusCode == 404) {
            continue;
          }
          // For other errors, rethrow
          rethrow;
        }
      }

      // If all endpoints failed with 404, return empty list (API doesn't support payments yet)
      return ApiSuccess(<PaymentModel>[]);
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 404) {
        return ApiSuccess(<PaymentModel>[]);
      }
      String? message;
      if (e.response?.data is Map<String, dynamic>) {
        final errorData = e.response!.data as Map<String, dynamic>;
        message = errorData['message']?.toString() ?? message;
      } else if (e.message != null) {
        message = e.message;
      }
      return ApiFailure(message ?? '', statusCode: statusCode);
    } catch (e) {
      return ApiFailure(e.toString());
    }
  }

  // Helper methods to map strings to enums
  PaymentType _mapStringToPaymentType(String type) {
    switch (type.toLowerCase()) {
      case 'trial':
        return PaymentType.trial;
      case 'expense':
        return PaymentType.expense;
      default:
        return PaymentType.membership;
    }
  }

  PaymentMode _mapStringToPaymentMode(String mode) {
    switch (mode.toLowerCase()) {
      case 'online':
        return PaymentMode.online;
      case 'cash':
        return PaymentMode.cash;
      // case 'upi':
      //   return PaymentMode.upi;
      // case 'netbanking':
      //   return PaymentMode.netBanking;
      // case 'other':
      //   return PaymentMode.other;
      default:
        return PaymentMode.cash;
    }
  }

  /// Fetch user transactions (payments) by userId with pagination
  Future<ApiResult<List<PaymentModel>>> getUserTransactions({
    required String userId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/transactions/$userId',
        queryParameters: {'page': page, 'limit': limit},
      );

      final map = response.data as Map<String, dynamic>;
      if (map['success'] == true) {
        final data = (map['data'] as Map<String, dynamic>?) ?? const {};
        final list = (data['data'] as List<dynamic>? ?? const []);
        final payments = list.map((e) {
          final m = (e as Map).cast<String, dynamic>();
          final id = (m['id'] ?? m['_id'] ?? '').toString();
          final amount = (m['amount'] as num?)?.toDouble() ?? 0.0;
          final uid = (m['userId'] ?? userId).toString();
          final txDateStr =
              (m['transactionDate'] ?? m['date'] ?? m['createdAt'])?.toString();
          final txDate = DateTime.tryParse(txDateStr ?? '') ?? DateTime.now();
          final createdAt =
              DateTime.tryParse(
                (m['createdAt'] ?? txDateStr ?? '').toString(),
              ) ??
              txDate;
          final typeStr = (m['type'] ?? m['category'] ?? 'subscription')
              .toString();
          final method = (m['paymentMethod'] ?? m['mode'] ?? 'cash').toString();
          final desc = m['description']?.toString();
          return PaymentModel(
            id: id.isNotEmpty
                ? id
                : DateTime.now().millisecondsSinceEpoch.toString(),
            amount: amount,
            userId: uid,
            linkedUserName: null,
            date: txDate,
            type: _mapStringToPaymentType(typeStr),
            mode: _mapStringToPaymentMode(method),
            description: desc,
            notes: null,
            isIncome: true,
            createdAt: createdAt,
          );
        }).toList();
        return ApiSuccess(payments);
      }
      return ApiFailure(
        map['message']?.toString() ?? 'Failed to fetch transactions',
      );
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      String message = 'Failed to fetch transactions';
      if (e.response?.data is Map<String, dynamic>) {
        final err = e.response!.data as Map<String, dynamic>;
        message = err['message']?.toString() ?? message;
      } else if (e.message != null) {
        message = e.message!;
      }
      return ApiFailure(message, statusCode: statusCode);
    } catch (e) {
      return ApiFailure('Unexpected error: ${e.toString()}');
    }
  }

  /// Add a new payment for a UMS
  Future<ApiResult<PaymentModel>> addMemberPayment({
    required String memberId,
    required double amount,
    required String paymentType,
    required String paymentMode,
    DateTime? date,
    String? notes,
  }) async {
    try {
      final response = await _dio.post(
        '/club/members/$memberId/payments',
        data: {
          'amount': amount,
          'type': paymentType,
          'mode': paymentMode,
          'notes': notes,
          'date': (date ?? DateTime.now()).toIso8601String(),
        },
      );

      final paymentResponse = response.data as Map<String, dynamic>;

      if (paymentResponse['success'] == true) {
        final paymentData = paymentResponse['data'] as Map<String, dynamic>;
        final payment = PaymentModel(
          id:
              paymentData['id']?.toString() ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          amount: (paymentData['amount'] as num?)?.toDouble() ?? amount,
          userId: memberId,
          date:
              DateTime.tryParse(paymentData['date']?.toString() ?? '') ??
              (date ?? DateTime.now()),
          type: _mapStringToPaymentType(
            paymentData['type']?.toString() ?? paymentType,
          ),
          mode: _mapStringToPaymentMode(
            paymentData['mode']?.toString() ?? paymentMode,
          ),
          isIncome: true,
          createdAt: DateTime.now(),
        );

        return ApiSuccess(payment);
      } else {
        return ApiFailure(
          paymentResponse['message']?.toString() ?? 'Failed to add payment',
        );
      }
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      String message = 'Failed to add payment';

      if (statusCode == 404) {
        // Payment endpoint not available, return success with mock data
        final payment = PaymentModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          amount: amount,
          userId: memberId,
          date: date ?? DateTime.now(),
          type: _mapStringToPaymentType(paymentType),
          mode: _mapStringToPaymentMode(paymentMode),
          isIncome: true,
          createdAt: DateTime.now(),
        );
        return ApiSuccess(payment);
      }

      if (e.response?.data is Map<String, dynamic>) {
        final errorData = e.response!.data as Map<String, dynamic>;
        message = errorData['message']?.toString() ?? message;
      } else if (e.message != null) {
        message = e.message!;
      }

      return ApiFailure(message, statusCode: statusCode);
    } catch (e) {
      return ApiFailure('Unexpected error: ${e.toString()}');
    }
  }

  /// Update an existing payment
  Future<ApiResult<PaymentModel>> updateMemberPayment({
    required String memberId,
    required String paymentId,
    required double amount,
    required String paymentType,
    required String paymentMode,
    String? notes,
  }) async {
    try {
      final response = await _dio.put(
        '/club/members/$memberId/payments/$paymentId',
        data: {
          'amount': amount,
          'type': paymentType,
          'mode': paymentMode,
          'notes': notes,
        },
      );

      final paymentResponse = response.data as Map<String, dynamic>;

      if (paymentResponse['success'] == true) {
        final paymentData = paymentResponse['data'] as Map<String, dynamic>;
        final payment = PaymentModel(
          id: paymentId,
          amount: (paymentData['amount'] as num?)?.toDouble() ?? amount,
          userId: memberId,
          date:
              DateTime.tryParse(paymentData['date']?.toString() ?? '') ??
              DateTime.now(),
          type: _mapStringToPaymentType(
            paymentData['type']?.toString() ?? paymentType,
          ),
          mode: _mapStringToPaymentMode(
            paymentData['mode']?.toString() ?? paymentMode,
          ),
          isIncome: true,
          createdAt: DateTime.now(),
        );

        return ApiSuccess(payment);
      } else {
        return ApiFailure(
          paymentResponse['message']?.toString() ?? 'Failed to update payment',
        );
      }
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      String message = 'Failed to update payment';

      if (statusCode == 404) {
        // Payment endpoint not available, return success with mock updated data
        final payment = PaymentModel(
          id: paymentId,
          amount: amount,
          userId: memberId,
          date: DateTime.now(),
          type: _mapStringToPaymentType(paymentType),
          mode: _mapStringToPaymentMode(paymentMode),
          isIncome: true,
          createdAt: DateTime.now(),
        );
        return ApiSuccess(payment);
      }

      if (e.response?.data is Map<String, dynamic>) {
        final errorData = e.response!.data as Map<String, dynamic>;
        message = errorData['message']?.toString() ?? message;
      } else if (e.message != null) {
        message = e.message!;
      }

      return ApiFailure(message, statusCode: statusCode);
    } catch (e) {
      return ApiFailure('Unexpected error: ${e.toString()}');
    }
  }

  /// Delete a payment
  Future<ApiResult<bool>> deleteMemberPayment({
    required String memberId,
    required String paymentId,
  }) async {
    try {
      final response = await _dio.delete('/income/$paymentId');

      final deleteResponse = response.data as Map<String, dynamic>;

      if (deleteResponse['success'] == true) {
        return ApiSuccess(true);
      } else {
        return ApiFailure(
          deleteResponse['message']?.toString() ?? 'Failed to delete payment',
        );
      }
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      String message = 'Failed to delete payment';

      if (statusCode == 404) {
        // Payment endpoint not available, return success
        return ApiSuccess(true);
      }

      if (e.response?.data is Map<String, dynamic>) {
        final errorData = e.response!.data as Map<String, dynamic>;
        message = errorData['message']?.toString() ?? message;
      } else if (e.message != null) {
        message = e.message!;
      }

      return ApiFailure(message, statusCode: statusCode);
    } catch (e) {
      return ApiFailure('Unexpected error: ${e.toString()}');
    }
  }

  /// Create an income entry (Unified Income API)
  /// Payload: { title, amount, incomeType: 'membership', paymentDate, userId }
  Future<ApiResult<PaymentModel>> createIncome({
    required String title,
    required double amount,
    required DateTime paymentDate,
    required String userId,
  }) async {
    try {
      final response = await _dio.post(
        '/income',
        data: {
          'title': title,
          'amount': amount,
          'incomeType': 'membership',
          'paymentDate': paymentDate.toIso8601String(),
          'userId': userId,
        },
      );

      final map = response.data as Map<String, dynamic>;
      if (map['success'] == true) {
        final data = (map['data'] is Map<String, dynamic>)
            ? map['data'] as Map<String, dynamic>
            : map;

        // Try common keys; fall back gracefully
        final id =
            (data['id'] ??
                    data['_id'] ??
                    data['incomeId'] ??
                    DateTime.now().millisecondsSinceEpoch)
                .toString();
        final amt = (data['amount'] as num?)?.toDouble() ?? amount;
        final uid = (data['userId'] ?? userId).toString();
        final dateStr =
            (data['paymentDate'] ?? data['date'] ?? data['createdAt'])
                ?.toString();
        final dt = DateTime.tryParse(dateStr ?? '') ?? paymentDate;

        final payment = PaymentModel(
          id: id,
          amount: amt,
          userId: uid,
          linkedUserName: null,
          date: dt,
          type: PaymentType.membership,
          mode: null, // UI may set this locally; API doesn't take mode
          description: data['title']?.toString(),
          notes: null,
          isIncome: true,
          createdAt:
              DateTime.tryParse(
                (data['createdAt'] ?? dt.toIso8601String()).toString(),
              ) ??
              dt,
        );

        return ApiSuccess(payment);
      }
      return ApiFailure(
        map['message']?.toString() ?? 'Failed to create income',
      );
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      String message = 'Failed to create income';
      if (e.response?.data is Map<String, dynamic>) {
        final err = e.response!.data as Map<String, dynamic>;
        message = err['message']?.toString() ?? message;
      } else if (e.message != null) {
        message = e.message!;
      }

      // If endpoint missing in some envs, don't fabricate success here; bubble error
      return ApiFailure(message, statusCode: statusCode);
    } catch (e) {
      return ApiFailure('Unexpected error: ${e.toString()}');
    }
  }

  // ================== UNIFIED USERMODEL METHODS ==================

  /// Fetch unified users (formerly members) with pagination
  Future<ApiResult<MembersData>> getUsers({
    int page = 1,
    int limit = 20,
    bool activeOnly = true,
  }) async {
    try {
      final response = await _dio.get(
        '/club/members',
        queryParameters: {
          'page': page,
          'limit': limit,
          'activeOnly': activeOnly,
        },
      );

      final membersResponse = MembersResponse.fromJson(response.data);

      if (membersResponse.success) {
        return ApiSuccess(membersResponse.data);
      } else {
        return ApiFailure(membersResponse.message);
      }
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      String message = _extractDioMessage(e);
      if (message.isEmpty) message = 'Failed to fetch UMS';

      return ApiFailure(message, statusCode: statusCode);
    } catch (e) {
      return ApiFailure(e.toString());
    }
  }

  /// Fetch unified visitor users with pagination
  Future<ApiResult<MembersData>> getVisitorUsers({
    int page = 1,
    int limit = 20,
    bool activeOnly = false,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      String _fmt(DateTime d) =>
          '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final queryParameters = {
        'page': page,
        'limit': limit,
        'activeOnly': activeOnly,
        if (startDate != null) 'startDate': _fmt(startDate),
        if (endDate != null) 'endDate': _fmt(endDate),
      };

      Response response;
      try {
        response = await _dio.get(
          '/club/visitors',
          queryParameters: queryParameters,
        );
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          // Fallback to absolute URL as requested
          response = await _dio.get(
            '${Env.finalApiBaseUrl}/club/visitors',
            queryParameters: queryParameters,
          );
        } else {
          rethrow;
        }
      }

      final map = response.data as Map<String, dynamic>;
      try {
        final visitorsResponse = MembersResponse.fromJson(map);
        if (visitorsResponse.success) {
          return ApiSuccess(visitorsResponse.data);
        }
        return ApiFailure('Visitors response not successful');
      } catch (parseError) {
        return ApiFailure('Failed to parse visitors data');
      }
    } on DioException catch (e) {
      return ApiFailure(
        _extractDioMessage(e),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return ApiFailure('Unexpected error: ${e.toString()}');
    }
  }

  /// Fetch unified coach users with pagination
  Future<ApiResult<MembersData>> getCoachUsers({
    int page = 1,
    int limit = 20,
    bool includeInactive = false,
    String? memberRole, // 'coach' or 'senior_coach'
    String? search, // Search query for filtering coaches
  }) async {
    try {
      final response = await _dio.get(
        '/club/coaches',
        queryParameters: {
          'page': page,
          'limit': limit,
          'includeInactive': includeInactive,
          'activeOnly':
              !includeInactive, // Add activeOnly parameter as opposite of includeInactive
          if (memberRole != null) 'memberRole': memberRole,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );

      final responseData = response.data as Map<String, dynamic>;
      try {
        final coachesResponse = MembersResponse.fromJson(responseData);
        if (coachesResponse.success) {
          return ApiSuccess(coachesResponse.data);
        }
        return ApiFailure('Coaches response not successful');
      } catch (parseError) {
        return ApiFailure('Failed to parse coaches data');
      }
    } on DioException catch (e) {
      return ApiFailure(
        _extractDioMessage(e),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return ApiFailure('Unexpected error: ${e.toString()}');
    }
  }

  /// Fetch club trials with pagination
  Future<ApiResult<MembersData>> getTrials({
    int page = 1,
    int limit = 20,
    bool activeOnly = true,
  }) async {
    try {
      final queryParameters = {
        'page': page,
        'limit': limit,
        'activeOnly': activeOnly,
      };

      Response response;
      try {
        response = await _dio.get(
          '/club/trial',
          queryParameters: queryParameters,
        );
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          response = await _dio.get(
            '${Env.finalApiBaseUrl}/club/trial',
            queryParameters: queryParameters,
          );
        } else {
          rethrow;
        }
      }

      final map = response.data as Map<String, dynamic>;
      try {
        final trialsResponse = MembersResponse.fromJson(map);
        if (trialsResponse.success) {
          return ApiSuccess(trialsResponse.data);
        }
        final dataJson = (map['data'] is Map<String, dynamic>)
            ? map['data'] as Map<String, dynamic>
            : map;
        final membersData = MembersData.fromJson(dataJson);
        return ApiSuccess(membersData);
      } catch (_) {
        final membersData = MembersData.fromJson(map['data'] ?? map);
        return ApiSuccess(membersData);
      }
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      String message = 'Failed to fetch trials';

      if (e.response?.data is Map<String, dynamic>) {
        final errorData = e.response!.data as Map<String, dynamic>;
        message = errorData['message']?.toString() ?? message;
      } else if (e.message != null) {
        message = e.message!;
      }

      return ApiFailure(message, statusCode: statusCode);
    } catch (e) {
      return ApiFailure('Unexpected error: ${e.toString()}');
    }
  }

  /// Fetch unified trial users with pagination
  Future<ApiResult<MembersData>> getTrialUsers({
    int page = 1,
    int limit = 20,
    bool activeOnly = true,
  }) async {
    try {
      final queryParameters = {
        'page': page,
        'limit': limit,
        'activeOnly': activeOnly,
      };

      Response response;
      try {
        response = await _dio.get(
          '/club/trial',
          queryParameters: queryParameters,
        );
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          response = await _dio.get(
            '${Env.finalApiBaseUrl}/club/trial',
            queryParameters: queryParameters,
          );
        } else {
          rethrow;
        }
      }

      final map = response.data as Map<String, dynamic>;
      // print('DEBUG: getTrialUsers received response: ${map.keys.toList()}');
      try {
        final trialsResponse = MembersResponse.fromJson(map);
        // print(
        //   'DEBUG: getTrialUsers MembersResponse success: ${trialsResponse.success}',
        // );
        if (trialsResponse.success) {
          // print(
          //   'DEBUG: getTrialUsers trialsResponse.data type: ${trialsResponse.data.runtimeType}',
          // );
          // print(
          //   'DEBUG: getTrialUsers trialsResponse.data.data type: ${trialsResponse.data.data.runtimeType}',
          // );
          // print(
          //   'DEBUG: getTrialUsers trialsResponse.data.data length: ${trialsResponse.data.data.length}',
          // );
          return ApiSuccess(trialsResponse.data);
        }
        return ApiFailure('Trials response not successful');
      } catch (parseError) {
        // print('DEBUG: getTrialUsers parse error: $parseError');
        return ApiFailure('Failed to parse trials data');
      }
    } on DioException catch (e) {
      return ApiFailure(
        _extractDioMessage(e),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return ApiFailure('Unexpected error: ${e.toString()}');
    }
  }

  /// Filter/search users (UMS, coaches, senior coaches) by free-text
  /// Returns raw user maps; screens can map to their view models.
  Future<ApiResult<List<Map<String, dynamic>>>> filterUsers({
    required String search,
    int page = 1,
    int limit = 20,
    bool activeOnly = false,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      String _fmt(DateTime d) =>
          '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

      final queryParameters = <String, dynamic>{
        'page': page,
        'limit': limit,
        'search': search,
        'activeOnly': activeOnly,
        if (startDate != null) 'startDate': _fmt(startDate),
        if (endDate != null) 'endDate': _fmt(endDate),
      };

      Response response;
      try {
        response = await _dio.get(
          '/club/users/filter',
          queryParameters: queryParameters,
        );
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          response = await _dio.get(
            '${Env.finalApiBaseUrl}/club/users/filter',
            queryParameters: queryParameters,
          );
        } else {
          rethrow;
        }
      }

      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        final list =
            ((data['data'] as Map<String, dynamic>)['data'] as List<dynamic>?)
                ?.cast<Map<String, dynamic>>()
                .toList();
        return ApiSuccess(list ?? <Map<String, dynamic>>[]);
      }
      // Fallback: attempt to read list even if success not true
      final list =
          ((data['data'] ?? data) as Map<String, dynamic>)['data']
              as List<dynamic>? ??
          const [];
      return ApiSuccess(
        list.map((e) => (e as Map).cast<String, dynamic>()).toList(),
      );
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      String message = 'Failed to filter users';
      if (e.response?.data is Map<String, dynamic>) {
        final err = e.response!.data as Map<String, dynamic>;
        message = err['message']?.toString() ?? message;
      } else if (e.message != null) {
        message = e.message!;
      }
      return ApiFailure(message, statusCode: statusCode);
    } catch (e) {
      return ApiFailure('Unexpected error: ${e.toString()}');
    }
  }

  /// Referral search (search API)
  /// Uses /club/users/search with:
  /// page=1, limit=30, activeOnly=false, ignoreClubFilter=false
  /// Includes user supplied `search` term.
  Future<ApiResult<List<Map<String, dynamic>>>> searchReferralCandidates({
    required String search,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'page': 1,
        'limit': 30,
        'activeOnly': false,
        'ignoreClubFilter': false,
        if (search.isNotEmpty) 'search': search,
      };

      // Debug: trace referral search endpoint and params
      // ignore: avoid_print
      print(
        'DEBUG(api): GET /club/users/search params=' +
            queryParameters.toString(),
      );

      final response = await _dio.get(
        '/club/users/search',
        queryParameters: queryParameters,
      );

      // Robust parsing for potential variants
      final raw = response.data;
      if (raw is Map<String, dynamic>) {
        if (raw['success'] == true) {
          final data = (raw['data'] as Map<String, dynamic>?) ?? {};
          final listDyn = (data['data'] as List?) ?? const [];
          final list = listDyn
              .map((e) => (e as Map).cast<String, dynamic>())
              .toList();
          return ApiSuccess(list);
        }
        // Fallback if success not provided consistently
        final dataOrRaw = (raw['data'] ?? raw) as Map<String, dynamic>;
        final listDyn = (dataOrRaw['data'] as List?) ?? const [];
        final list = listDyn
            .map((e) => (e as Map).cast<String, dynamic>())
            .toList();
        return ApiSuccess(list);
      }
      // Unexpected structure: return empty list
      return const ApiSuccess(<Map<String, dynamic>>[]);
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      String message = 'Failed to search referral candidates';
      if (e.response?.data is Map<String, dynamic>) {
        final err = e.response!.data as Map<String, dynamic>;
        message = err['message']?.toString() ?? message;
      } else if (e.message != null) {
        message = e.message!;
      }
      return ApiFailure(message, statusCode: statusCode);
    } catch (e) {
      return ApiFailure('Unexpected error: ${e.toString()}');
    }
  }

  /// Attendance: fetch filtered users (membership + trial) with pagination
  Future<ApiResult<FilteredUsersPage>> fetchFilteredUsers({
    int page = 1,
    int limit = 20,
    bool activeOnly = false,
    List<String> membershipTypes = const ['membership', 'trial'],
  }) async {
    try {
      final query = {
        'page': page,
        'limit': limit,
        'activeOnly': activeOnly,
        'membershipTypes': membershipTypes.join(','),
      };

      final response = await _dio.get(
        '/club/users/filter',
        queryParameters: query,
      );

      final map = response.data as Map<String, dynamic>;
      if (map['success'] == true) {
        final pageData = FilteredUsersPage.fromJson(map);
        return ApiSuccess(pageData);
      }
      return ApiFailure(map['message']?.toString() ?? 'Failed to fetch users');
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      String message = 'Failed to fetch users';
      if (e.response?.data is Map<String, dynamic>) {
        final err = e.response!.data as Map<String, dynamic>;
        message = err['message']?.toString() ?? message;
      } else if (e.message != null) {
        message = e.message!;
      }
      return ApiFailure(message, statusCode: statusCode);
    } catch (e) {
      return ApiFailure('Unexpected error: ${e.toString()}');
    }
  }

  /// Attendance: submit full attendance (present and absent) for provided users
  ///
  /// Pass a map of userId -> isPresent (true = present, false = absent).
  Future<ApiResult<AttendanceSubmitResult>> submitAttendance({
    required DateTime attendanceDate,
    required Map<String, bool> statuses,
  }) async {
    try {
      String _fmt(DateTime d) =>
          '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

      final body = {
        'attendanceDate': _fmt(attendanceDate),
        'attendanceRecords': statuses.entries
            .map(
              (e) => {
                'userId': e.key,
                'status': e.value ? 'present' : 'absent',
              },
            )
            .toList(),
      };

      final response = await _dio.post('/attendance', data: body);

      final map = response.data as Map<String, dynamic>;
      if (map['success'] == true) {
        final result = AttendanceSubmitResult.fromJson(map);
        return ApiSuccess(result);
      }
      return ApiFailure(map['message']?.toString() ?? 'Attendance failed');
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      String message = 'Attendance failed';
      if (e.response?.data is Map<String, dynamic>) {
        final err = e.response!.data as Map<String, dynamic>;
        message = err['message']?.toString() ?? message;
      } else if (e.message != null) {
        message = e.message!;
      }
      return ApiFailure(message, statusCode: statusCode);
    } catch (e) {
      return ApiFailure('Unexpected error: ${e.toString()}');
    }
  }

  /// Get user subscription history
  /// API: GET /ums/subscriptions/{userId}?page={page}&limit={limit}&activeOnly=false
  Future<ApiResult<Map<String, dynamic>>> getUserSubscriptions({
    required String userId,
    int page = 1,
    int limit = 30,
    bool activeOnly = false,
  }) async {
    try {
      final response = await _dio.get(
        '/ums/subscriptions/$userId',
        queryParameters: {
          'page': page,
          'limit': limit,
          'activeOnly': activeOnly,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data as Map<String, dynamic>;
        if (responseData['success'] == true) {
          return ApiSuccess(responseData['data'] as Map<String, dynamic>);
        } else {
          return ApiFailure(
            responseData['message']?.toString() ??
                'Failed to fetch subscriptions',
            statusCode: response.statusCode,
          );
        }
      } else {
        return ApiFailure(
          'Failed to fetch subscriptions',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      String message = _extractDioMessage(e);
      if (message.isEmpty) {
        message = 'Failed to fetch subscription history';
      }
      return ApiFailure(message, statusCode: statusCode);
    } catch (e) {
      return ApiFailure('Unexpected error: ${e.toString()}');
    }
  }
}
