import 'dart:async';
import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_result.dart';
import '../../core/storage/token_storage.dart';
import '../../core/storage/user_storage.dart';
import '../../core/session/session_manager.dart';
import '../models/login_response.dart';

class AuthService {
  final Dio _dio = ApiClient.instance.dio;

  /// Login with email and password
  /// Returns ApiResult containing LoginData with user info, token, and club info
  Future<ApiResult<LoginData>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      final loginResponse = LoginResponse.fromJson(response.data);

      if (loginResponse.success) {
        // Store token for future requests
        await TokenStorage.setToken(loginResponse.data.accessToken);

        // Store user and club data
        await UserStorage.saveUser(loginResponse.data.user);
        await UserStorage.saveClub(loginResponse.data.club);

        // Update session manager
        SessionManager.instance.updateSession(loginResponse.data);

        return ApiSuccess(loginResponse.data);
      } else {
        return ApiFailure(loginResponse.message);
      }
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      String message = 'Login failed';

      if (statusCode == 401) {
        message = 'Invalid email or password';
      } else if (e.response?.data is Map<String, dynamic>) {
        final errorData = e.response!.data as Map<String, dynamic>;
        message =
            errorData['message']?.toString() ??
            errorData['error']?.toString() ??
            message;
      } else if (e.message != null) {
        message = e.message!;
      }

      return ApiFailure(message, statusCode: statusCode);
    } catch (e) {
      return ApiFailure('Unexpected error: ${e.toString()}');
    }
  }

  /// Logout - clear stored token and user data
  Future<ApiResult<void>> logout() async {
    try {
      // Call logout API if token exists
      final token = await TokenStorage.getToken();
      if (token != null && token.isNotEmpty) {
        // Enforce a short timeout; if it takes too long, proceed with local logout
        await _dio.post('/auth/logout').timeout(const Duration(seconds: 5));
      }

      // Clear all stored data regardless of API call result
      await TokenStorage.clearToken();
      await UserStorage.clearUserData();
      SessionManager.instance.clearSession();

      return const ApiSuccess(null);
    } on DioException catch (e) {
      // Even if API call fails, clear local data
      await TokenStorage.clearToken();
      await UserStorage.clearUserData();
      SessionManager.instance.clearSession();

      String message = 'Logout completed locally';

      if (e.response?.data is Map<String, dynamic>) {
        final errorData = e.response!.data as Map<String, dynamic>;
        message = errorData['message']?.toString() ?? message;
      }

      // Return success even if API fails, since local cleanup is done
      return const ApiSuccess(null);
    } on TimeoutException {
      // API took too long; force local logout
      await TokenStorage.clearToken();
      await UserStorage.clearUserData();
      SessionManager.instance.clearSession();
      return const ApiSuccess(null);
    } catch (e) {
      // Ensure cleanup even on unexpected errors
      await TokenStorage.clearToken();
      await UserStorage.clearUserData();
      SessionManager.instance.clearSession();

      return const ApiSuccess(null);
    }
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await TokenStorage.getToken();
    return token != null && token.isNotEmpty;
  }

  /// Forgot password - send password reset email
  Future<ApiResult<String>> forgotPassword({required String email}) async {
    try {
      final response = await _dio.post(
        '/auth/forgot-password',
        data: {'email': email},
      );

      if (response.data is Map<String, dynamic>) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true) {
          final message =
              responseData['message']?.toString() ??
              'Password reset instructions have been sent to your email.';
          return ApiSuccess(message);
        } else {
          final message =
              responseData['message']?.toString() ??
              'Failed to send password reset email.';
          return ApiFailure(message);
        }
      }

      return const ApiSuccess(
        'Password reset instructions have been sent to your email.',
      );
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      String message = 'Failed to send password reset email';

      if (statusCode == 404) {
        message = 'No account found with this email address';
      } else if (statusCode == 429) {
        message = 'Too many requests. Please try again later';
      } else if (e.response?.data is Map<String, dynamic>) {
        final errorData = e.response!.data as Map<String, dynamic>;
        message =
            errorData['message']?.toString() ??
            errorData['error']?.toString() ??
            message;
      } else if (e.message != null) {
        message = e.message!;
      }

      return ApiFailure(message, statusCode: statusCode);
    } catch (e) {
      return ApiFailure('Unexpected error: ${e.toString()}');
    }
  }

  /// Get current logged in user
  Future<User?> getCurrentUser() async {
    return await UserStorage.getUser();
  }

  /// Get current club
  Future<Club?> getCurrentClub() async {
    return await UserStorage.getClub();
  }
}
