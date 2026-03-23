import 'package:flutter/material.dart';
import '../network/api_client.dart';
import '../error/error_handler.dart';

/// Centralized API service wrapper for consistent error handling
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static ApiService get instance => _instance;

  /// Make a GET request with centralized error handling
  static Future<T?> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    BuildContext? context,
    String? successMessage,
    bool showSuccessMessage = false,
  }) async {
    try {
      final response = await ApiClient.instance.dio.get(
        endpoint,
        queryParameters: queryParameters,
      );

      if (showSuccessMessage && successMessage != null && context != null) {
        ErrorHandler.showSuccess(context, successMessage);
      }

      return response.data;
    } catch (e) {
      if (context != null) {
        // For GET requests, avoid showing generic dialogs; inline UI should surface errors
        await ErrorHandler.handleError(context, e, showDialog: false);
      }
      return null;
    }
  }

  /// Make a POST request with centralized error handling
  static Future<T?> post<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    BuildContext? context,
    String? successMessage,
    bool showSuccessMessage = true,
  }) async {
    try {
      final response = await ApiClient.instance.dio.post(
        endpoint,
        data: data,
        queryParameters: queryParameters,
      );

      // Handle success message from API response or custom message
      if (context != null && showSuccessMessage) {
        String message = successMessage ?? 'Operation completed successfully';

        // Try to extract message from API response
        if (response.data is Map && response.data['message'] != null) {
          message = response.data['message'];
        }

        ErrorHandler.showSuccess(context, message);
      }

      return response.data;
    } catch (e) {
      if (context != null) {
        await ErrorHandler.handleError(context, e);
      }
      return null;
    }
  }

  /// Make a PUT request with centralized error handling
  static Future<T?> put<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    BuildContext? context,
    String? successMessage,
    bool showSuccessMessage = true,
  }) async {
    try {
      final response = await ApiClient.instance.dio.put(
        endpoint,
        data: data,
        queryParameters: queryParameters,
      );

      if (context != null && showSuccessMessage) {
        String message = successMessage ?? 'Updated successfully';

        if (response.data is Map && response.data['message'] != null) {
          message = response.data['message'];
        }

        ErrorHandler.showSuccess(context, message);
      }

      return response.data;
    } catch (e) {
      if (context != null) {
        await ErrorHandler.handleError(context, e);
      }
      return null;
    }
  }

  /// Make a DELETE request with centralized error handling
  static Future<T?> delete<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    BuildContext? context,
    String? successMessage,
    bool showSuccessMessage = true,
  }) async {
    try {
      final response = await ApiClient.instance.dio.delete(
        endpoint,
        data: data,
        queryParameters: queryParameters,
      );

      if (context != null && showSuccessMessage) {
        String message = successMessage ?? 'Deleted successfully';

        if (response.data is Map && response.data['message'] != null) {
          message = response.data['message'];
        }

        ErrorHandler.showSuccess(context, message);
      }

      return response.data;
    } catch (e) {
      if (context != null) {
        await ErrorHandler.handleError(context, e);
      }
      return null;
    }
  }

  /// Execute any API call with loading state management
  static Future<T?> executeWithLoading<T>(
    Future<T?> Function() apiCall, {
    required BuildContext context,
    required void Function(bool) setLoading,
  }) async {
    try {
      setLoading(true);
      return await apiCall();
    } finally {
      if (context.mounted) {
        setLoading(false);
      }
    }
  }
}
