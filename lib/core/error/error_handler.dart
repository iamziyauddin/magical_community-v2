import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../services/navigation_service.dart';
import '../storage/token_storage.dart';
import '../theme/app_theme.dart';
import '../../screens/auth/login_screen.dart';

class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();

  static ErrorHandler get instance => _instance;

  // Track if we're already showing a session expired dialog
  static bool _isShowingSessionDialog = false;

  // Track the last error message to prevent duplicates
  static String? _lastErrorMessage;
  static DateTime? _lastErrorTime;

  // Track consecutive timeouts to detect stuck sessions
  static int _timeoutCount = 0;
  static DateTime? _lastTimeoutTime;
  static const Duration _timeoutWindow = Duration(seconds: 60);
  static const int _timeoutThreshold = 2; // After 2 timeouts, force logout

  /// Main method to handle all API errors consistently
  static Future<void> handleError(
    BuildContext context,
    dynamic error, {
    String? customMessage,
    bool showDialog = true,
  }) async {
    String errorMessage = customMessage ?? _getErrorMessage(error);

    // Prevent duplicate error messages within 2 seconds
    final now = DateTime.now();
    if (_lastErrorMessage == errorMessage &&
        _lastErrorTime != null &&
        now.difference(_lastErrorTime!).inSeconds < 2) {
      return;
    }

    _lastErrorMessage = errorMessage;
    _lastErrorTime = now;

    // Handle session expiry globally - Check for 401 errors
    if (_isSessionExpired(error)) {
      await _handleSessionExpiry(context);
      return;
    }

    // Handle network timeouts: if they occur twice in a short window, treat as expired session
    if (_isTimeout(error)) {
      final last = _lastTimeoutTime;
      if (last == null || now.difference(last) > _timeoutWindow) {
        _timeoutCount = 1;
      } else {
        _timeoutCount += 1;
      }
      _lastTimeoutTime = now;

      if (_timeoutCount >= _timeoutThreshold) {
        // Reset counters and force logout + redirect to login with session expired message
        _timeoutCount = 0;
        _lastTimeoutTime = null;
        await _handleSessionExpiry(
          context,
          message: 'Your session has expired. Please login again to continue.',
        );
        return;
      }

      // For single timeout, avoid noisy dialogs; surface inline UI where appropriate
      return;
    }

    // Reset timeout counters on non-timeout errors
    _timeoutCount = 0;
    _lastTimeoutTime = null;

    // Show error dialog if requested
    if (showDialog && context.mounted) {
      await _showErrorDialog(context, errorMessage);
    }
  }

  /// Alternative method to handle 401 errors without dialog (more reliable)
  static Future<void> handleUnauthorizedError() async {
    // This method is now deprecated - handled directly in AuthInterceptor
    final context = NavigationService.instance.currentContext;
    if (context != null) {
      await _handleSessionExpiry(context);
    } else {
      await TokenStorage.clearToken();
      NavigationService.instance.pushWidgetAndClearStack(const LoginScreen());
    }
  }

  /// Check if error is due to session expiry
  static bool _isSessionExpired(dynamic error) {
    if (error is DioException) {
      return error.response?.statusCode == 401;
    }
    return false;
  }

  /// Handle session expiry - clear token and redirect to login
  static Future<void> _handleSessionExpiry(
    BuildContext context, {
    String message =
        'Your session has expired. Please login again to continue.',
  }) async {
    // Prevent multiple session dialogs
    if (_isShowingSessionDialog) return;
    _isShowingSessionDialog = true;

    try {
      await TokenStorage.clearToken();

      if (context.mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning, color: AppTheme.errorRed),
                SizedBox(width: 8),
                Text('Session Expired'),
              ],
            ),
            content: Text(message),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlack,
                  foregroundColor: AppTheme.white,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  NavigationService.instance.pushWidgetAndClearStack(
                    const LoginScreen(),
                  );
                },
                child: const Text('Login Again'),
              ),
            ],
          ),
        );
      } else {
        NavigationService.instance.pushWidgetAndClearStack(const LoginScreen());
      }
    } catch (e) {
      NavigationService.instance.pushWidgetAndClearStack(const LoginScreen());
    } finally {
      // Reset timeout tracking on forced logout
      _timeoutCount = 0;
      _lastTimeoutTime = null;
      _isShowingSessionDialog = false;
    }
  }

  /// Show error dialog with consistent styling and better visibility
  static Future<void> _showErrorDialog(
    BuildContext context,
    String message,
  ) async {
    // Clear any existing snackbars first
    ScaffoldMessenger.of(context).clearSnackBars();

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: AppTheme.errorRed, size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Error',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Dismiss',
              style: TextStyle(color: AppTheme.primaryBlack),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Show success snackbar with consistent styling (less intrusive for positive feedback)
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Show warning dialog for important non-error messages
  static Future<void> showWarning(
    BuildContext context,
    String message, {
    String? title,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_outlined, color: Colors.orange, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title ?? 'Warning',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 16)),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Show info dialog for general information
  static Future<void> showInfo(
    BuildContext context,
    String message, {
    String? title,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: AppTheme.primaryBlack, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title ?? 'Information',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 16)),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlack,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Show confirmation dialog for destructive actions
  static Future<bool> showConfirmation(
    BuildContext context,
    String message, {
    String? title,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    Color? confirmColor,
    bool isDangerous = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isDangerous ? Icons.warning : Icons.help_outline,
              color: isDangerous ? AppTheme.errorRed : AppTheme.primaryBlack,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title ?? (isDangerous ? 'Confirm Action' : 'Confirmation'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              cancelText,
              style: TextStyle(color: AppTheme.primaryBlack),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  confirmColor ??
                  (isDangerous ? AppTheme.errorRed : AppTheme.primaryBlack),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmText),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    return result ?? false;
  }

  /// Extract user-friendly error message from various error types
  static String _getErrorMessage(dynamic error) {
    if (error is DioException) {
      // Try early extraction of a backend provided message before status-specific fallbacks
      final data = error.response?.data;
      String? backendMessage;
      if (data is Map) {
        if (data['message'] is String &&
            (data['message'] as String).trim().isNotEmpty) {
          backendMessage = data['message'];
        } else if (data['error'] is String &&
            (data['error'] as String).trim().isNotEmpty) {
          backendMessage = data['error'];
        } else if (data['errors'] is List) {
          // Combine array of errors into a single readable string
          final list = (data['errors'] as List)
              .whereType<String>()
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
          if (list.isNotEmpty) backendMessage = list.join('\n');
        } else if (data['errors'] is Map) {
          // Validation error map: {field: [msg1, msg2]}
          final map = data['errors'] as Map;
          final parts = <String>[];
          map.forEach((k, v) {
            if (v is List) {
              for (final item in v) {
                if (item is String && item.trim().isNotEmpty) {
                  parts.add('$k: ${item.trim()}');
                }
              }
            } else if (v is String && v.trim().isNotEmpty) {
              parts.add('$k: ${v.trim()}');
            }
          });
          if (parts.isNotEmpty) backendMessage = parts.join('\n');
        }
      }
      switch (error.response?.statusCode) {
        case 400:
          return backendMessage ?? 'Invalid request. Please check your input.';
        case 401:
          return backendMessage ?? 'Session expired. Please login again.';
        case 403:
          return backendMessage ??
              'You don\'t have permission to perform this action.';
        case 404:
          return backendMessage ?? 'The requested resource was not found.';
        case 422:
          return backendMessage ?? 'Please check your input and try again.';
        case 500:
          return backendMessage ?? 'Server error. Please try again later.';
        case 502:
        case 503:
        case 504:
          return backendMessage ??
              'Service temporarily unavailable. Please try again.';
        default:
          if (backendMessage != null) return backendMessage;
          if (error.type == DioExceptionType.connectionTimeout) {
            return 'Connection timeout. Please check your internet.';
          }
          if (error.type == DioExceptionType.sendTimeout) {
            return 'Request timeout. Please try again.';
          }
          if (error.type == DioExceptionType.receiveTimeout) {
            return 'Server response timeout. Please try again.';
          }
          if (error.type == DioExceptionType.connectionError) {
            return 'Network error. Please check your connection.';
          }
          return 'Something went wrong. Please try again.';
      }
    }

    if (error is Exception) {
      return error.toString().replaceFirst('Exception: ', '');
    }

    return 'An unexpected error occurred.';
  }

  /// Clear any cached error state (useful for testing or reset)
  static void clearErrorState() {
    _lastErrorMessage = null;
    _lastErrorTime = null;
    _isShowingSessionDialog = false;
    _timeoutCount = 0;
    _lastTimeoutTime = null;
  }

  /// Test method to simulate 401 error (for debugging)
  static Future<void> testUnauthorizedError() async {
    debugPrint('Testing unauthorized error handling...');
    await handleUnauthorizedError();
  }

  // Determine if the error is a timeout
  static bool _isTimeout(dynamic error) {
    if (error is DioException) {
      return error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout;
    }
    if (error is SocketException) {
      // SocketException may represent connection issues which often surface as timeouts
      return true;
    }
    final message = error.toString().toLowerCase();
    return message.contains('timeout') || message.contains('timed out');
  }
}
