import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_result.dart';

class ApiTestService {
  final Dio _dio = ApiClient.instance.dio;

  /// Test API connectivity
  Future<ApiResult<Map<String, dynamic>>> testConnection() async {
    try {
      final response = await _dio.get('/health');
      return ApiSuccess(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      String message = 'Connection test failed';

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
}
