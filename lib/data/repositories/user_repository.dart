import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_result.dart';
import '../../models/user_model.dart';

class UserRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<ApiResult<List<UserModel>>> fetchUsers() async {
    try {
      await _dio.get('/users');
      // Map JSON to UserModel if/when you add fromJson. For now, stub empty list.
      // TODO: Implement proper fromJson mapping
      return ApiSuccess<List<UserModel>>([]);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final message = e.response?.data is Map<String, dynamic>
          ? (e.response?.data['message']?.toString() ?? 'Request failed')
          : e.message ?? 'Request failed';
      return ApiFailure<List<UserModel>>(message, statusCode: status);
    } catch (e) {
      return ApiFailure<List<UserModel>>(e.toString());
    }
  }
}
